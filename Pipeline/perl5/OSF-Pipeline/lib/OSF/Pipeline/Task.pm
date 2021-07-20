
package OSF::Pipeline::Task;

use warnings;
use strict;

use Log::Report 'osf-pipeline';

use JSON            ();
use List::MoreUtils qw(uniq);

my $json = JSON->new->utf8;

=chapter NAME

OSF::Pipeline::Task - client task

=chapter SYNOPSIS

=chapter DESCRIPTION
Extensions of this module are Tasks which run on the Pipeline.

=chapter METHODS
=section Constructors

=c_method new %options
=requires name STRING
=cut

sub new(%)
{   my $class = shift;
    $class ne __PACKAGE__ or panic "You need to extend $class";
    (bless {}, $class)->_init({@_});
}

sub _init($)
{   my ($self, $args) = @_;
    $self->{OPT_name} = $args->{name} || ref $self;
    $self;
}

#---------------
=section Accessors

=method name
=cut

sub name() { $_[0]->{OPT_name} }

#---------------
=section Actions

=method take $product, %options
=cut

sub take($%)
{   my ($self, $product, %args) = @_;

    # write
    $self->save($product, my $hits);
    1;
}

#---------------
=section Filter construction

=method filterRequiresText %options
Returns a CODE which returns a descriptive HASH when the product has
a text extract and fulfils the (optional) size restriction.

=option  minimum_size INTEGER
=default minimum_size <undef>

=option  minimum_chars INTEGER
=default minimum_chars <undef>
Counts only C<\w> characters.

=option  minimum_words INTEGER
=default minimum_words <undef>
=cut

sub filterRequiresText(%)
{   my ($self, %args) = @_;
    my $minsize  = $args{minimum_size } || 0;
    my $minchars = $args{minimum_chars} || 0;
    my $minwords = $args{minimum_words} || 0;

    sub {
        my $product = shift;
        my $size  = $product->contentSize or return ();
        my %facts = (rule => 'requires text', size => $size);
        return () if $minsize > $size || $minchars > $size || $minwords > $size;

        if($minchars)
        {   my $chars = $facts{chars} = $product->contentWordChars;
            return () if $minchars > $chars;
        }

        if($minwords)
        {   my $words = $facts{words} = $product->contentWords;
            return () if $minwords > $words;
        }

        \%facts;
    };
}

=method filterContentType \@types
=cut

sub filterContentType($)
{   my ($self, $types) = @_;
    @$types or return sub { () };

    my %types = map +(lc $_ => 1), @$types;

    sub {
        my $ct = $_[0]->contentType;
        $types{lc $ct} or return ();
        +{ rule => 'content type', type => $ct };
    };
}

=method filterDomain \@domains
=cut

sub filterDomain($)
{   my ($self, $domains) = @_;
    @$domains or return sub { () };

    # Matching them reverse sorted makes regex internal optimizations
    # possible.
    my $any   = join '|', sort map lc scalar reverse, @$domains;
    $any      =~ s/\./\\./g;
    my $match = qr/^($any)(?:\.|$)/;

    sub {
        my $hostname = reverse lc($_[0]->uri->host);
        $hostname =~ $match or return ();
        +{ rule => 'domain name', name => reverse $1 };
    };
}

=method filterFullWords \@words, %options;
=option  case_sensitive BOOLEAN
=default case_sensitive <false>
=cut

sub filterFullWords($%)
{   my ($self, $words, %args) = @_;
    @$words or return sub { 0 };

    my $any   = join '|', map quotemeta, @$words;

    if($args{case_sensitive})
    {   my $match = qr!\b(?:$any)\b!;
        return sub {
            my $ref_text = $_[0]->refText;
            my @words = $$ref_text =~ /$match/m;
            @words or return ();

            map +{ rule => 'full word', word => $_ },
                uniq @words;
        };
    }
    else
    {   my $match = qr!\b(?:$any)\b!i;
        my %words = map +(lc($_) => $_), @$words;  # right capitization

        return sub {
            my $ref_text = $_[0]->refText;
            my @words = $$ref_text =~ /$match/im;
            @words or return ();

            map +{ rule => 'full word', word => $words{$_} },
                uniq(map lc, @words);
        };
    }
}

=method filterMatchText \%regexps, %options;
The keys are the names for the regexes, used for logging.  The $1 of
the regex is collected in the log.

=option  case_sensitive BOOLEAN
=default case_sensitive <false>
=cut

sub filterMatchText($%)
{   my ($self, $regexes, %args) = @_;
    keys %$regexes or return sub { () };

    sub {
        my $text = $_[0]->refText or return ();
        my @hits;
        foreach my $label (keys %$regexes)
        {   my @matches = $$text =~ /$regexes->{$label}/g;
            push @hits, +{
                rule    => 'match text',
                pattern => $label,
                matches => [ uniq @matches ],
            } if @matches;
        }
        @hits;
    };
}

1;


package OSF::Pipeline::Task;

use warnings;
use strict;

use Log::Report 'pipeline';

use JSON            ();
use List::MoreUtils qw(uniq);

my $json = JSON->new->utf8;

=chapter NAME

OSF::Pipeline::Task - client task

=chapter SYNOPSIS

=chapter DESCRIPTION
Extensions of this module are Tasks which run on the Pipeline.

=chapter METHODS

=c_method new %options
=cut

sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init($)
{   my ($self, $args) = @_;

    $self;
}

=method take $product, %options
=cut

sub take($%)
{   my ($self, $product, %args) = @_;

    # write
    $self->_save($product, my $hits);
    1;
}

#---------------
=section Filter construction

=method filterRequiresText %options
=option  minimum_size INTEGER
=default minimum_size 0
=cut

sub filterRequiresText(%)
{   my ($self, %args) = @_;
    my $minsize = $args{minimum_size} || 0;

    $minsize
        or return sub { $_[0]->refText ? +{ rule => 'requires text' } : () };

    sub {
        my $t = $_[0]->refText;
        $t && length $$t >= $minsize or return ();
         +{ rule          => 'requires text',
             minimum_size => $minsize,
             size         => length $$t,
          };
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

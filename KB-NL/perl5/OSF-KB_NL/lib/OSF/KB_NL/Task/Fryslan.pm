package OSF::KB_NL::Task::Fryslan;
use parent 'OSF::Pipeline::Task';

use warnings;
use strict;
use utf8;

use charnames ':full', ':alias' => {
   a_CIRCUM   => 'LATIN SMALL LETTER A WITH CIRCUMFLEX',
   CIRCUMFLEX => 'COMBINING CIRCUMFLEX ACCENT',
};

use OSF::Package::7zip ();
use HTTP::Status       qw(is_success);

my $collect       = $ENV{KB_COLLECT}
    or die "Environment variable KB_COLLECT missing";

my @content_types = qw(text/html text/xhtml application/pdf);
my @domain_names  = qw(frl team);

# The â probably has alternatives in Unicode
my @words_in_text =
 ( "Fryslan"
 , "Frysl\N{a_CIRCUM}n"
 , "Frysla\N{CIRCUMFLEX}n"
 , "Friesland"
 , 'Teszelszky'
 );

my @regexes_in_text;

sub _init($)
{   my ($self, $args) = @_;
    $args->{name} ||= 'KB_NL Fryslân';

    $self->SUPER::_init($args);
    $self->{OKT_save} = OSF::Package::7zip->new(directory => $collect);
    $self;
}

sub createFilter()
{   my $self  = shift;
    my $text  = $self->filterRequiresText(minimum_size => 200);
    my $ct    = $self->filterContentType(\@content_types);
    my $rid   = $self->filterDomain(\@domain_names);
    my $words = $self->filterFullWords(\@words_in_text);

    sub {
        my $product = shift;
           is_success($product->responseStatus)
        && $ct->($product)
        && $text->($product)
            or return undef;

        my @hits = ($words->($product), $rid->($product));
        @hits ? \@hits : undef;
    };
}

sub save($$)
{   my ($self, $product, $hits) = @_;
warn "SAVE ", $product->name;

    my $save = $self->{OKT_save};
    foreach my $component ( qw/request response text/ )
    {   my $part = $product->part($component) or next;
        $save->addFile($product, "$component.warc-record.gz", $part->refBytes);
    }

    $save->addJson($product, 'facts.json', +{
        hits   => $hits,
        origin => $product->origin,
    });
}

1;

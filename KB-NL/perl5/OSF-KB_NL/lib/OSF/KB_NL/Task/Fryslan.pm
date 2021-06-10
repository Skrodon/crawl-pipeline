package OSF::KB_NL::Fryslan;
use parent 'OSF::Pipeline::Task';

use warnings;
use strict;
use utf8;

use charnames ':full', ':alias' => {
   a_CIRCUM   => 'LATIN SMALL LETTER A WITH CIRCUMFLEX',
   CIRCUMFLEX => 'COMBINING CIRCUMFLEX ACCENT',
};

use OSF::Package::7zip ();

my $collect       = $ENV{KB_COLLECT} or die "Environment variable KB_COLLECT missing";

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

sub init($)
{   my ($self, $args) = @_;

    # Exclude
#   $args->{accept_content_types} ||= \@content_types;
#   $args->{minimum_text_size} //= 200;

    # Search
    push @{$args->{text_contains_words}}, @words_in_text;
    push @{$args->{text_contains_regexes}}, @regexes_in_text;
    push @{$args->{domain_names}}, @domain_names;

    # Save
    $self->{OKT_save} = OSF::Package::7zip->new(directory => $collect);

    $self->SUPER::init($args);
}

sub exclude($)
{   my ($self, $product) = @_;
    return 1 if $self->SUPER::exclude($product);

    0;
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

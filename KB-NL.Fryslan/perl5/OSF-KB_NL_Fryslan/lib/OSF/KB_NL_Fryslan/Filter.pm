package OSF::KB_NL_Fryslan::Filter;
use parent 'OSF::Pipeline::Filter';

use warnings;
use strict;
use utf8;

use charnames ':full', ':alias' => {
   a_CIRCUM   => 'LATIN SMALL LETTER A WITH CIRCUMFLEX',
   CIRCUMFLEX => 'COMBINING CIRCUMFLEX ACCENT',
};

my @content_types = qw(text/html);
my @domain_names  = qw(frl);

# The â probably has alternatives in Unicode
my @words_in_text =
 ( "Fryslan"
 , "Frysl\N{a_CIRCUM}n"
 , "Frysla\N{CIRCUMFLEX}n"
 , "Friesland"
 );

my @regexes_in_text =
 ( Mark => qr/\bmark\b/si,
 );


sub init($)
{   my ($self, $args) = @_;

    # Exclude
    $args->{accept_content_types} ||= \@content_types;

    # Search
    push @{$args->{text_contains_words}}, @words_in_text;
    push @{$args->{text_contains_regexes}}, @regexes_in_text;
    push @{$args->{domain_names}}, @domain_names;

    $self->SUPER::init($args);
}

sub exclude($)
{   my ($self, $product) = @_;
    return 1 if $self->SUPER::exclude($product);

    0;
}

sub save($$)
{   my ($self, $product, $hits) = @_;
use Data::Dumper;
warn Dumper $hits;
warn "SAVING: ", $product->uri;
}

1;

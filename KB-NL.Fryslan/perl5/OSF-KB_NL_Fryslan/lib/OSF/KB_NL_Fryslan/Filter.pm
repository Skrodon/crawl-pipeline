package OSF::KB_NL_Fryslan::Filter;
use parent 'OSF::Pipeline::Filter';

use warnings;
use strict;
use utf8;

use charnames ':full', ':alias' => {
   a_CIRCUM   => 'LATIN SMALL LETTER A WITH CIRCUMFLEX',
   CIRCUMFLEX => 'COMBINING CIRCUMFLEX ACCENT',
};

# The â probably has alternatives in Unicode
my @words_in_text =
 ( "Fryslan"
 , "Frysl\N{a_CIRCUM}n"
 , "Frysla\N{CIRCUMFLEX}n"
 , "Friesland"
 );

my @domain_names = qw(frl);

sub init($)
{   my ($self, $args) = @_;

    push @{$args->{text_contains_words}}, @words_in_text;
    push @{$args->{domain_names}}, @domain_names;

    $self->SUPER::init($args);
}

sub save($)
{   my ($self, $product) = @_;
warn "SAVING: ", $product->url;
}

1;

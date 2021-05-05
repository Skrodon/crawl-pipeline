package OSF::CommonCrawl::Product;

use warnings;
use strict;

use JSON   qw(decode_json);

sub new(%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;
    $self->{OCP_parts} = $args->{parts} || {};
    $self;
}

sub part($) { $_[0]->{OCP_parts}{$_[1]} }

sub uri() { $_[0]->{OCP_uri} ||= $_[0]->part('request')->uri }

sub cld2()
{   my $self = shift;
    return $self->{OCP_cld2} if defined $self->{OCP_cld2};

    my $meta = $self->part('metadata') or return;
    my $cld2 = $meta->value('languages-cld2') or return;
    $self->{OCP_cld2} = decode_json $cld2;
}

1;

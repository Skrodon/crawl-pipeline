package OSF::CommonCrawl::Product;

use warnings;
use strict;

use JSON   qw(decode_json);
use URI    ();

sub new(%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;
    $self->{OCP_parts} = $args->{parts} || {};
    $self;
}

sub part($) { $_[0]->{OCP_parts}{$_[1]} }

sub uri()
{   my $self = shift;
    $self->{OCP_uri} ||= URI->new($self->part('request')->uri)->canonical;
}

sub cld2()
{   my $self = shift;
    return $self->{OCP_cld2} if defined $self->{OCP_cld2};

    my $meta = $self->part('metadata') or return;
    my $cld2 = $meta->value('languages-cld2') or return;
    $self->{OCP_cld2} = decode_json $cld2;
}

1;

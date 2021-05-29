
package OSF::Pipeline::Batch;

use warnings;
use strict;

sub new(%) { my $class = shift; (bless {}, $class)->init( {@_} ) }

sub init($)
{   my ($self, $args) = @_;

    $self->{OPB_name} = $args->{name} or die;
    $self;
}

sub name() { $_[0]->{OPB_name} }

sub getProduct { die "Must be extended" }

1;

# A "Batch" is a short lived Pipeline: it processes a set of files,
# and then it stops.

package OSF::Pipeline::Batch;
use parent 'OSF::Pipeline';

use warnings;
use strict;

use Log::Report 'osf-pipeline';

=chapter NAME

OSF::Pipeline::Batch - run a pipeline in batch mode

=chapter SYNOPSIS
  my $pipe = OSF::Pipeline::Batch->new(...)
  $pipe->processProducts(...);
  $pipe->finish;

=chapter DESCRIPTION
Batch pipelines read static products from a source, usually from
WARC archives.

=chapter METHODS

=c_method new %options
=cut

#sub _init($)
#{   my ($self, $args) = @_;
#    $self->SUPER::_init($args);
#    $self;
#}

=method processProducts %options
Process all products from the batch.
=cut

sub processProducts()
{   my ($self, %args) = @_;

    while(my $product = $self->getProduct)
    {   my $taken = $self->runTasks($product);
    }

    1;
}

=method getProduct
Returns a single product from the batch file(s), which is
different per source of static data.
=cut

sub getProduct { panic "Must be extended" }

1;

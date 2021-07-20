
package OSF::Pipeline;

use warnings;
use strict;

use Log::Report 'osf-pipeline';
use Data::Dumper;

=chapter NAME

OSF::Pipeline - base for all processing pipelines

=chapter SYNOPSIS

  my $pipe = OSF::Pipeline->new(...)
  $pipe->runTasks($_) for @products;
  $pipe->batchFinished;

=chapter DESCRIPTION
All pipeline scripts use a single pipeline, which handles task
processing.  This may be a batch processing of files, but also
the immediate processing of crawling results.

The Pipeline will take Products, and feed them to Tasks.  Each
Task contains a filter, extractor, and packager.

=chapter METHODS

=c_method new %options
Create a new pipeline.  All tasks get initialized.
=required name STRING
=cut

sub new(%) { my $class = shift; (bless {}, $class)->_init( {@_} ) }

sub _init($)
{   my ($self, $args) = @_;

    $self->{OP_name}   = $args->{name}
        or panic "Pipeline without name";

    $self->{OP_closed} = 0;
    $self->{OP_stats}  = {
        products => 0,
        taken    => 0,
        start    => time,
    };

    my @pkgs = grep /^[\w:]+$/, split ' ', $ENV{PIPELINE_TASKS} // '';
    @pkgs or error "No PIPELINE_TASKS in the environment";

    my $tasks = $self->{OP_tasks} = [];
    foreach my $pkg (@pkgs)
    {   eval "require $pkg";
        die $@ if $@;

        $pkg->isa('OSF::Pipeline::Task')
            or error "$pkg is not a pipeline task in PIPELINE_TASKS";

        push @$tasks, $pkg->new(batch => $self);
    }

    $self;
}

=method name
=cut

sub name()  { $_[0]->{OP_name} }

=method stats
Returns a HASH with statistics about the pipeline.  May also be
called after M<batchFinished()>.
=cut

sub stats() { $_[0]->{OP_stats} }

=method isClosed
When M<batchFinished()> has already been executed, you should not attempt
to process more products.
=cut

sub isClosed() { $_[0]->{OP_closed} }

=method tasks
All tasks to be run on each product.
=cut

sub tasks() { @{$_[0]->{OP_tasks}} }

=method showStats
"Nice" display of the pipeline status.
=cut

sub showStats()
{   my $self  = shift;
    my $stats = $self->stats;

    print join "\n  ",
        "Pipeline ".$self->name. ($self->isClosed ? ' (closed)' : ''),
        "products processed: $stats->{products}",
        "products taken:     $stats->{taken}",
        'elapse time:        ' .(time - $stats->{start}). " seconds\n";
}

=method runTasks $product
Run all tasks for a single product.  Returns C<true> when any task
was interested.
=cut

sub runTasks($)
{   my ($self, $product) = @_;
    not $self->isClosed
        or panic "pipeline already closed";

    my $stats = $self->stats;
    $stats->{products}++;
    $stats->{taken}++ if grep $_->take($product), $self->tasks;
    $self;
}

=method batchFinished %options
Must be called when you stop processing a pipeline: some of the tasks
have caches which need to be flushed.
=cut

sub batchFinished(%)
{   my ($self, %args) = @_;
    next if $self->{OP_closed}++;

    $_->batchFinished($self) for $self->tasks;
    1;
}

1;

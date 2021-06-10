package OSF::LinkCollector::Task;
use parent 'OSF::Pipeline::Task';

### Collects ALL links from HTML/XHTML

use warnings;
use strict;
use utf8;

use OSF::Package::Zip  ();

my $collect       = $ENV{LC_COLLECT}
    or die "Environment variable LC_COLLECT missing";

my @content_types = qw(text/html text/xhtml);

sub init($)
{   my ($self, $args) = @_;

    # Exclude
    $args->{accept_content_types} ||= \@content_types;

    # Search

    $self->{OLT_packer} = OSF::Package::Zip->new(directory => $collect);
    $self->SUPER::init($args);
}

sub packer(){ $_[0]->{OLT_packer} }
sub index() { $_[0]->{OLT_index} ||= {} }

sub exclude($)
{   my ($self, $product) = @_;
    return 1 if $self->SUPER::exclude($product);

    0;
}

sub save($$)
{   my ($self, $product, $hits) = @_;
    my $response = $product->part('response') or return;
    my $html     = $response->inspectHTML or return;

use Data::Dumper;
warn Dumper $html->collectMeta;
exit 0;
#   $self->index->{$product->name} = $response->extractLinks;
}

sub finish(%)
{   my ($self, %args) = @_;

    my $batch = $args{batch} or die;
    my $name  = $batch->name;

    my $index = $self->index;
    keys %$index or return;

    $self->packer->addJSON(undef, "$name.links", $index);

    $self->SUPER::finish(%args);
}

1;

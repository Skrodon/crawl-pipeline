package OSF::Planner::Task::LinkCollector;
use parent 'OSF::Pipeline::Task';

use Log::Report 'osf-planner';

### Collects ALL links from HTML/XHTML

use warnings;
use strict;
use utf8;

use JSON ();
use OSF::Package::Zip  ();

my $collect       = $ENV{PLANNER_LC_COLLECT}
    or die "Environment variable PLANNER_LC_COLLECT missing";

my @content_types = qw(text/html text/xhtml);

my $json = JSON->new->utf8->convert_blessed->pretty;

sub _init($)
{   my ($self, $args) = @_;
    $self->{OPTL_packer} = OSF::Package::Zip->new(directory => $collect);
    $self->SUPER::_init($args);
}

sub packer(){ $_[0]->{OPTL_packer} }
sub index() { $_[0]->{OPTL_index} ||= {} }

sub createFilter()
{   my $self = shift;

    my $ct = $self->filterContentType(\@content_types);
    sub {
        my $product = shift;
        $ct->($product) or return;
        [];    # no specific data kept from filter action
    };
}

sub save($$)
{   my ($self, $product, $hits) = @_;
    my $response = $product->part('response') or return;

    my $data = try {
       my $html     = $response->inspectHTML or return;
         +{
            meta  => $html->collectMetaClassic
          , links => $html->collectLinks
          , refs  => $html->collectReferences
          , OpenGraph => $html->collectOpenGraph
          , date  => $response->date
          };
    };

    if(my $fatal = $@->wasFatal)
    {   $product->reportError($@);
#warn $@;
    }

    $self->index->{$product->name} = $data;
}

sub batchFinished()
{   my $self  = shift;

#use Data::Dumper;
print $json->convert_blessed(1)->encode($self->index);
return;
    my $name  = $self->batch->name;
    $self->packer->addJSON(undef, "$name.links", $self->index // {});

    $self->SUPER::batchFinished;
}

1;

package OSF::Package;

use warnings;
use strict;
use utf8;

use Log::Report 'osf-package';

use JSON qw(encode_json);

sub new(%) { my $class = shift; (bless {}, $class)->_init( {@_} ) }

sub _init($)
{   my ($self, $args) = @_;
    $self;
}

sub addFile($$$)
{   my ($self, $product, $name, $ref_bytes) = @_;
    die "Must be overridden";
}

sub addJson($$$)
{   my ($self, $product, $name, $data) = @_;
    $name .= '.json' unless $name =~ m!\.json$!;
    $self->addFile($product, "$name.json", encode_json $data);
}

sub batchFinished() { shift }

1;

package OSF::Package::Zip;
use parent 'OSF::Package';

use warnings;
use strict;

use Log::Report 'osf-package';
use File::Path  qw(make_path);

sub _init($)
{   my ($self, $args) = @_;
    $self->SUPER::_init($args);

    my $dir = $self->{OPZ_root} = $args->{directory}
        or die "directory required";

    make_path $dir;
    $self;
}

sub root() { $_[0]->{OPZ_root} }

sub addFile($$$)
{   my ($self, $product, $name, $ref_bytes) = @_;

    my $dir = $self->root;
    $dir   .= '/' . $product->id;
    make_path $dir;

    my $fn  = "$dir/$name";
    open my $fh, ">:raw", $fn
        or die "ERROR: Cannot write results to $fn: $!";

    $fh->print($$ref_bytes);
    $fh->close
        or die "ERROR: Failed writing full result to $fn: $!";

    $fn;
}

1;

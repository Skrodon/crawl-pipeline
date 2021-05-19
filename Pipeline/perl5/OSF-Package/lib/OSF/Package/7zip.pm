package OSF::Package::7zip;
use parent 'OSF::Package';

use warnings;
use strict;

use File::Path  qw(make_path);

sub init($)
{   my ($self, $args) = @_;

    my $dir = $self->{OP7_root} = $args->{directory}
        or die "directory required";

    make_path $dir;

    $self;
}

sub root() { $_[0]->{OP7_root} }

sub addFile($$$)
{   my ($self, $product, $name, $ref_bytes) = @_;

    my $dir = join '/', $self->root . $product->id;
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

package OSF::Package::7zip;
use parent 'OSF::Package';

use warnings;
use strict;

use Log::Report 'osf-package';

use File::Path   qw(make_path);
use Scalar::Util qw(blessed);

sub _init($)
{   my ($self, $args) = @_;
    $self->SUPER::_init($args);

    my $dir = $self->{OP7_root} = $args->{directory}
        or panic "directory required";

    make_path $dir;
    $self;
}

sub root() { $_[0]->{OP7_root} }

sub addFile($$$)
{   my ($self, $product, $name, $data) = @_;

    my $dir = $self->root;
    $dir   .= '/' . $product->id if $product;

    make_path $dir;

    my $fn  = "$dir/$name";
    open my $fh, ">:raw", $fn
        or fault "Cannot write results to $fn";

    if(blessed $data && $data->isa('OSF::WARC::Record'))
    {   $data->write($fh);
    }
    else
    {   $fh->print(ref $data eq 'SCALAR' ? $$data : $data);
    }

    $fh->close
        or fault "Failed writing full result to $fn";

    $fn;
}

1;

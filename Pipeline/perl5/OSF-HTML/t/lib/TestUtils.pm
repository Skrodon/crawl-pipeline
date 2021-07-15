package TestUtils;
use strict;
use warnings;
use utf8;
use Exporter 'import';
our @EXPORT_OK = qw(slurp);    # symbols to export on request

sub slurp {
    open my $fh, '<', $_[0] || Carp::croak($!);
    local $/;
    return <$fh>;
}

1;

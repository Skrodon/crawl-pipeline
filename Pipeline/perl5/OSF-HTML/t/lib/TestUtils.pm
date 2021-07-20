package TestUtils;
use strict;
use warnings;
use utf8;

use Exporter 'import';
### That's not how exporter should be used:
### package ...; use parent 'Exporter';
### Exporter is called via OO, whether you like it or not.

our @EXPORT_OK = qw(slurp);    # symbols to export on request

sub slurp {
    open my $fh, '<', $_[0] || Carp::croak($!);
    local $/;
    return <$fh>;
}

1;

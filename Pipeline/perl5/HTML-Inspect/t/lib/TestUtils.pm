package TestUtils;
use strict;
use warnings;
use utf8;

use parent 'Exporter';
use Log::Report 'TestUtils';
our @EXPORT_OK = qw(slurp);

sub slurp {
    open my $fh, '<', $_[0] or fault "Cannot read data from $_[0]";
    local $/;
    return <$fh>;
}

1;

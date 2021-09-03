use strict;
use warnings;
use Test::More;
use File::Basename;


plan(skip_all => 'Test::PerlTidy is temporarirly muted');

eval { require Test::PerlTidy; } or do {
    plan(skip_all => 'Test::PerlTidy required to criticise code');
};

my $ROOT = dirname(dirname(__FILE__));

Test::PerlTidy::run_tests(
    #debug    => 1,
    path       => $ROOT,
    exclude    => [ 'blib/', 'data/', ],
    perltidyrc => "$ROOT/.perltidyrc",
);


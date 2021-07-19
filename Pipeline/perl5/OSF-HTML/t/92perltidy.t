use strict;
use warnings;
use Test::More;
use File::Basename;


eval { require Test::PerlTidy; } or do {
    plan(skip_all => 'Test::PerlTidy required to criticise code');
};
### Require Test::PerlTidy in Makefile , but only for tests.

my $ROOT = dirname(__FILE__) . '/..';
### my $ROOT = dirname(dirname(__FILE__));
### my $ROOT = '../../';

Test::PerlTidy::run_tests(

### Why above blank?
    #debug      => 1,
    path       => $ROOT,
    exclude    => ['blib/', 'data/'],
### I prefer a blank after [ and before ]
    perltidyrc => "$ROOT/.perltidyrc"
### When you put a trailing comma here, you will get less syntax errors
### during maintenance later.
);


# t/00_load.t - check module loading
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;

use_ok('HTML::Inspect');
require_ok('HTML::Inspect');


done_testing;

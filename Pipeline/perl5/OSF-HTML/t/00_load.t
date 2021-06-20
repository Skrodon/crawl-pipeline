# t/00_load.t - check module loading
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;

use_ok('OSF::HTML::Inspect');
require_ok('OSF::HTML::Inspect');


done_testing;

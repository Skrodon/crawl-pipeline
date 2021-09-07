use warnings;
use strict;
use Test::More;

use_ok 'HTML::Inspect::Normalize';
HTML::Inspect::Normalize->import;

warn set_base('https://example.com');

done_testing;

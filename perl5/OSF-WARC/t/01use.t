use warnings;
use strict;

use Test::More;

use_ok 'OSF::WARC::Record';
use_ok 'OSF::WARC::Revisit';
use_ok 'OSF::WARC::Conversion';
use_ok 'OSF::WARC::Metadata';
use_ok 'OSF::WARC::Supply';
use_ok 'OSF::WARC::WarcInfo';
use_ok 'OSF::WARC::Response';
use_ok 'OSF::WARC::Request';
use_ok 'OSF::WARC::Sink';

done_testing;

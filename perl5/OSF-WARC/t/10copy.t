# Check that copying of compressed elements works

use warnings;
use strict;

use OSF::WARC::Supply ();
use OSF::WARC::Sink   ();
use Test::More;

my $supply_fn = '../../CommonCrawl/perl5/OSF-CommonCrawl/t/batch1/42-CRAWL.warc.gz';

-f $supply_fn or die "Cannot find WARC example in $supply_fn";

### Open the Supply

my $supply = OSF::WARC::Supply->new(filename => $supply_fn);
ok defined $supply, "Opened supply $supply_fn";

isa_ok $supply, 'OSF::WARC::Supply', '...';

is $supply->filename, $supply_fn, '... filename';

my $info = $supply->warcinfo;
ok defined $info, 'Header record';
is $info->type, 'warcinfo', '... type';

is $info->value('publisher'), 'Common Crawl', '... content';
cmp_ok scalar($info->fields), '==', 9, '... all fields';

### Open the Sink

my $sink_fn = ($ENV{TMPDIR} || '/tmp') . '/sink-test.warc.gz';

my $sink = OSF::WARC::Sink->new(filename => $sink_fn);
ok defined $sink, "Opened sink $sink_fn";
isa_ok $sink, 'OSF::WARC::Sink', '...';
is $sink->filename, $sink_fn, '... filename';

ok -f $sink_fn, '... file created, exists';
ok ! -s $sink_fn, '... file created empty';

### Copy

ok $sink->write($info), 'Write WarcInfo';
ok -s $sink_fn, '... file has grown';

cmp_ok scalar(keys %{$sink->index}), '==', 1, '... one in index';
ok exists $sink->index->{__WARCINFO__}, '... info in index';

my %nr_records;
while(my $record = $supply->getRecord)
{   $nr_records{$record->type}++;

    ok $sink->write($record), '... written record, type '.$record->type;
}

is_deeply \%nr_records, {
   request  => 50,
   response => 50,
   metadata => 50,
}, '... expected 150 records';

cmp_ok scalar(keys %{$sink->index}), '==', 50+1, '... full index';

# Not as long as we cannot take the compressed copies
# cmp_ok -s $sink_fn, '==', -s $supply_fn, 'Copy has same size';


done_testing;

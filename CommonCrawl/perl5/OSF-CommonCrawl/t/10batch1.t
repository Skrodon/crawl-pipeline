
use warnings;
use strict;

use Test::More;
use OSF::CommonCrawl::Batch;

my $source = -d 't/batch1' ? 't/batch1' : -d 'batch1' ? 'batch1' : die "No sources";

my $batch  = OSF::CommonCrawl::Batch->new(source => $source);
isa_ok $batch, 'OSF::CommonCrawl::Batch';

is $batch->name, '42', "Auto name detect";

my $nr_products  = 0;
my $nr_texts     = 0;

while(my $product = $batch->getProduct)
{   $nr_products++;
    ok defined $product, "Product $nr_products, ". $product->name;
    isa_ok $product, 'OSF::CommonCrawl::Product', '...';
    isa_ok $product, 'OSF::Pipeline::Product', '...';
    ok defined $product->contentType, "... ct ".$product->contentType;

    my $request = $product->part('request');
    ok $request, "... found request";
    isa_ok $request, 'OSF::WARC::Request', '... ...';

    my $response = $product->part('response');
    ok $response, "... found response";
    isa_ok $response, 'OSF::WARC::Response', '... ...';

    my $metadata = $product->part('metadata');
    ok $metadata, "... found metadata";
    isa_ok $metadata, 'OSF::WARC::Metadata', '... ...';

use Data::Dumper;
#warn Dumper $metadata->_index;

    if(my $text = $product->part('text'))
    {   ok $text, "... found text";
        isa_ok $text, 'OSF::WARC::Conversion', '... ...';

        if(my $lang = $product->language)
        {   ok defined $lang, "... ... language $lang";
        }

        $nr_texts++;
    }
    else
    {   ok 1, "... does not contain text";
    }
}

cmp_ok $nr_products, '==', 50, "Found all products";
cmp_ok $nr_texts, '==', 48, "Found all texts";

done_testing;

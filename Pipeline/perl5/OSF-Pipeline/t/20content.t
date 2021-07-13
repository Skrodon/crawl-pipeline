
use Test::More;
use warnings;
use strict;

{  package Test::Product;
   use parent 'OSF::Pipeline::Product';

   sub _id { 42 }
   sub _ct { 'text/html' }
   sub _textRef { \"  This  is a\n \nsloppy text..." }
}

my $p = Test::Product->new(
  parts  => { test => 1 },
  origin => 'Test source',
  name   => 'Test name',
);

is $p->id, 42, 'Product id';
is $p->origin, 'Test source', 'Origin';
is $p->name, 'Test name', 'Name';
is $p->contentType, 'text/html', 'Content type';

is $p->contentSize, 29, "Size";
is $p->contentWordChars, 17, "Word Chars";
is $p->contentWords, 5, "Words";

ok ! $p->part('missing'), "Missing part";
ok $p->part('test');

is_deeply $p->stamp(extra => 13),
   { name       => 'Test name',
     origin     => 'Test source',
     content_type => 'text/html',
     extra      => 13,
     product_id => 42,
   }, "Stamp";

done_testing;

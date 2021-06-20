# t/01_basic.t
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;
use_ok('OSF::HTML::Inspect');
my $inspector;
like(
    ($inspector = eval { OSF::HTML::Inspect->new(); } || $@) =>
      qr/^Expected parameter "html_ref/,
    '_init croaks ok'
);
like(
    ($inspector = eval { OSF::HTML::Inspect->new(html_ref => "foo"); } || $@) =>
      qr/^Argument "html_ref/,
    '_init croaks ok2'
);
like(
    ($inspector = eval { OSF::HTML::Inspect->new(html_ref => \"foo"); } || $@) =>
      qr/HTML\sstring\./,
    '_init croaks ok3'
);

$inspector = OSF::HTML::Inspect->new(html_ref => \"<B>FooBar</B>");
isa_ok($inspector => 'OSF::HTML::Inspect');

# note $inspector->doc;
isa_ok($inspector->doc, 'XML::LibXML::Element');
like($inspector->doc => qr|<b>FooBar</b>|, '$inspector->doc lowercased ok');

like($inspector->doc("hehe") => qr/FooBar/, '$inspector->doc() is a read-only getter');
done_testing;

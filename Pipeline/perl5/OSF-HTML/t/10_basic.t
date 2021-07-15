use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";
use Test::More;
use TestUtils qw(slurp);
require_ok('HTML::Inspect');

my $constructor_and_doc = sub {
    my $inspector;
    like(($inspector = eval { HTML::Inspect->new(); } || $@) => qr/^Expected parameter "html_ref/, '_init croaks ok1');
    like(($inspector = eval { HTML::Inspect->new(html_ref => "foo"); }  || $@) => qr/^Argument "html_ref/, '_init croaks ok2');
    like(($inspector = eval { HTML::Inspect->new(html_ref => \"foo"); } || $@) => qr/HTML\sstring\./,      '_init croaks ok3');

    like(($inspector = eval { HTML::Inspect->new(html_ref => \"<B>FooBar</B>"); } || $@) => qr/is\smandatory\./,
         '_init croaks ok4');
    $inspector = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \"<B>FooBar</B>");
    isa_ok($inspector => 'HTML::Inspect');

    # note $inspector->doc;
    isa_ok($inspector->doc, 'XML::LibXML::Element');
    like($inspector->doc => qr|<b>FooBar</b>|, '$inspector->doc, lowercased ok');

    like($inspector->doc("hehe") => qr/FooBar/, '$inspector->doc() is a read-only getter');
};
my $collectMeta = sub {
    my $html      = slurp("$Bin/data/collectMeta.html");
    my $inspector = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $expectedMeta = {
                   charset => 'utf-8',
                   name => {Алабала => 'ница', generator => "Хей, гиди Ванчо", description => 'The Open Graph protocol enables...'},
                   'http-equiv' => {'content-type' => 'text/html;charset=utf-8', refresh => '3;url=https://www.mozilla.org'}
    };
    my $collectedMeta = $inspector->collectMeta();
    is_deeply($collectedMeta => $expectedMeta, 'OHI_meta, parsed ok');
    is($collectedMeta => $inspector->collectMeta(), 'collectMeta() returns already parsed OHI_meta');
};

my $collectOpenGraph = sub {
    my $html = slurp("$Bin/data/collectOpenGraph.html");

    my $inspector = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $og        = $inspector->collectOpenGraph();
    is(ref $og => 'HASH', 'collectOpenGraph() returns a HASH reference');
    note explain $og;
};

my $collectLinks = sub {
    my $html      = slurp("$Bin/data/links.html");
    my $inspector = HTML::Inspect->new(request_uri => 'https://html.spec.whatwg.org/multipage/dom.html', html_ref => \$html);
    my $links     = $inspector->collectLinks();
    is(ref $links           => 'HASH',  'collectLinks() returns a HASH reference');
    is(ref $links->{a_href} => 'ARRAY', 'collectLinks() returns a HASH reference of ARRAYs');
    note explain $links;
};
subtest constructor_and_doc => $constructor_and_doc;
subtest collectMeta         => $collectMeta;
subtest collectOpenGraph    => $collectOpenGraph;
subtest collectLinks        => $collectLinks;


done_testing;

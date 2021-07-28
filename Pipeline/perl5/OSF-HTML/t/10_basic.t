use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";
use Test::More;
use TestUtils qw(slurp);
require_ok('HTML::Inspect');
use Log::Report 'html-inspect';

my $constructor_and_doc = sub {
    my $inspector;
    try { HTML::Inspect->new };
    like($@ => qr/no html/, '_init croaks ok1');
    try { HTML::Inspect->new(html_ref => "foo") };
    like($@ => qr/Not SCALAR/, '_init croaks ok2');
    try { HTML::Inspect->new(html_ref => \"foo") };
    like($@ => qr/Not HTML/, '_init croaks ok3');
    try { HTML::Inspect->new(html_ref => \"<B>FooBar</B>") };
    like($@ => qr/is\smandatory/, '_init croaks ok4');
    $inspector = HTML::Inspect->new(request_uri => 'http://example.com/doc.html', html_ref => \"<B>FooBar</B>");
    isa_ok($inspector => 'HTML::Inspect');
    isa_ok(HTML::Inspect->new(request_uri => URI->new('http://example.com/doc.htm'), html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    isa_ok(HTML::Inspect->new(request_uri => URI->new('http://example.com/doc.htm')->canonical, html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    # note $inspector->doc;
    isa_ok($inspector->doc, 'XML::LibXML::Element');
    like($inspector->doc => qr|<b>FooBar</b>|, '$inspector->doc, lowercased ok');

    like($inspector->doc("hehe") => qr/FooBar/, '$inspector->doc() is a read-only getter');
};

my $collectMeta = sub {
    my $html         = slurp("$Bin/data/collectMeta.html");
    my $inspector    = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $expectedMeta = {
        charset      => 'utf-8',
        name         => {Алабала => 'ница', generator => "Хей, гиди Ванчо", description => 'The Open Graph protocol enables...'},
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
    is(ref $og          => 'HASH',                'collectOpenGraph() returns a HASH reference');
    is($og->{og}{title} => 'Open Graph protocol', 'content is trimmed');
    is_deeply(
        $og => {
            'fb' => {'app_id' => [ {'content' => '115190258555800'} ]},
            'og' => {
                'image' => [
                    {'content' => 'https://ogp.me/logo.png'},
                    {
                        'alt'        => 'A shiny red apple with a bite taken out',
                        'content'    => 'https://example.com/ogp.jpg',
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/ogp.jpg',
                        'type'       => 'image/jpeg',
                        'width'      => '400'
                    },
                    {'content' => 'HTTPS://EXAMPLE.COM/ROCK.JPG'},
                    {'content' => 'HTTPS://EXAMPLE.COM/ROCK2.JPG'}
                ],
                'profile' => [ {'first_name' => "Перко", 'last_name' => "Наумов", 'username' => "наумов"} ],
                'title'   => 'Open Graph protocol',
                'type'    => 'website',
                'url'     => 'https://ogp.me/',
                'video'   => [
                    {
                        'content'    => 'https://example.com/movie.swf',
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/movie.swf',
                        'type'       => 'application/x-shockwave-flash',
                        'width'      => '400'
                    }
                ]
            }
        },
        'all OG meta tags are parsed properly'
    );
    # note explain $og;
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

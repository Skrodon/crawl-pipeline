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
    like($@ => qr/html_ref is required/, '_init croaks ok1');
    try { HTML::Inspect->new(html_ref => "foo") };
    like($@ => qr/html_ref not SCALAR/, '_init croaks ok2');
    try { HTML::Inspect->new(html_ref => \"foo") };
    like($@ => qr/Not HTML/, '_init croaks ok3');
    try { HTML::Inspect->new(html_ref => \"<B>FooBar</B>") };
    like($@ => qr/is\smandatory/, '_init croaks ok4');
    my $req_uri = 'http://example.com/doc.html';
    $inspector = HTML::Inspect->new(request_uri => $req_uri, html_ref => \"<B>FooBar</B>");
    isa_ok($inspector => 'HTML::Inspect');
    is($req_uri => $inspector->requestURI, 'requestURI ok');
    isa_ok(HTML::Inspect->new(request_uri => URI->new('http://example.com/doc.htm'), html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    isa_ok(HTML::Inspect->new(request_uri => URI->new('http://example.com/doc.htm')->canonical, html_ref => \"<B>FooBar</B>"),
        'HTML::Inspect');
    # note $inspector->doc;
    isa_ok($inspector->doc, 'XML::LibXML::Element');
    like($inspector->doc => qr|<b>FooBar</b>|, '$inspector->doc, lowercased ok');

    like($inspector->doc("hehe") => qr/FooBar/, '$inspector->doc() is a read-only getter');
    my $i = HTML::Inspect->new(
        request_uri => $req_uri,
        prefixes    => {bar => 'https://example.com/ns/bar#'},
        html_ref    => \q|<meta property=bar:site_name content="SomeThing">
        <B prefix="foo: https://example.com/ns/foo#">FooBar</B>|
    );
    note 'HI_doc_prefixes:', explain($i->_doc_prefixes);
    is($i->prefix2ns('bar') => 'https://example.com/ns/bar#', 'right prefix');
    is($i->prefix2ns('foo') => 'https://example.com/ns/foo#', 'right prefix');
    is($i->prefix2ns('baz') => 'https://ogp.me/ns/baz#',      'right prefix');
};

my $collectMeta = sub {
    my $html         = slurp("$Bin/data/collectMeta.html");
    my $inspector    = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $expectedMeta = {
        charset => 'utf-8',
        name    =>
          {empty => '', Алабала => 'ница', generator => "Хей, гиди Ванчо", description => 'The Open Graph protocol enables...'},
        'http-equiv' =>
          {'content-disposition' => '', 'content-type' => 'text/html;charset=utf-8', refresh => '3;url=https://www.mozilla.org'},
        'prefixes' => {'fb' => 'https://ogp.me/ns/fb#'}

    };
    my $collectedMeta = $inspector->collectMeta();
    is_deeply($collectedMeta => $expectedMeta, 'HI_meta, parsed ok');
    is($collectedMeta => $inspector->collectMeta(), 'collectMeta() returns already parsed HI_meta');
    note explain $collectedMeta;
    $html          = slurp("$Bin/data/collectMeta-no-charset.html");
    $inspector     = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    $collectedMeta = $inspector->collectMeta();
    is_deeply($collectedMeta => {}, 'no-charset HI_meta, parsed ok');
    is($inspector->base => 'http://example.com/', 'right base');
    note explain $collectedMeta;
};

my $collectOpenGraph = sub {
    my $html = slurp("$Bin/data/collectOpenGraph.html");

    my $i  = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $og = $i->collectOpenGraph();
    is(ref $og          => 'HASH',                 'collectOpenGraph() returns a HASH reference');
    is($og->{og}{title} => 'Open Graph protocol',  'content is trimmed');
    is($og              => $i->collectOpenGraph(), 'collectOpenGraph() returns already parsed Graph data');
    is_deeply(
        $og => {
            fb => {'app_id' => '115190258555800'},
            og => {
                'image' => [
                    {'url' => 'https://ogp.me/logo.png'},
                    {
                        'alt'        => 'A shiny red apple with a bite taken out',
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/ogp.jpg',
                        'type'       => 'image/jpeg',
                        'url'        => 'https://example.com/ogp.jpg',
                        'width'      => '400'
                    },
                    {
                        'url'        => 'HTTPS://EXAMPLE.COM/ROCK.png',
                        'type'       => 'image/png',
                        'secure_url' => 'https://secure.example.com/ROCK.png',
                    },
                    {'url' => 'HTTPS://EXAMPLE.COM/ROCK2.JPG'}
                ],
#XXX This is incorrect use of profile.  Should be: profile:first_name etc
                'profile' => {'first_name' => "Перко", 'last_name' => "Наумов", 'username' => "наумов"},
                'title'   => 'Open Graph protocol',
                'type'    => 'website',
                'url'     => 'https://ogp.me/',
                'video'   => [
                    {
                        'height'     => '300',
                        'secure_url' => 'https://secure.example.com/movie.swf',
                        'type'       => 'application/x-shockwave-flash',
                        'url'        => 'https://example.com/movie.swf',
                        'width'      => '400'
                    }
                ]
            },
        },
        'all OG meta tags are parsed properly'
    );
    note explain $og;

    # ARRAY_TYPES
    $i = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \<<'HTMLOG')->arrayTypes(qr/song/);
    <!-- See https://developers.facebook.com/docs/opengraph/music/ -->
    <meta property="og:title" content="Greatest Hits II"/>
    <meta property="og:type" content="music.album"/>
    <meta property="og:url" content="http://open.spotify.com/album/7rq68qYz66mNdPfidhIEFa"/>
    <meta property="og:image" content="http://o.scdn.co/image/e4c7b06c20c17156e46bbe9a71eb0703281cf345"/>
    <meta property="og:site_name" content="Spotify"/>
    <meta property="fb:app_id" content="174829003346"/>
    <meta property="og:description" content="Greatest Hits II, an album by Queen on Spotify."/>

    <meta property="music:release_date" content="2011-04-19">
    <meta property="music:musician" content="http://open.spotify.com/artist/1dfeR4HaWDbWqFHLkxsg1d">
    <meta property="music:song" content="http://open.spotify.com/track/0pfHfdUNVwlXA0WDXznm2C">
    <meta property="music:song:disc" content="1">
    <meta property="music:song:track" content="1">
    <meta property="music:song" content="http://open.spotify.com/track/2aSFLiDPreOVP6KHiWk4lF">
    <meta property="music:song:disc" content="1">
    <meta property="music:song:track" content="2">
HTMLOG

    $og = $i->collectOpenGraph();
    is_deeply(
        $og => {
            og => {
                'description' => 'Greatest Hits II, an album by Queen on Spotify.',
                'image'       => [ {url => 'http://o.scdn.co/image/e4c7b06c20c17156e46bbe9a71eb0703281cf345'} ],
                'site_name'   => 'Spotify',
                'title'       => 'Greatest Hits II',
                'type'        => 'music.album',
                'url'         => 'http://open.spotify.com/album/7rq68qYz66mNdPfidhIEFa'
            },
            fb    => {'app_id' => '174829003346'},
            music => {
                'musician'     => ['http://open.spotify.com/artist/1dfeR4HaWDbWqFHLkxsg1d'],
                'release_date' => '2011-04-19',
                'song'         => [
                    {'disc' => '1', 'track' => '1', 'description' => 'http://open.spotify.com/track/0pfHfdUNVwlXA0WDXznm2C'},
                    {'disc' => '1', 'track' => '2', 'description' => 'http://open.spotify.com/track/2aSFLiDPreOVP6KHiWk4lF'}
                ]
            }
        },
        'Only song array type is recognised.'
    );
    note explain $og;
};

my $collectReferences = sub {
    my $html      = slurp("$Bin/data/links.html");
    my $inspector = HTML::Inspect->new(request_uri => 'https://html.spec.whatwg.org/multipage/dom.html', html_ref => \$html);
    my $links     = $inspector->collectReferences();
    is(ref $links           => 'HASH',                          'collectReferences() returns a HASH reference');
    is(ref $links->{a_href} => 'ARRAY',                         'collectReferences() returns a HASH reference of ARRAYs');
    is($links               => $inspector->collectReferences(), 'same reference');
    # note explain $links;
};

subtest constructor_and_doc => $constructor_and_doc;
subtest collectMeta         => $collectMeta;
subtest collectOpenGraph    => $collectOpenGraph;
subtest collectReferences   => $collectReferences;

done_testing;

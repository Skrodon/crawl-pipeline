use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use lib "$Bin/lib";
use lib "$Bin/../lib";
use Test::More;
use TestUtils qw(slurp);
use HTML::Inspect;

# Testing collectLinks() thoroughly here
my $html      = slurp("$Bin/data/links.html");
my $inspector = HTML::Inspect->new(request_uri => 'https://html.spec.whatwg.org/multipage/dom.html', html_ref => \$html);

###
### collectReferences
###

my $refs = $inspector->collectReferences;
#note explain $refs;

# Have we collected all links that we support?
my $ref_attributes = $inspector->_refAttributes;
while (my ($t, $a) = each %$ref_attributes) {
    ok $refs->{"${t}_$a"}, "${t}_$a were found in document";

    # Are the refs deduplicated?
    my @refs_kind = $inspector->doc->findnodes("//$t\[\@$a\]");
    cmp_ok scalar @refs_kind, '>', scalar @{$refs->{"${t}_$a"}}, "${t}_$a refs are deduplicated";
}

# See all deduplicated links from the parsed document.
# Are all links absolute(and canonical) URI instance?
#note explain $refs;
is_deeply(
    $refs => {
        'a_href' => [
            'https://whatwg.org/',
            'https://html.spec.whatwg.org/multipage/structured-data.html',
            'https://html.spec.whatwg.org/multipage/',
            'https://html.spec.whatwg.org/multipage/semantics.html',
            'https://html.spec.whatwg.org/multipage/dom.html#dom',
            'https://html.spec.whatwg.org/multipage/dom.html#documents',
            'https://html.spec.whatwg.org/multipage/dom.html#elements',
            'https://html.spec.whatwg.org/multipage/dom.html#semantics-2',
            'https://html.spec.whatwg.org/multipage/dom.html#elements-in-the-dom',
            'https://html.spec.whatwg.org/multipage/dom.html#html-element-constructors',
            'https://html.spec.whatwg.org/multipage/dom.html#element-definitions',
            'https://html.spec.whatwg.org/multipage/#documents',
            'https://html.spec.whatwg.org/multipage/#document',
            'https://html.spec.whatwg.org/multipage/references.html#refsDOM',
            'https://dom.spec.whatwg.org/#concept-document-url'
        ],
        'area_href' => [
            'https://mozilla.org',                                   'https://developer.mozilla.org/',
            'https://developer.mozilla.org/docs/Web/Guide/Graphics', 'https://developer.mozilla.org/docs/Web/CSS'
        ],
        'base_href'   => ['https://html.spec.whatwg.org/multipage/'],
        'embed_src'   => ['https://html.spec.whatwg.org/media/cc0-videos/flower.mp4'],
        'form_action' => ['https://html.spec.whatwg.org/multipage/x'],
        'iframe_src'  => [
            'https://www.openstreetmap.org/export/embed.html?bbox=-0.004017949104309083%2C51.47612752641776%2C0.00030577182769775396%2C51.478569861898606&layer=mapnik'
        ],
        'img_src'   => [ 'https://resources.whatwg.org/logo.svg', 'https://html.spec.whatwg.org/media/examples/mdn-info.png' ],
        'link_href' => [
            'https://resources.whatwg.org/spec.css',                     'https://resources.whatwg.org/standard.css',
            'https://resources.whatwg.org/standard-shared-with-dev.css', 'https://resources.whatwg.org/logo.svg',
            'https://html.spec.whatwg.org/styles.css'
        ],
        'script_src' => [
            'https://html.spec.whatwg.org/link-fixup.js', 'https://html.spec.whatwg.org/html-dfn.js',
            'https://resources.whatwg.org/file-issue.js'
        ]
    },
    'all references are collected'
);

###
### collectLinks
###

my $links = $inspector->collectLinks;
#note explain $links;

is_deeply $links,
  {
    'icon' => [
        {'crossorigin' => 'use-credentials', 'href' => 'https://resources.whatwg.org/logo.svg'},
        {'href'        => 'https://resources.whatwg.org/logo.svg'}
    ],
    'stylesheet' => [
        {'crossorigin' => 'anonymous', 'href' => 'https://resources.whatwg.org/spec.css'},
        {'crossorigin' => '',          'href' => 'https://resources.whatwg.org/standard.css'},
        {'href'        => 'https://resources.whatwg.org/standard-shared-with-dev.css'},
        {'href'        => 'https://resources.whatwg.org/standard-shared-with-dev.css'},
        {'crossorigin' => '', 'href' => 'https://html.spec.whatwg.org/styles.css'}
    ]
  },
  'all link elements are collected';

done_testing;

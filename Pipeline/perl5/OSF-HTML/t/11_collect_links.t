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

my $refs      = $inspector->collectReferences;
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
is_deeply(
    $refs =>
    {
        'a_href' => [
            bless(do { \(my $o = 'https://whatwg.org/') },                                                       'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/structured-data.html') },               'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/') },                                   'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/semantics.html') },                     'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#dom') },                       'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#documents') },                 'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#elements') },                  'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#semantics-2') },               'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#elements-in-the-dom') },       'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#html-element-constructors') }, 'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#element-definitions') },       'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html#document') },                  'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/references.html#refsDOM') },            'URI::https'),
            bless(do { \(my $o = 'https://dom.spec.whatwg.org/#concept-document-url') },                         'URI::https')
        ],
        'area_href' => [
            bless(do { \(my $o = 'https://mozilla.org/') },                                  'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/') },                        'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/docs/Web/Guide/Graphics') }, 'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/docs/Web/CSS') },            'URI::https')
        ],
        'base_href'   => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/') },                  'URI::https') ],
        'embed_src'   => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/media/cc0-videos/flower.mp4') }, 'URI::https') ],
        'form_action' => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/dom.html') },          'URI::https') ],
        'iframe_src'  => [
            bless(
                do {
                    \(my $o
                          = 'https://www.openstreetmap.org/export/embed.html?bbox=-0.004017949104309083%2C51.47612752641776%2C0.00030577182769775396%2C51.478569861898606&layer=mapnik'
                     );
                },
                'URI::https'
            )
        ],
        'img_src' => [
            bless(do { \(my $o = 'https://resources.whatwg.org/logo.svg') },                    'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/media/examples/mdn-info.png') }, 'URI::https')
        ],
        'link_href' => [
            bless(do { \(my $o = 'https://resources.whatwg.org/spec.css') },                     'URI::https'),
            bless(do { \(my $o = 'https://resources.whatwg.org/standard.css') },                 'URI::https'),
            bless(do { \(my $o = 'https://resources.whatwg.org/standard-shared-with-dev.css') }, 'URI::https'),
            bless(do { \(my $o = 'https://resources.whatwg.org/logo.svg') },                     'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/styles.css') },                   'URI::https')
        ],
        'script_src' => [
            bless(do { \(my $o = 'https://html.spec.whatwg.org/link-fixup.js') }, 'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/html-dfn.js') },   'URI::https'),
            bless(do { \(my $o = 'https://resources.whatwg.org/file-issue.js') }, 'URI::https')
        ]
    },
    'all references are collected'
);

###
### collectLinks
###

my $links = $inspector->collectLinks;
#note explain $links;

is_deeply
   $links,
  {
    icon => [
      {
        crossorigin => 'use-credentials',
        href => 'https://resources.whatwg.org/logo.svg',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/logo.svg')}, 'URI::https' ),
        rel => 'icon'
      },
      {
        href => 'https://resources.whatwg.org/logo.svg',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/logo.svg')}, 'URI::https' ),
        rel => 'icon'
      }
    ],
    stylesheet => [
      {
        crossorigin => 'anonymous',
        href => 'https://resources.whatwg.org/spec.css',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/spec.css')}, 'URI::https' ),
        rel => 'stylesheet'
      },
      {
        crossorigin => '',
        href => 'https://resources.whatwg.org/standard.css',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/standard.css')}, 'URI::https' ),
        rel => 'stylesheet'
      },
      {
        href => 'https://resources.whatwg.org/standard-shared-with-dev.css',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/standard-shared-with-dev.css')}, 'URI::https' ),
        rel => 'stylesheet'
      },
      {
        href => 'https://resources.whatwg.org/standard-shared-with-dev.css',
        href_uri => bless( do{\(my $o = 'https://resources.whatwg.org/standard-shared-with-dev.css')}, 'URI::https' ),
        rel => 'stylesheet'
      },
      {
        crossorigin => '',
        href => '/styles.css',
        href_uri => bless( do{\(my $o = 'https://html.spec.whatwg.org/styles.css')}, 'URI::https' ),
        rel => 'stylesheet'
      }
    ]
  },
   'all link elements are collected';

done_testing;

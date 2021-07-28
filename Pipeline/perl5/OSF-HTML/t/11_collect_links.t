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
my $links     = $inspector->collectLinks();

# Have we collected all links that we support?
my %link_attributes = $inspector->linkAttributes;
while (my ($t, $a) = each %link_attributes) {
    ok(exists $links->{"${t}_$a"}, "${t}_$a were found in document");

    # Are the links deduplicated?
    my @links_kind = $inspector->doc->findnodes("//$t\[\@$a\]");
    cmp_ok(scalar @links_kind, '>', scalar @{$links->{"${t}_$a"}}, "${t}_$a are deduplicated");
}

# See all deduplicated links from the parsed document.
# note explain $links;
# Are all links absolute(and canonical) URI instance?
is_deeply(
    $links => {
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
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/#documents') },                         'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/#document') },                          'URI::https'),
            bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/references.html#refsDOM') },            'URI::https'),
            bless(do { \(my $o = 'https://dom.spec.whatwg.org/#concept-document-url') },                         'URI::https')
        ],
        'area_href' => [
            bless(do { \(my $o = 'https://mozilla.org') },                                   'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/') },                        'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/docs/Web/Guide/Graphics') }, 'URI::https'),
            bless(do { \(my $o = 'https://developer.mozilla.org/docs/Web/CSS') },            'URI::https')
        ],
        'base_href'   => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/') },                  'URI::https') ],
        'embed_src'   => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/media/cc0-videos/flower.mp4') }, 'URI::https') ],
        'form_action' => [ bless(do { \(my $o = 'https://html.spec.whatwg.org/multipage/') },                  'URI::https') ],
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
    'all links are collected'
);

done_testing();

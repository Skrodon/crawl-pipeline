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

# maybe we need this to be a global variable or we need a getter
my %attributesWithLinks = (
    a      => 'href',
    area   => 'href',
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',
    script => 'src',
    base   => 'href',

    # more ?..
);

# Have we collected all links that we support?
while (my ($t, $a) = each(%attributesWithLinks)) {
    ok(exists $links->{"${t}_$a"}, "${t}_$a were found in document");

    # Are all links absolute == canonical?
    for my $link (@{$links->{"${t}_$a"}}) {
        isa_ok($link => 'URI', 'the link is an URI instance');
        is(URI->new("$link")->scheme => 'https', 'right scheme - absolute url');
    }

    # Do the links need to be deduplicated? I think - No
    # What else can/should we test?..

    # What does it mean "Are some related? Then return structured"?
}

note explain $links;

done_testing();

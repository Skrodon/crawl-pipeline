# t/01_basic.t
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Test::More;
use strict;
use warnings;
use utf8;

require_ok('OSF::HTML::Inspect');

my $constructor_and_doc = sub {
    my $inspector;
    like(
        ($inspector = eval { OSF::HTML::Inspect->new(); } || $@) =>
          qr/^Expected parameter "html_ref/,
        '_init croaks ok1'
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
    like($inspector->doc => qr|<b>FooBar</b>|, '$inspector->doc, lowercased ok');

    like(
        $inspector->doc("hehe") => qr/FooBar/,
        '$inspector->doc() is a read-only getter'
    );
};

my $collectMeta = sub {
    my $inspector = OSF::HTML::Inspect->new(
        html_ref => \_slurp("$Bin/data/collectMeta.html"));
    my $expectedMeta = {
        charset => 'utf-8',
        name    => {
            Алабала     => 'ница',
            generator   => "Хей, гиди Ванчо",
            description => 'The Open Graph protocol enables...'
        },
        'http-equiv' => {
            'content-type' => 'text/html;charset=utf-8',
            refresh        => '3;url=https://www.mozilla.org'
        }
    };
    my $collectedMeta = $inspector->collectMeta();
    is_deeply($collectedMeta => $expectedMeta, 'OHI_meta, parsed ok');
    is( $collectedMeta => $inspector->collectMeta(),
        'collectMeta() returns already parsed OHI_meta'
    );
};

subtest constructor_and_doc => $constructor_and_doc;
subtest collectMeta         => $collectMeta;

sub _slurp {
    open my $fh, '<', $_[0] || Carp::croak($!);
    local $/;
    return <$fh>;
}

done_testing;

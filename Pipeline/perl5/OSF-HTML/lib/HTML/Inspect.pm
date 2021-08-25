package HTML::Inspect;

use strict;
use warnings;
use utf8;

no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

use Log::Report 'html-inspect';

use HTML::Inspect::Util       qw(trim_attr xpc_find);
use HTML::Inspect::OpenGraph  ();  # mixin for collectOpenGraph()
use HTML::Inspect::References ();  # mixin for collectReferences()

use XML::LibXML  ();
use Scalar::Util qw(blessed);
use URI          ();
use URI::Fast    qw(html_url);

=encoding utf-8

=head1 NAME

HTML::Inspect - Inspect a HTML document

=head1 SYNOPSIS

    my $html         = slurp("t/data/collectMeta.html");
    my $inspector    = HTML::Inspect->new(request_uri => 'http://example.com/doc', html_ref => \$html);
    my $collectedMeta = $inspector->collectMeta();
    # $collectedMeta is:
    #{
    #    charset      => 'utf-8',
    #    name         => {
    #        Алабала => 'ница',
    #        generator => "Хей, гиди Ванчо",
    #        description => 'The Open Graph protocol enables...'
    #    },
    #    'http-equiv' => {
    #        'content-type' => 'text/html;charset=utf-8',
    #        refresh => '3;url=https://www.mozilla.org'
    #    }
    #};

=head1 DESCRIPTION

HTML::Inspect uses L<XML::LibXML> to parse a document as fast as possible and
returns different logical parts of it into self explanatory structures of data,
which can further be used for document analisys as part of a bigger pipeline.
See C<t/*.t> files for examples of use and returned results.

=head1 Constructors

=head2 new

    my $self = $class->new(%options)

Arguments: C<request_uri> and C<html_ref>. C<request_uri> is an absolute url as
a string or an L<URI> instance. C<html_ref> is areference to the valid HTML
string. Both argunebts are mandatory.

=cut

sub new {
    my $class = shift;
    (bless {}, $class)->_init({@_});
}

sub _init ($self, $args) {
    my $html_ref = $args->{html_ref} or panic "html_ref is required";
    ref $html_ref eq 'SCALAR'        or panic "html_ref not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or error "Not HTML: '".substr($$html_ref, 0, 20)."'";

    my $req = $args->{request_uri}   or panic '"request_uri" is mandatory';
    my $uri = $self->{HI_request_uri} = blessed $req && $req->isa('URI') ? $req : URI->new($req);

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );
    my $doc = $self->{HI_doc} = $dom->documentElement;

    $self->{HI_xpc} = XML::LibXML::XPathContext->new($doc);

    my $base;
    state $find_base_href = xpc_find '//base[@href][1]';
    if(my ($base_elem) = $find_base_href->($self)) {
        # Sometimes, base does not contain scheme.
        $base = html_url($base_elem->getAttribute('href'), $uri);
    }
    else {
        $base = $uri->canonical;
    }
    $self->{HI_base} = $base->as_string;

    $self;
}

#-------------------------

=head1 Accessors

=head2 doc

    my $doc = $self->doc;

Readonly accessor.
Returns instance of XML::LibXML::Element, representing the root node of the
document and everything in it.
=cut

sub doc { $_[0]->{HI_doc} }

=head2 xpc

    my $xpath_context = $self->xpc;

Readonly accessor.
Returns instance of XML::LibXML::XPathContext, representing the XPATH context
with attached root node of the document and everything in it. Using find,
findvalue and L<XML::LibXML::XPathContext/findnodes> is slightly faster than
C<$doc-E<gt>findnodes($xpath_expression)>.
=cut

sub xpc { $_[0]->{HI_xpc} }

=head2 requestURI

    my $uri = $self->requestURI;

Readonly accessor.
The L<URI> object which represents the C<request_uri> parameter which was
passed as default base for relative links to C<new()>.
=cut

sub requestURI { $_[0]->{HI_request_uri} }

=head2 base

    my $uri = $self->base;

Readonly accessor.
The base URI, which is used for relative links in the page.  This is the
C<requestURI> unless the HTML contains a C<< <base href> >> declaration.  The
base URI is normalized.
=cut

sub base { $_[0]->{HI_base} }

#-------------------------

=head1 Collecting

=head2 collectMeta 

    my $hash = $html->collectMeta(%options);

Returns a HASH reference with all C<< <meta> >> information of traditional content:
each value will only appear once. OpenGraph meta-data records use attribute
'property', and are ignored here.

Example:

    {  'http-equiv' => { 'content-type' => 'text/plain' },
        charset => 'UTF-8',
        name => { author => 'John Smith' , description => 'The John Smith\'s page.'},
    }

=cut

sub collectMeta($self, %args) {
    return $self->{HI_meta} if $self->{HI_meta};

    state $meta_classic = xpc_find '//meta[@http-equiv or @name or @charset]';
    my %meta;
    foreach my $meta ($meta_classic->($self)) {
        if(my $http = $meta->getAttribute('http-equiv')) {
            my $content = $meta->getAttribute('content') // next;
            $meta{'http-equiv'}{lc $http} = trim_attr $content;
        }
        elsif(my $name = $meta->getAttribute('name')) {
            my $content = $meta->getAttribute('content') // next;
            $meta{name}{$name} = trim_attr $content;
        }
        elsif(my $charset = $meta->getAttribute('charset')) {
            $meta{charset} = lc $charset;
        }
    }

    $self->{HI_meta} = \%meta;
}

=head2 collectLinks 

    $hash = $self->collectLinks;

Collect all C<< <link> >> relations from the document.  The returned HASH
contains the relation (the C<rel> attribute, required) to an ARRAY of
link elements with that value.  The ARRAY elements are HASHes of all
attributes of the link and and all lower-cased.  The added C<href_uri>
key will be a normalized, absolute translation of the C<href> attribute.
=cut

sub collectLinks($self) {
    return $self->{HI_links} if $self->{HI_links};
    my $base = $self->base;

    state $find_link_rel = xpc_find '//link[@rel]';

    my %links;
    foreach my $link ($find_link_rel->($self)) {
        my %attrs = map +($_->name => $_->value),
            grep $_->isa('XML::LibXML::Attr'), $link->attributes;
        $attrs{href} = html_url($attrs{href} || 'x', $base)->as_string if exists $attrs{href};
        push @{$links{delete $attrs{rel}}}, \%attrs;
    }

    $self->{HI_links} = \%links;
}

=head2 collectReferences 

    $hash = $self->collectReferences;

Collects all references from document. Returns a HASH reference with
keys like C<$tag_$attr> and values an ARRAY of unique URIs found in such
tags and attributes. The URIs are in their textual order in the document,
where only the first encounter is recorded.
=cut

### collectReferences() is in mixin file ::References


=head2 collectOpenGraph

    $hash = $self->collectOpenGraph;

=cut

### collectOpenGraph() is in mixin file ::OpenGraph

=head1 SEE ALSO

L<URI::Fast>, L<XML::LibXML>, L<Log::Report>

=head1 AUTHORS and COPYRIGHT
    
    Mark Overmeer
    CPAN ID: MARKOV
    markov at cpan dot org
    https://solutions.overmeer.net/

    Красимир Беров
    CPAN ID: BEROV
    berov на cpan точка org
    https://studio-berov.eu

This is free software, licensed under:

The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the LICENSE file included with
this module.

This distribution contains other free software  and content which belongs to
their respective authors.
=cut

1;

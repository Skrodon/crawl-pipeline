package HTML::Inspect;
use strict;
use warnings;
use utf8;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

use XML::LibXML  ();
use URI;
use Log::Report 'html-inspect';
use Scalar::Util qw(blessed);
use List::Util   qw(uniq);

# A map: for which tag which attributes to be considered as links?
# We can add more tags and types of links later.
my %referencing_attributes = (
    a      => 'href',
    area   => 'href',
    base   => 'href',     # could be kept from the start, would add complexity
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',     # could use collectLinks(), but probably slower by complexity
    script => 'src',
);
sub _refAttributes($thing) { return \%referencing_attributes }    # for testing only

# Precompiled xpath expressions to be reused by instances of this class.
# Not much more faster than literal string passing but still faster.
# See xt/benchmark_collectOpenGraph.pl
my $X_BASE          = XML::LibXML::XPathExpression->new('//base[@href][1]');
my $X_META_PROPERTY = XML::LibXML::XPathExpression->new('//meta[@property]');
my $X_NOT_PROPERTY  = XML::LibXML::XPathExpression->new('//meta[not(@property) and (@http-equiv or @name or @charset)]');
my $X_LINK_REL      = XML::LibXML::XPathExpression->new('//link[@rel]');
my %X_REF_ATTRS;
$X_REF_ATTRS{"$_\_$referencing_attributes{$_}"} = XML::LibXML::XPathExpression->new("//$_\[\@$referencing_attributes{$_}\]")
  for (keys %referencing_attributes);
# Types which may be met more than once in a document. These are usually alternatives of each other.
my $ARRAY_TYPES = qr/image|video|audio/;


# Deduplicate white spaces and trim string.
sub _trimss { return ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z$//r }

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
    return (bless {}, $class)->_init({@_});
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
    my $xpc = $self->{HI_xpc} = XML::LibXML::XPathContext->new($doc);

    my $base_elem = $xpc->findvalue($X_BASE);
    $self->{HI_base} = $base_elem ? $base_elem->getAttribute('href') : $uri->canonical;

    return $self;
}

#-------------------------

=head1 Accessors

=head2 doc

    my $doc = $self->doc;

Readonly accessor.
Returns instance of XML::LibXML::Element, representing the root node of the
document and everything in it.
=cut

sub doc { return $_[0]->{HI_doc} }

=head2 xpc

    my $xpath_context = $self->xpc

Readonly accessor.
Returns instance of XML::LibXML::XPathContext, representing the XPATH context
with attached root node of the document and everything in it. Using find,
findvalue and L<XML::LibXML::XPathContext/findnodes> is slightly faster than
C<$doc-E<gt>findnodes($xpath_expression)>.
=cut

sub xpc { return $_[0]->{HI_xpc} }

=head2 prefix2ns

Readonly static accessor.
Retuns the corresponding namespace for a prefix.

    my $ns = $self->prefix2ns('og'); # https://ogp.me/ns#
    my $ns = HTML::Inspect->prefix2ns('og'); # https://ogp.me/ns#
    my $ns = HTML::Inspect->prefix2ns('video'); #https://ogp.me/ns/video# 
=cut


sub prefix2ns ($self, $prefix) {
# Default and known namespaces for collectOpenGraph() when we have a document
# with no explicitly defined prefix(namespace), but then in the document it is
# used. These cases are very common.
    state %PREFIXES = (
        fb      => 'https://ogp.me/ns/fb#',
        og      => 'https://ogp.me/ns#',
        image   => 'https://ogp.me/ns/image#',
        music   => 'https://ogp.me/ns/music#',
        video   => 'https://ogp.me/ns/video#',
        article => 'https://ogp.me/ns/article#',
        book    => 'https://ogp.me/ns/book#',
        profile => 'https://ogp.me/ns/profile#',
        # From https://ogp.me/ : "No additional properties other than the basic
        # ones. Any non-marked up webpage should be treated as og:type website."
        website => 'https://ogp.me/ns/website#',
    );

    return $PREFIXES{$prefix};
}

=head2 requestURI

    my $uri = $self->requestURI;

Readonly accessor.
The L<URI> object which represents the C<request_uri> parameter which was
passed as default base for relative links to C<new()>.
=cut

sub requestURI { return $_[0]->{HI_request_uri} }

=head2 base

    my $uri = $self->base;

Readonly accessor.
The base URI, which is used for relative links in the page.  This is the
C<requestURI> unless the HTML contains a C<< <base href> >> declaration.  The
base URI is normalized.
=cut

sub base { return $_[0]->{HI_base} }

#-------------------------

=head1 Collecting

=head2 collectMeta 

    my $hash = $html->collectMeta(%options);

Returns a HASH reference with all <meta> information of traditional content:
each value will only appear once. OpenGraph meta-data records use attribute
'property', and are ignored here.

Example:

    { 'http-equiv' => { 'content-type' => 'text/plain' }
        charset => 'UTF-8',
        name => { author => 'John Smith' , description => 'The John Smith\'s page.'}
    }

=cut

sub collectMeta ($self, %args) {
    return $self->{HI_meta} if $self->{HI_meta};

    my %meta;
    foreach my $meta ($self->xpc->findnodes($X_NOT_PROPERTY)) {
        if(my $http = $meta->getAttribute('http-equiv')) {
            my $content = $meta->getAttribute('content') // next;
            $meta{'http-equiv'}{lc $http} = _trimss($content);
        }
        elsif(my $name = $meta->getAttribute('name')) {
            my $content = $meta->getAttribute('content') // next;
            $meta{name}{$name} = _trimss($content);
        }
        elsif(my $charset = $meta->getAttribute('charset')) {
            $meta{charset} = lc $charset;
        }
    }
    return $self->{HI_meta} = \%meta;
}

=head2 collectReferences 

    $hash = $self->collectReferences;

Collects all references from document. Returns a HASH reference with
keys like C<$tag_$attr> and values an ARRAY of unique URIs found in such
tags and attributes. The URIs are in their textual order in the document,
where only the first encounter is recorded.
=cut

sub collectReferences($self) {
    return $self->{HI_refs} if $self->{HI_refs};
    my $base = $self->base;

    my %refs;
    while (my ($tag, $attr) = each %referencing_attributes) {
        my @attr = uniq map { URI->new_abs($_->getAttribute($attr), $base)->canonical }
          $self->xpc->findnodes($X_REF_ATTRS{"${tag}_$attr"});
        $refs{"${tag}_$attr"} = \@attr if @attr;
    }

    return $self->{HI_refs} = \%refs;
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

    my %links;
    foreach my $link ($self->xpc->findnodes($X_LINK_REL)) {
        my %attrs = map { $_->name => $_->value } grep { $_->isa('XML::LibXML::Attr') } $link->attributes;
        $attrs{href_uri} = URI->new_abs($attrs{href}, $base)->canonical if $attrs{href};
        push @{$links{$attrs{rel}}}, \%attrs;
    }

    return $self->{HI_links} = \%links;
}

=head2 collectOpenGraph

    my $hash = $self->collectOpenGraph();

Collects all meta elements which have an attribute C<property>.  See
t/12_collect_opengraph.t for examples of the HASH reference structure which is
returned. 

Example

    my $html = slurp("$Bin/data/open-graph-protocol-examples/article-offset.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://example.com/article-offset.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    
   # {
   #   'https://ogp.me/ns#' => {
   #     'image' => [
   #       {
   #         'height' => '50',
   #         'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
   #         'type' => 'image/png',
   #         'url' => 'http://examples.opengraphprotocol.us/media/images/50.png',
   #         'width' => '50'
   #       }
   #     ],
   #     'locale' => 'en_US',
   #     'site_name' => 'Open Graph protocol examples',
   #     'title' => 'John Doe profile page',
   #     'type' => 'profile',
   #     'url' => 'http://examples.opengraphprotocol.us/profile.html'
   #   },
   #   'https://ogp.me/ns/profile#' => {
   #     'first_name' => 'John',
   #     'gender' => 'male',
   #     'last_name' => 'Doe',
   #     'username' => 'johndoe'
   #   }
   # }

=cut

# TODO: Implement collection fo all tags specified in this page
# https://developers.facebook.com/docs/sharing/webmasters
# https://ogp.me/#types
# See also: https://developers.facebook.com/docs/sharing/webmasters/crawler
# https://developers.facebook.com/docs/sharing/webmasters/optimizing
sub collectOpenGraph ($self, %args) {
    return $self->{HI_og} if $self->{HI_og};
    my $og = {};
    $self->_handle_og_meta($og, $_) for $self->doc->findnodes($X_META_PROPERTY);
    return $self->{HI_og} = $og;
}

# A not so dummy, implementation of collecting OG data from a page
sub _handle_og_meta ($self, $og, $meta) {
    my ($prefix, $type, $attr) = split /:/, lc $meta->getAttribute('property');
    my $curie   = $self->prefix2ns($prefix);
    my $ns      = ($og->{$curie} //= {});
    my $content = _trimss $meta->getAttribute('content');
    if($prefix ne 'og') {
        # warn "_handle_other_prefix(" . $meta->getAttribute('property');
        _handle_other_prefix($ns, $type, $content);
    }
    elsif(!defined $attr) {
        # warn "_handle_no_attr(" . $meta->getAttribute('property');
        _handle_no_attr($ns, $type, $content);
    }
    else {
        # warn "_handle_attr(" . $meta->getAttribute('property');
        _handle_attr($ns, $type, $attr, $content);
    }
    return;
}

# Handle cases like og:audio:author, where we have the namespace, type and
# attribute.
sub _handle_attr ($ns, $type, $attr, $content) {
    if(!exists $ns->{$type}) {
        if($type =~ $ARRAY_TYPES) {
            $ns->{$type} = [ {$attr => $content} ];
        }
        else {
            $ns->{$type} = {$attr => $content};
        }
        return;
    }
    # An already defined object of type $type.
    my $ns_type = $ns->{$type};
    if(ref $ns_type eq 'ARRAY') {
        if(!exists $ns_type->[-1]{$attr}) {
            $ns_type->[-1]{$attr} = $content;
        }
        # Starting a new object
        else {
            push @$ns_type, {$attr => $content};
        }
    }
    else {
        $ns_type->{$attr} = $content;
    }
    return;
}

# Handle cases like og:image or og:audio, where we have to introduce an 'url'
# atribute if we have other atributes of the same object later in the data.
sub _handle_no_attr ($ns, $type, $content) {

    # Handle og properties
    if(!exists $ns->{$type}) {
        # There is no way to have image as an og property and as an array
        # object at the same time, so the first image in the image array is a
        # property of the default type(website).
        if($type =~ $ARRAY_TYPES) {
            $ns->{$type} = [ {url => $content} ];
        }
        # this is a property of og
        else {
            $ns->{$type} = $content;
        }
        return;
    }
    # An already deined object of type $type.
    my $ns_type = $ns->{$type};

    if(ref $ns_type eq 'ARRAY') {
        push @$ns_type, {url => $content};
    }
    else {
        my $first_content = $ns_type;
        $ns_type = [ $first_content, {url => $content} ];
    }
    return;
}

# Handle cases like audio:author or image:width, where the object is in separate
# namespace, named after its type.
sub _handle_other_prefix ($type, $attr, $content) {
    if(!exists $type->{$attr}) {
        $type->{$attr} = $content;
    }
    elsif(ref $type->{$attr} eq 'ARRAY') {
        push @{$type->{$attr}}, $content;
    }
    else {
        my $first_content = $type->{$attr};
        $type->{$attr} = [ $first_content, $content ];
    }
    return;
}

=head1 SEE ALSO

L<URI>, L<XML::LibXML>, L<Log::Report>

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

package HTML::Inspect;
use strict;
use warnings;
use utf8;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

# TODO: Add POD. Prepare for CPAN
use XML::LibXML();
use URI;
use Log::Report 'html-inspect';
use Scalar::Util qw(blessed);
use List::Util qw(uniq);

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

sub _refAttributes($thing) { \%referencing_attributes }    # for testing only

# Deduplicate white spaces and trim string.
sub _trimss { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z$//r }

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
which can further be used for document analisys as part of a bigger pipline.
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
    my $html_ref = $args->{html_ref} or panic "no html";
    ref $html_ref eq 'SCALAR'        or panic "Not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or panic "Not HTML";

    my $req = $args->{request_uri} or panic '"request_uri" is mandatory';
    my $uri = $self->{HI_request_uri} = blessed $req && $req->isa('URI') ? $req : URI->new($req)->canonical;

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );
    $self->{HI_doc} = $dom->documentElement;

    my $base = blessed $uri && $uri->isa('URI') ? $uri : URI->new($uri)->canonical;
    if(my $base_tag = $self->{HI_doc}->findvalue('//base[@href][position()=1]')) {
        $self->{HI_base} = $base = $base_tag->getAttribute('href');
    }
    else {
        $self->{HI_base} = $uri;
    }

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

Returns a HASH with all <meta> information of traditional content: each
value will only appear once.  OpenGraph meta-data records use attribute
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
    foreach my $meta ($self->doc->findnodes('//meta[not(@property)]')) {
        if(my $http = $meta->getAttribute('http-equiv')) {
            my $content = _trimss($meta->getAttribute('content')) // next;
            $meta{'http-equiv'}{lc $http} = $content;
        }
        elsif(my $name = $meta->getAttribute('name')) {
            my $content = _trimss($meta->getAttribute('content')) // next;
            $meta{name}{$name} = $content;
        }
        elsif(my $charset = $meta->getAttribute('charset')) {
            $meta{charset} = lc $charset;
        }
    }
    return $self->{HI_meta} = \%meta;
}

=head2 collectOpenGraph

    my $hash = $self->collectOpenGraph();

Collects all meta elements which have an attribute 'property'.  See website
about the structure which is returned. 

Example

    my $html = slurp("$Bin/data/open-graph-protocol-examples/article-offset.html");
    my $i    = HTML::Inspect->new(request_uri => 'http://examples.opengraphprotocol.us/article-offset.html', html_ref => \$html);
    my $og   = $i->collectOpenGraph();
    #{
    #    'article' => {
    #        'author'         => 'http://example.com/profile.html',
    #        'published_time' => '1972-06-17T20:23:45-05:00',
    #        'section'        => 'Front page',
    #        'tag'            => 'Watergate'
    #    },
    #    'og' => {
    #        'image' => {
    #            'height'     => '50',
    #            'secure_url' => 'https://d72cgtgi6hvvl.cloudfront.net/media/images/50.png',
    #            'type'       => 'image/png',
    #            'url'        => 'http://examples.opengraphprotocol.us/media/images/50.png',
    #            'width'      => '50'
    #        },
    #        'locale'    => 'en_US',
    #        'site_name' => 'Open Graph protocol examples',
    #        'title'     => '5 Held in Plot to Bug Office',
    #        'type'      => 'article',
    #        'url'       => 'http://examples.opengraphprotocol.us/article-offset.html'
    #    },
    #    'prefixes' => {'article' => 'http://ogp.me/ns/article#', 'og' => 'http://ogp.me/ns#'}
    #}

=cut

# TODO: Implement collection fo all tags specified in this page
# https://developers.facebook.com/docs/sharing/webmasters
# https://ogp.me/#types
# See also: https://developers.facebook.com/docs/sharing/webmasters/crawler
# https://developers.facebook.com/docs/sharing/webmasters/optimizing
sub collectOpenGraph ($self, %args) {
    return $self->{HI_og} if $self->{HI_og};
    my $og = {};
    # Find explicitly defined prefixes if we have such. A prefix may be an
    # object — article, video, etc...
    for my $tag ($self->doc->findnodes('//html[@prefix] | head[@prefix]')) {
        my %prefixes = split /:?\s+/, $tag->getAttribute('prefix');
        # merge prefixes
        keys %{$og->{prefixes}} ? ($og->{prefixes} = {%{$og->{prefixes}}, %prefixes}) : ($og->{prefixes} = \%prefixes);
    }

    $self->_handle_og_meta($og, $_) for $self->doc->findnodes('//meta[@property]');
    return $self->{HI_og} = $og;
}

# A not so dummy, implementation of collecting OG data from a page
sub _handle_og_meta ($self, $og, $meta) {
    my ($prefix, $type, $attr) = split /:/, lc $meta->getAttribute('property');
    my $content = _trimss $meta->getAttribute('content');
    my $ns      = ($og->{$prefix} //= {});
    if($prefix ne 'og') {
        $self->_handle_other_prefix($ns, $type, $content);
    }
    elsif(!defined $attr) {
        $self->_handle_no_attr($ns, $type, $content);
    }
    else {
        $self->_handle_attr($ns, $type, $attr, $content);
    }
    return;
}

# Handle cases like og:audio:author, where we have the namespace, type and
# attribute.
sub _handle_attr ($self, $ns, $type, $attr, $content) {

    if(!exists $ns->{$type} || ref $ns->{$type} eq 'HASH') {
        $ns->{$type}{$attr} = $content;
    }
    elsif(ref $ns->{$type} eq 'ARRAY') {
        $ns->{$type}[-1]{$attr} = $content;
    }
    elsif(!ref $ns->{$type}) {
        my $url = $ns->{$type};
        $ns->{$type}        = {};
        $ns->{$type}{url}   = $url;
        $ns->{$type}{$attr} = $content;
    }
    return;
}

# Handle cases like og:image or og:audio, where we have to introduce an 'url'
# atribute if we have other atributes of the same object later in the data.
sub _handle_no_attr ($self, $ns, $type, $content) {

    if(!exists $ns->{$type}) {
        $ns->{$type} = $content;
    }
    elsif(ref $ns->{$type} eq 'ARRAY') {
        push @{$ns->{$type}}, {url => $content};
    }
    else {
        my $first_content = $ns->{$type};
        $ns->{$type} = [ $first_content, {url => $content} ];
    }
    return;
}

# Handle cases like audio:author or image:width, where the object is in separate
# namespace, named after its type.
sub _handle_other_prefix ($self, $type, $attr, $content) {
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
        my @attr = uniq map URI->new_abs($_->getAttribute($attr), $base)->canonical, $self->doc->findnodes("//$tag\[\@$attr\]");
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
    foreach my $link ($self->doc->findnodes('//link[@rel]')) {
        my %attrs = map +(lc($_->name) => $_->value), grep $_->isa('XML::LibXML::Attr'), $link->attributes;
        $attrs{href_uri} = URI->new_abs($attrs{href}, $base)->canonical if $attrs{href};
        push @{$links{$attrs{rel}}}, \%attrs;
    }

    return $self->{HI_links} = \%links;
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

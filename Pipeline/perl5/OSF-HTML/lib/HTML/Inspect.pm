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
    base   => 'href',  # could be kept from the start, would add complexity
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',  # could use collectLinks(), but probably slower by complexity
    script => 'src',
);

sub _refAttributes($thing) { \%referencing_attributes } # for testing only

# Deduplicate white spaces and trim string.
sub _trimss { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z$//r }

=head1 Constructors

=head2 my $self = $class->new(%options)
Requires C<request_uri> and C<html_ref>
=cut

sub new {
    my $class = shift;
    return (bless {}, $class)->_init({@_});
}

sub _init ($self, $args) {
    my $html_ref = $args->{html_ref} or panic "no html";
    ref $html_ref eq 'SCALAR'        or panic "Not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or panic "Not HTML";

    my $req = $args->{request_uri}   or panic '"request_uri" is mandatory';
    my $uri = $self->{HI_request_uri} =
        blessed $req && $req->isa('URI') ? $req : URI->new($req)->canonical;

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );
    $self->{HI_doc}  = $dom->documentElement;

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

=head2 my $doc = $self->doc;
Returns instance of XML::LibXML::Element, representing the root node of the document and
everything in it.
=cut

sub doc { return $_[0]->{HI_doc} }

=head2 my $uri = $self->requestURI;
The M<URI> object which represents the C<request_uri> parameter which was passed as
default base for relative links to C<new()>.
=cut

sub requestURI { $_[0]->{HI_request_uri} }

=head2 my $uri = $self->base;
The base URI, which is used for relative links in the page.  This is the C<requestURI>
unless the HTML contains a C<< <base href> >> declaration.  The base URI is normalized.
=cut

sub base { $_[0]->{HI_base} }

#-------------------------
=head1 Collecting
=cut

=head2 my $hash = $html->collectMeta(%options);
Returns a HASH with all <meta> information of traditional content: each
value will only appear once.  OpenGraph meta-data records use attribute
'property', and are ignored here.

Example:
  { 'http-equiv' => { 'content-type' => 'text/plain' }
    charset => 'UTF-8',
    name => { author => , description => }
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

=head2 my $hash = $self->collectOpenGraph
Collects all meta elements which have an attribute 'property'.  See website
about the structure which is returned.
=cut

# TODO: Implement collection fo all tags specified in this page
# https://developers.facebook.com/docs/sharing/webmasters
# https://ogp.me/#types
# See also: https://developers.facebook.com/docs/sharing/webmasters/crawler
# https://developers.facebook.com/docs/sharing/webmasters/optimizing
sub collectOpenGraph ($self, %args) {
    return $self->{HI_og} if $self->{HI_og};

    my $og = {};
    $self->_handle_og_meta($og, $_) for $self->doc->findnodes('//meta[@property]');
    return $self->{HI_og} = $og;
}

# A not so dummy, implementation of collecting OG data from a page
sub _handle_og_meta ($self, $og, $meta) {
    my ($prefix, $type, $attr) = split /\:/, lc $meta->getAttribute('property');
    $attr //= 'content';
    my $content   = _trimss $meta->getAttribute('content');
    my $namespace = ($og->{$prefix} //= {});

    # Handle Types title,type,url
    if($type =~ /^(?:title|type|url)$/i) {
        $namespace->{$type} = $content;
        return;
    }

    # Handle objects, represented as array of possible alternative
    # properties or overrides. Here a new object starts.
    if(!exists $namespace->{$type}) {
        $namespace->{$type} = [ {$attr => $content} ];
        return;
    }

    # Continue adding properties to this object.
    my $arr = $namespace->{$type};
    if(!exists $arr->[-1]{$attr}) {
        $arr->[-1]{$attr} = $content;
    }

    # Alternates for this object
    else {
        push @$arr, {$attr => $content};
    }
    return;
}


=head2 $hash = $self->collectReferences;
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
        my @attr = uniq map URI->new_abs($_->getAttribute($attr), $base)->canonical,
               $self->doc->findnodes("//$tag\[\@$attr\]");
        $refs{"${tag}_$attr"} = \@attr if @attr;
    }

    return $self->{HI_refs} = \%refs;
}

=head2 $hash = $self->collectLinks;
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
        my %attrs = map +(lc($_->name) => $_->value),
            grep $_->isa('XML::LibXML::Attr'),
                $link->attributes;
        $attrs{href_uri} = URI->new_abs($attrs{href}, $base)->canonical
            if $attrs{href};
        push @{$links{$attrs{rel}}}, \%attrs;
    }

    return $self->{HI_links} = \%links;
}

1;

package HTML::Inspect;
use strict;
use warnings;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

# TODO: Make a Makefile.PL and describe the dependencise - prepare for CPAN
use XML::LibXML();
use URI;
use URI::WithBase();
use Log::Report 'html-inspect';

# A map: for which tag which attributes to be considered as links?
# We can add more tags and types of links later.
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

# Initialises an HTML::Inspect instance and returns it.
sub _init ($self, $args) {
    my $html_ref_re = qr!\<\s*/?\s*\w+!;
    my $html_ref    = $args->{html_ref} or panic "no html";
    ref $html_ref eq 'SCALAR'  or panic "Not SCALAR";
    $$html_ref =~ $html_ref_re or panic "Not HTML";
    $args->{request_uri}       or panic '"request_uri" is mandatory';

    # use a canonicalised version
    $self->{HI_request_uri} = URI->new($args->{request_uri})->canonical;

    # Translate all tags to lower-case, because libxml is case-
    # sensisitive, but HTML isn't.  This is not fail-safe.
    my $string = $$html_ref =~ s!($html_ref_re)!lc $1!gsre;
    my $dom    = XML::LibXML->load_html(
        string            => \$string,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );
    $self->{HI_doc} = $dom->documentElement;
    return $self;
}

sub new { _init((bless {}, shift), {@_}) }

# A read-only getter for the parsed document. Returns instance of
# XML::LibXML::Element, representing the root node of the document and
# everything in it.
sub doc { return $_[0]->{HI_doc} }

# attributes must be treated as if they are case-insensitive
sub _attributes ($self, $element) {
    return {map { +(lc($_->name) => $_->value) } grep { $_->isa('XML::LibXML::Attr') } $element->attributes};
}

sub _cleanup_content($string) {
    $string =~ s/\s+/ /g;            # reduce spaces
    $string =~ s/^\s(.*?)\s$/$1/;    # trim
    return $string;
}


# $html->collectMeta(%options)
# Returns a HASH with all <meta> information of traditional
# content: each value will only appear once.  Example:
#  { 'http-equiv' => { 'content-type' => 'text/plain' }
#    charset => 'UTF-8',
#    name => { author => , description => }
# OpenGraph meta-data records use attribute 'property', and are
# ignored here.

sub collectMeta ($self, %args) {
    return $self->{HI_meta} if $self->{HI_meta};
    my %meta;
    foreach my $meta ($self->doc->findnodes('//meta')) {
        my $attrs = $self->_attributes($meta);
        $attrs->{content} = _cleanup_content $attrs->{content};
        if(my $http = $attrs->{'http-equiv'}) {
            $meta{'http-equiv'}{lc $http} = $attrs->{content} if defined $attrs->{content};
        }
        elsif(my $name = $attrs->{name}) {
            $meta{name}{$name} = $attrs->{content} if defined $attrs->{content};
        }
        elsif(my $charset = $attrs->{charset}) {
            $meta{charset} = $charset;
        }
    }
    return $self->{HI_meta} = \%meta;
}

# Collects all meta elements which have an attribute 'property'
# TODO: Implement collection fo all tags specified in this page
# https://developers.facebook.com/docs/sharing/webmasters
# https://ogp.me/#types
# See also: https://developers.facebook.com/docs/sharing/webmasters/crawler
# https://developers.facebook.com/docs/sharing/webmasters/optimizing
sub collectOpenGraph ($self, %args) {
    return $self->{HI_og} if $self->{HI_og};
    $self->{HI_og} = {};
    foreach my $meta ($self->doc->findnodes('//meta[@property]')) {
        $self->_handle_og_meta($meta);
    }

    return $self->{HI_og};
}

# A dummy, initial implementation of collecting OG data from a page
sub _handle_og_meta ($self, $meta) {
    my $attrs = $self->_attributes($meta);
    my ($ns, $type, $attr) = split /:/, lc $attrs->{property};
    $attr //= 'content';
    $attrs->{content} = _cleanup_content $attrs->{content};

    my $namespace = ($self->{HI_og}{$ns} //= {});

    # Handle Types title,type,url
    if($type =~ /^(?:title|type|url)$/i) {
        $namespace->{$type} = $attrs->{content};
        return;
    }

    # Handle objects, represented as array of possible alternative properties
    # or overrides.
    # A new object starts.
    if(!exists $namespace->{$type}) {
        $namespace->{$type} = [{$attr => $attrs->{content}}];
        return;
    }

    # Continue adding properties to this object.
    my $arr = $namespace->{$type};
    if(!exists $arr->[-1]{$attr}) {
        $arr->[-1]{$attr} = $attrs->{content};
    }

    # Alternates for this object
    else {
        push @$arr, {$attr => $attrs->{content}};
    }
    return;
}


# Collects all links from document. Returns a hash with keys like $tag_$attr
# and values an array of links found in such tags and attributes.
sub collectLinks ($self) {
    my $links = $self->{HI_links};
    return $links if $links;
    my $base = $self->{HI_request_uri} =~ s|/[^/]+$|/|r;
    if(my ($_base) = $self->doc->findnodes('//base[@href]')) {
        my $href = $self->_attributes($_base)->{href};
        $base = $href if $href;
    }

    while (my ($tag, $attr) = each %attributesWithLinks) {
        foreach my $link ($self->doc->findnodes("//$tag\[\@$attr\]")) {

            # https://en.wikipedia.org/wiki/URI_normalization maybe some day
            push @{$links->{"${tag}_$attr"}}, URI->new_abs($self->_attributes($link)->{$attr}, $base);
        }
    }
    return $self->{HI_links} = $links;
}

1;

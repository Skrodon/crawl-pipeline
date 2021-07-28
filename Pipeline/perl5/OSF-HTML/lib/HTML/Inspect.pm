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
my %attributesWithLinks = (
    a      => 'href',
    area   => 'href',
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',
    script => 'src',
    # base is taken separately in _init(), but we want it normalized too
    base => 'href',
    # more ?..
);

# Tag => attribute pairs, considered to contain links. Readonly.
sub linkAttributes {
    return %attributesWithLinks;
}
# Initialises an HTML::Inspect instance and returns it.
sub _init ($self, $args) {
    my $html_ref = $args->{html_ref} or panic "no html";
    ref $html_ref eq 'SCALAR'        or panic "Not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or panic "Not HTML";
    $args->{request_uri}             or panic '"request_uri" is mandatory';

    # make sure we have a canonicalised URL.
    $self->{HI_request_uri} = ((blessed($args->{request_uri}) // '') eq 'URI' && $args->{request_uri}->canonical)
      || URI->new($args->{request_uri})->canonical;

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );
    $self->{HI_doc}  = $dom->documentElement;
    $self->{HI_base} = $self->{HI_request_uri} =~ s|/[^/]+$|/|r;
    if(my $base_tag = $self->{HI_doc}->findvalue('//base[@href][position()=1]')) {
        my $href = $base_tag->getAttribute('href');
        $self->{HI_base} = $href if $href;
    }

    return $self;
}

sub new {
    my $class = shift;
    return (bless {}, $class)->_init({@_});
}

# A read-only getter for the parsed document. Returns instance of
# XML::LibXML::Element, representing the root node of the document and
# everything in it.
sub doc { return $_[0]->{HI_doc} }

# Deduplicate white spaces and trim string.
sub _trimss {
    return ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z$//r;
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
    foreach my $meta ($self->doc->findnodes('//meta[not(@property)]')) {
        my $content = _trimss $meta->getAttribute('content');
        if(my $http = $meta->getAttribute('http-equiv')) {
            $meta{'http-equiv'}{lc $http} = $content if defined $content;
        }
        elsif(my $name = $meta->getAttribute('name')) {
            $meta{name}{$name} = $content if defined $content;
        }
        elsif(my $charset = $meta->getAttribute('charset')) {
            $meta{charset} = lc $charset;
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
    my $og = {};
    # Find explicitly defined prefixes if we have such. A prefix may be an
    # object — article, video, etc...
    $og->{prefixes} = {};
    for my $tag ($self->doc->findnodes('//html[@prefix] | head[@prefix]')) {
        my %prefixes = split /:?\s+/, $tag->getAttribute('prefix');
        # merge prefixes
        keys %{$og->{prefixes}} ? ($og->{prefixes} = {%{$og->{prefixes}}, %prefixes}) : ($og->{prefixes} = \%prefixes);
    }
    if(!exists $og->{prefixes}{og}) {
        $og->{prefixes}{og} = 'http://ogp.me/ns#';
    }

    $self->_handle_og_meta($og, $_) for ($self->doc->findnodes('//meta[@property]'));

    return $self->{HI_og} = $og;
}

# A not so dummy, implementation of collecting OG data from a page
sub _handle_og_meta ($self, $og, $meta) {
    my ($prefix, $type_or_attr, $attr) = split /:/, lc $meta->getAttribute('property');
    my $content = _trimss $meta->getAttribute('content');
    my $ns      = ($og->{$prefix} //= {});
    if(!defined $attr) {
        if(!exists $ns->{$type_or_attr}) {
            $ns->{$type_or_attr} = $content;
        }
        elsif(ref $ns->{$type_or_attr} eq 'ARRAY') {
            push @{$ns->{$type_or_attr}}, {url => $content};
        }
        else {
            my $first_content = $ns->{$type_or_attr};
            $ns->{$type_or_attr} = [ $first_content, {url => $content} ];
        }
    }
    else {
        if(!exists $ns->{$type_or_attr}) {
            $ns->{$type_or_attr}{$attr} = $content;
        }
        elsif(ref $ns->{$type_or_attr} eq 'HASH') {
            $ns->{$type_or_attr}{$attr} = $content;
        }
        elsif(ref $ns->{$type_or_attr} eq 'ARRAY') {
            $ns->{$type_or_attr}[-1]{$attr} = $content;
        }
        elsif(!ref $ns->{$type_or_attr}) {
            my $url = $ns->{$type_or_attr};
            $ns->{$type_or_attr}        = {};
            $ns->{$type_or_attr}{url}   = $url;
            $ns->{$type_or_attr}{$attr} = $content;
        }
    }
    return;
}


# Collects all links from document. Returns a hash referense with keys like $tag_$attr
# and values an array of unique links found in such tags and attributes. The links are
# in their natural order in the document.
sub collectLinks ($self) {
    return $self->{HI_links} if $self->{HI_links};
    my %links;
    my $base = $self->{HI_base};

    while (my ($tag, $attr) = each %attributesWithLinks) {
        my @seen_in_order;
        foreach my $link ($self->doc->findnodes("//$tag\[\@$attr\]")) {
            # https://en.wikipedia.org/wiki/URI_normalization maybe some day
            push @seen_in_order, URI->new_abs($link->getAttribute($attr), $base);
        }
        @{$links{"${tag}_$attr"}} = uniq @seen_in_order;
    }
    return $self->{HI_links} = \%links;
}


1;

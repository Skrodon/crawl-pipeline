package HTML::Inspect;
use strict;
use warnings;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

# TODO: Make a Makefile.PL and describe the dependencise - prepare for CPAN
use Carp;                                    # TODO: Change to Log::Report
use XML::LibXML();
use URI();


# Initialises an HTML::Inspect instance and returns it.
sub _init(%) {
    my ($self, $args) = @_;
    my $html_ref_re = qr!\<\s*/?\s*\w+!;
    {
        local $Carp::CarpLevel = 2;
        croak('Expected parameter "html_ref" is not present.' . ' Please provide reference to a HTML string!')
          if (!($args && $args->{html_ref}));
        croak('Argument "html_ref" is not a reference to a HTML string.')
          unless (ref $args->{html_ref} eq 'SCALAR' && (${$args->{html_ref}} || '') =~ /$html_ref_re/);
        croak('Argument "request_uri" is mandatory. PLease provide an URI as a string.') unless ($args->{request_uri});

    }

    # use a normalized version
    $self->{request_uri} = URI->new($args->{request_uri})->canonical;

    # Translate all tags to lower-case, because libxml is case-
    # sensisitive, but HTML isn't.  This is not fail-safe.
    my $string = ${$args->{html_ref}} =~ s!($html_ref_re)!lc $1!gsre;

    my $dom = XML::LibXML->load_html(
                                     string            => \$string,
                                     recover           => 2,
                                     suppress_errors   => 1,
                                     suppress_warnings => 1,
                                     no_network        => 1,
                                     no_xinclude_nodes => 1,
                                    );

    $self->{OHI_doc} = $dom->documentElement;
    return $self;
}

sub new { _init((bless {}, shift), {@_}) }

# A read-only getter for the parsed document. Returns instance of
# XML::LibXML::Element, representing the root node of the document and
# everything in it.
sub doc { $_[0]->{OHI_doc} }

# attributes must be treated as if they are case-insensitive
sub _attributes {
    my ($self, $element) = @_;
    my %attrs = map +(lc($_->name) => $_->value), grep $_->isa('XML::LibXML::Attr'),    # not namespace decls
      $element->attributes;
    return \%attrs;
}


### $html->collectMeta(%options)
# Returns a HASH with all <meta> information of traditional
# content: each value will only appear once.  Example:
#  { 'http-equiv' => { 'content-type' => 'text/plain' }
#    charset => 'UTF-8',
#    name => { author => , description => }
# OpenGraph meta-data records use attribute 'property', and are
# ignored here.

sub collectMeta {
    my ($self, %args) = @_;
    return $self->{OHI_meta} if $self->{OHI_meta};
    my %meta;
    foreach my $meta ($self->doc->getElementsByTagName('meta')) {
        my $attrs = $self->_attributes($meta);
        if (my $http = $attrs->{'http-equiv'}) {
            $meta{'http-equiv'}{lc $http} = $attrs->{content} if defined $attrs->{content};
        }
        elsif (my $name = $attrs->{name}) {
            $meta{name}{$name} = $attrs->{content} if defined $attrs->{content};
        }
        elsif (my $charset = $attrs->{charset}) {
            $meta{charset} = $charset;
        }
    }
    return $self->{OHI_meta} = \%meta;
}

# Collects all meta elements which have an attribute 'property'
# TODO: Implement collection fo all tags specified in this page
# https://developers.facebook.com/docs/sharing/webmasters
# https://ogp.me/#types
# See also: https://developers.facebook.com/docs/sharing/webmasters/crawler
# https://developers.facebook.com/docs/sharing/webmasters/optimizing
sub collectOpenGraph {
    my ($self, %args) = @_;
    return $self->{OHI_og} if $self->{OHI_og};
    $self->{OHI_og} = {};
    for my $meta ($self->doc->findnodes('//meta[@property]')) {
        $self->_handle_og_meta($meta);
    }

    return $self->{OHI_og};
}

# A dummy, initial implementation of collecting OG data from a page
sub _handle_og_meta {
    my ($self, $meta) = @_;
    my ($ns, $type, $attr) = split m':', $meta->getAttribute('property');

    # Handle Types title,type,url
    if ($type =~ /title|type|url/) {
        $self->{OHI_og}{$ns}{$type} = $meta->getAttribute('content');
        return;
    }

    # Handle Arrays
    # a new object starts
    if (!exists $self->{OHI_og}{$ns}{$type}) {
        $self->{OHI_og}{$ns}{$type} = [{($attr ? $attr : 'content') => $meta->getAttribute('content')}];
    }

    # continue adding properties to this object
    elsif ($attr && !exists $self->{OHI_og}{$ns}{$type}[-1]{$attr}) {
        $self->{OHI_og}{$ns}{$type}[-1]{$attr} = $meta->getAttribute('content');
    }

    #alternates
    else {
        push @{$self->{OHI_og}{$ns}{$type}}, {($attr ? $attr : 'content') => $meta->getAttribute('content')};
    }
    return;
}

sub tag2attr {

    state $tag2attr = {
                       a      => 'href',
                       area   => 'href',
                       embed  => 'src',
                       form   => 'action',
                       iframe => 'src',
                       img    => 'src',
                       link   => 'href',
                       script => 'src',
                      };
}

# Collects all links from document. Returns a hash with keys like $tag_$attr
# and values an array of links with that tag and attribute.
# TODO: guess the <base> of the document.
sub collectLinks ($self) {
    return $self->{OHI_links} if $self->{OHI_links};

    # A map: for which tag which attributes to be considered as links?
    # We can add more tags and types of links later.

    while (my ($tag, $attr) = each %{$self->tag2attr}) {
        for my $link ($self->doc->findnodes("//$tag\[\@$attr\]")) {
            $self->_handle_link($tag, $attr, $link);
        }
    }
    return $self->{OHI_links};
}

# https://en.wikipedia.org/wiki/URI_normalization
# Returns a normalized link as string
my sub _normalize ($self, $link, $a) {
    my $req_uri = $self->{request_uri};
    my $attr    = $link->getAttribute($a);
    my $url     = URI->new($attr);

    # Relative urls get the scheme of the request_uri
    if (!$url->scheme && $req_uri->has_recognized_scheme) {
        $url->scheme($req_uri->scheme);
        if ($url->scheme =~ /^http/) {
            $url->host($req_uri->host);
            return $url->canonical->as_string;
        }

        #TODO: How about all other type of schemes?
    }
    return $attr;
}

sub _handle_link ($self, $t, $a, $link) {
    my $links = $self->{OHI_links}{"${t}_$a"} //= [];
    push @$links, _normalize($self, $link, $a);
    return;
}


1;

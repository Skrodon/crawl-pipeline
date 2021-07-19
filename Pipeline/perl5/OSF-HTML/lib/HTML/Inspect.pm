package HTML::Inspect;
use strict;
use warnings;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

# TODO: Make a Makefile.PL and describe the dependencise - prepare for CPAN
use XML::LibXML();
use URI();
use Log::Report 'html-inspect';

# Initialises an HTML::Inspect instance and returns it.
sub _init ($self, $args = {}) {
### $args is not optional
    my $html_ref_re = qr!\<\s*/?\s*\w+!;
    my $html_ref    = $args->{html_ref} or panic "no html";
    ref $html_ref eq 'SCALAR'  or error "Not SCALAR";
### Use 'panic' for internal software errors: it gives a stack-trace
### like confess which is useful for debugging.
    $$html_ref =~ $html_ref_re or error "Not HTML";
    $args->{request_uri} || error '"request_uri" is mandatory';
### To be consistent with the line before it, I would use 'or'

    # use a normalized version
    $self->{request_uri} = URI->new($args->{request_uri})->canonical;
### The 'request_uri' is a good name for the parameter, but not for
### the base in new_abs(), because that is influenced by other parameters
### like <base>.

    # Translate all tags to lower-case, because libxml is case-
    # sensisitive, but HTML isn't.  This is not fail-safe.
    my $string = $$html_ref =~ s!($html_ref_re)!lc $1!gsre;

    my $dom = XML::LibXML->load_html(
                                     string            => \$string,
                                     recover           => 2,
                                     suppress_errors   => 1,
                                     suppress_warnings => 1,
                                     no_network        => 1,
                                     no_xinclude_nodes => 1,
                                    );
### This is really ugly formatting.  Can we just indent this with 4, like
### we do with code>

    $self->{OHI_doc} = $dom->documentElement;
### As you can see, I use OHI_ before the object attributes.  This keeps
### poeple from "accidentally" do "$inspect->{request_uri}" where the
### intention was to write "inspect->requestURI".
### OHI_ is the abbreviation of OSF::HTML::Inspect.  Now the module name
### changed, it should become HI_
### This also protects a bit against accidental name collisions in the
### inheritance structure.  In Data::Dumper, you can now easily see
### which inheritance level maintains the parameter.
### So: maybe $self->{request_uri} --> $self->{HI_request_uri}
    return $self;
}

sub new { _init((bless {}, shift), {@_}) }

# A read-only getter for the parsed document. Returns instance of
# XML::LibXML::Element, representing the root node of the document and
# everything in it.
sub doc { return $_[0]->{OHI_doc} }

# attributes must be treated as if they are case-insensitive
sub _attributes ($self, $element) {
    my %attrs = map { +(lc($_->name) => $_->value) } grep { $_->isa('XML::LibXML::Attr') }    # not namespace decls
      $element->attributes;

### I do not used {} when map and grep are very simple actions.  But you do
### NOT NEED to follow me:
### my %attrs = map +(lc($_->name) => $_->value),
###      grep $_->isa('XML::LibXML::Attr'),   # not namespace decls
###          $element->attributes;

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

sub collectMeta ($self, %args) {
    return $self->{OHI_meta} if $self->{OHI_meta};
    my %meta;
    foreach my $meta ($self->doc->findnodes('//meta')) {
        my $attrs = $self->_attributes($meta);
        if (my $http = $attrs->{'http-equiv'}) {
### I do not like the blank between "if" and "(": I feel the "(" is part
### of the if keyword: it is not a separate expression.  But it's your
### choice.
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
sub collectOpenGraph ($self, %args) {
    return $self->{OHI_og} if $self->{OHI_og};
    $self->{OHI_og} = {};
    for my $meta ($self->doc->findnodes('//meta[@property]')) {
### Please use foreach() here.
### Is findnodes really faster than what I used?
        $self->_handle_og_meta($meta);
    }

    return $self->{OHI_og};
}

# A dummy, initial implementation of collecting OG data from a page
sub _handle_og_meta ($self, $meta) {
    my $attrs = $self->_attributes($meta);
    my ($ns, $type, $attr) = split /:/, lc $attrs->{property};
    $attr //= 'content';

    # Handle Types title,type,url
    if ($type =~ /^(?:title|type|url)$/i) {
        $self->{OHI_og}{$ns}{$type} = $attrs->{content} =~ s/\s+/ /gr;
### We use $self->{OHI_og}{$ns} everywhere, so assign it to a my()
        return;
    }

    # Handle objects, represented as arry of alternatives.
    # A new object starts.
    if (! exists $self->{OHI_og}{$ns}{$type}) {
        $self->{OHI_og}{$ns}{$type} = [{$attr => $attrs->{content}}];
### No cleanout of content?
        return;
    }

    # Continue adding properties to this object.
    my $arr = $self->{OHI_og}{$ns}{$type};
    if (!exists $arr->[-1]{$attr}) {
        $arr->[-1]{$attr} = $attrs->{content};
    }

    # Alternates for this object
    else {
        push @$arr, {$attr => $attrs->{content}};
    }
    return;
}

# A map: for which tag which attributes to be considered as links?
# We can add more tags and types of links later.
# We can also add/change this map per instance.
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

        # more ?..
                      };
### I prefer "configurables" in the top of the file.
### tag2attr is not clear enough: attrContainsLink?
### Public method?

    return $_[1] && ref $_[1] eq 'HASH' ? $_[0]->{tag2attr} = $_[1] : $tag2attr;
### No setter please.
}

# Collects all links from document. Returns a hash with keys like $tag_$attr
# and values an array of links found in such tags and attributes.
# TODO: guess the <base> of the document.
sub collectLinks ($self) {
    return $self->{OHI_links} if $self->{OHI_links};
    while (my ($tag, $attr) = each %{$self->tag2attr}) {
        for my $link ($self->doc->findnodes("//$tag\[\@$attr\]")) {
### foreach
### attributes must be handled case-insensitive: use _attributes()

            # https://en.wikipedia.org/wiki/URI_normalization maybe some day
            push @{$self->{OHI_links}{"${tag}_$attr"} //= []},
###  //= []  is not needed: autovifivication
### $self->{OHI_links} is used a lot, assign it a my() before while()
              URI->new_abs($self->_attributes($link)->{$attr}, $self->{request_uri});
### You use $self->{request_uri} for any link, and there are always many
### links.  Before while() use $self->base to the URI.
        }
    }
    return $self->{OHI_links};
}


1;

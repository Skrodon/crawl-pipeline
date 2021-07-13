package HTML::Inspect;

use warnings;
use strict;
use Carp;

use XML::LibXML ();

sub new(%) { my $class = shift; (bless {}, $class)->_init({@_}) }

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
    }

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

# A read-only getter for the parsed document. Returns instance of
# XML::LibXML::Element, representing the root node of the document and
# everything in it.
sub doc() { $_[0]->{OHI_doc} }

# attributes must be treated as if they are case-insensitive
sub _attributes($) {
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

sub collectMeta(%) {
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
sub collectOpenGraph(%) {
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

1;


package OSF::HTML::Inspect;

use warnings;
use strict;

use XML::LibXML   ();

sub new(%) { my $class = shift; (bless {}, $class)->init({@_}) }

sub init(%)
{   my ($self, $args) = @_;

    # Translate all tags to lower-case, because libxml is case-
    # sensisitive, but HTML isn't.  This is not fail-safe.
    my $string = ${$args->{html_ref}} =~ s!(\<\s*/?\s*\w+)!lc $1!gsre;

    my $dom = XML::LibXML->load_html(
       string            => \$string,
       recover           => 2,
       suppress_errors   => 1,
       suppress_warnings => 1,
       no_network        => 1,
       no_xinclude_nodes => 1,
    );

    $self->{OHI_doc} = $dom->documentElement;
    $self;
}

sub doc() { $_[0]->{OHI_doc} }

# attributes must be treated are case-insensitive
sub _attributes($)
{   my ($self, $element) = @_;
    my %attrs = map +(lc($_->name) => $_->value),
        grep $_->isa('XML::LibXML::Attr'),  # not namespace decls
            $element->attributes;
    \%attrs;
}


### $html->collectMeta(%options)
# Returns a HASH with all <meta> information of traditional
# content: each value will only appear once.  Example:
#  { 'http-equiv' => { 'content-type' => 'text/plain' }
#    charset => 'UTF-8',
#    name => { author => , description => }
# OpenGraph meta-data records use attribute 'property', and are
# ignored here.

sub collectMeta(%)
{   my ($self, %args) = @_;
    return $self->{OHI_meta} if $self->{OHI_meta};

    my %meta;
    foreach my $meta ($self->doc->getElementsByTagName('meta'))
    {   my $attrs = $self->_attributes($meta);
        if(my $http = $attrs->{'http-equiv'})
        {   my $content = $attrs->{content};
            $meta{'http-equiv'}{$http} = $content if defined $content;
        }
        elsif(my $name = $attrs->{name})
        {   my $content = $attrs->{content};
            $meta{name}{$name} = $content if defined $content;
        }
        elsif(my $charset = $attrs->{charset})
        {   $meta{charset} = $charset;
        }
    }

use Data::Dumper;
warn Dumper \%meta;
    $self->{OHI_meta} = \%meta;
}

1;

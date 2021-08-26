package HTML::Inspect::Util;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw(trim_attr xpc_find get_attributes absolute_url);

use Log::Report 'html-inspect';

use URI::Fast qw(html_url);

# Deduplicate white spaces and trim string.
sub trim_attr($) { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z//r }

# function xpc_find($pattern)
# Precompiled xpath expressions to be reused by instances of this class.
# Not much more faster than literal string passing but still faster.
# See xt/benchmark_collectOpenGraph.pl

# state $find = xpc_find 'pattern';
# my @nodes = $find->($self);     # or even: $self->$find

sub xpc_find($)
{   my $pattern = shift;
    my $compiled = XML::LibXML::XPathExpression->new($pattern);
    sub { $_[0]->_xpc->findnodes($compiled) };  # Call with $self as param
}

# function get_attributes($doc_element)
# Returns a HASH of all attributes found for an HTML element, which is an
# XML::LibXML::Element.

sub get_attributes($) {
   +{ map +($_->name => trim_attr($_->value)),
#        grep $_->isa('XML::LibXML::Attr'),  XXX only on <html> in xhtml
            $_[0]->attributes
    };
}

# function absolute_url($relative_url, $base)
# Convert a (possible relatative) url into an absolute version.  Things
# which are not urls (data: and javascript:) will return nothing.

sub absolute_url($$) {
    my $href = $_[0] || 'x';  #XXX avoid crash in URI::Fast 0.52
    my $ref  = html_url($href, $_[1])->as_string;
    $ref =~ m/^(?:data\:|javascript\:)/ ? () : $ref;
}

1;

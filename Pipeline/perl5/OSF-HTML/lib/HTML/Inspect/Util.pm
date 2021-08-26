package HTML::Inspect::Util;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw(trim_attr xpc_find get_attributes);

use Log::Report 'html-inspect';

# Deduplicate white spaces and trim string.
sub trim_attr($) { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z//r }

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

1;

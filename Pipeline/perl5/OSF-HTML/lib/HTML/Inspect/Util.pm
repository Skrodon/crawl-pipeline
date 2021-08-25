package HTML::Inspect::Util;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw(trim_attr xpc_find);

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
    sub { $_[0]->xpc->findnodes($compiled) };  # Call with $self as param
}

1;

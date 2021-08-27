package HTML::Inspect::Util;
use parent 'Exporter';

use strict;
use warnings;

our @EXPORT_OK = qw(trim_attr xpc_find get_attributes absolute_url);

use Log::Report 'html-inspect';

use URI::Fast qw(html_url);
use URI       ();

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
# which are not urls will return nothing.

# See https://github.com/Skrodon/temporary-documentation/wiki/HTML-link-statics
# to see what we try to clean-up here.

my %take_schemes = map +($_ => 1), qw/mailto http https ftp tel/;

sub absolute_url($$) {
    my ($href, $base) = @_;

    my $scheme = $href =~ /^([a-z]+)\:/i ? lc($1) : 'https';  # base always http*
    $take_schemes{$scheme} or return ();

    return URI->new_abs($href, $base)->canonical->as_string
        unless $scheme eq 'https' || $scheme eq 'http';  # about 2.2% of the input

    ### For http*, URI::Fast::html_url is mainly better than URI.  And much, much
    #   faster.  Even when some things need to be fixed later.


    # URI::Fast does not remove empty fragments and queries
#   my $url = html_url($href =~ s/\#\z//r =~ s/\?\z//r, $base);

#XXX avoid crash in URI::Fast 0.52
$href =~ s/\#\z//;
$href =~ s/\?\z//;
$href ||= 'x';
my $url = html_url($href, $base);

    if(my $port = $url->port) {
        $port =~ m/^[0-9]{1,8}$/ or return ();  # not validated by URI::Fast
        $url->port(undef)                       # not normalized by URI::Fast
            if $port == ($scheme eq 'http' ? 80 : 432);
    }

    #TODO: IDN on host
    #TODO: utf8->hex on path.  See xt/benchmark_utf8.t

    $url->as_string;
}

1;

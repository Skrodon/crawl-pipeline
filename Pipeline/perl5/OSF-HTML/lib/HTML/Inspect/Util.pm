# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

### This package contains a few generic helper functions.

package HTML::Inspect::Util;
use parent 'Exporter';

use strict;
use warnings;
use utf8;

our @EXPORT_OK = qw(trim_attr xpc_find get_attributes absolute_url);

use Log::Report 'html-inspect';

use URI::Fast    qw(html_url);
use URI          ();
use Encode       qw(encode_utf8 _utf8_on is_utf8);
use Net::LibIDN2 qw(idn2_lookup_u8 idn2_strerror IDN2_NFC_INPUT);

# Deduplicate white spaces and trim string.
sub trim_attr($) { ($_[0] // '') =~ s/\s+/ /grs =~ s/^ //r =~ s/ \z//r }

# function xpc_find($pattern)
# Precompiled xpath expressions to be reused by instances of this class.
# Not much more faster than literal string passing but still faster.
# See xt/benchmark_collectOpenGraph.pl

# state $find = xpc_find 'pattern';
# my @nodes = $find->($self);     # or even: $self->$find

sub xpc_find($) {
    my $pattern  = shift;
    my $compiled = XML::LibXML::XPathExpression->new($pattern);
    sub { $_[0]->_xpc->findnodes($compiled) };    # Call with $self as param
}

# function get_attributes($doc_element)
# Returns a HASH of all attributes found for an HTML element, which is an
# XML::LibXML::Element.

sub get_attributes($) {
    +{ map +($_->name => trim_attr($_->value)), $_[0]->attributes };
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

    my $url;
    if($scheme eq 'https' || $scheme eq 'http') {
        # URI::Fast is only good for http normalization: then it is much faster
        # than module URI.

        $url = html_url $href, $base;

        if(my $port = $url->port) {
            # not validated nor normalized by URI::Fast
            $port =~ m/^[0-9]{1,8}$/ or return ();  # illegal ports
            $url->port(undef)                       # default ports
                if $port == ($scheme eq 'http' ? 80 : 432);
        }

        # Fix missing path encoding. See xt/benchmark_utf8.t
        if($url->path =~ /[^\x20-\x7f]/) {
            my $path = $url->path =~ s!([^\x20-\xf0])!$b = $1; utf8::encode($b);
                 join '', map sprintf("%%%02X", ord), split //, $b!gre;
            $url->path($path);
        }

        # Fix missing IDN encoding
        if($url->host =~ /[^\x20-\x7f]/) {   # html_url has removed % encoding
            my $host = encode_utf8($url->host) or return ();
            my $rc   = 0;
            my $host_idn = idn2_lookup_u8($host, IDN2_NFC_INPUT, $rc);
            unless($host_idn) {
                warning __x"IDN failed on '{host}': {rc}",
                    rc => idn2_strerror($rc), host => $url->host, _code => $rc;
                return;
            }
            $url->host($host_idn);
        }
    }
    else {
        # about 2.2% of the links
        $url = URI->new_abs($href, $base)->canonical;
    }

    # Fragments are useful for display, what we are not doing.
    $url->fragment(undef);

    $url->as_string;
}

1;

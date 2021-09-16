# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

package HTML::Inspect;

use strict;
use warnings;
use utf8;

no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

our $VERSION = 0.11;

use Log::Report 'html-inspect';

use HTML::Inspect::Util       qw(trim_attr xpc_find get_attributes absolute_url);
use HTML::Inspect::Normalize  qw(set_page_base);

use HTML::Inspect::OpenGraph  ();    # mixin for collectOpenGraph()
use HTML::Inspect::References ();    # mixin for collectRef*()
use HTML::Inspect::Meta       ();    # mixin for collectMeta*()

use XML::LibXML ();
use Scalar::Util qw(blessed);
use URI ();

=encoding utf-8

=head1 NAME

HTML::Inspect - Inspect a HTML document

=head1 SYNOPSIS

    my $source    = 'http://example.com/doc';
    my $inspector = HTML::Inspect->new(location => $source, html_ref => \$html);
    my $classic   = $inspector->collectMetaClassic;

=head1 DESCRIPTION

This module extracts information from HTML, using a clean parser (L<XML::LibXML>)
Returned structures may need further processing.  Please suggest additional
extractors.

=head1 Constructors

=head2 new

    my $self = $class->new(%options);

The required C<html_ref> is a reference to a (possibly troublesome) HTML string.
Passed as reference to avoid copying large strings.

The required C<location> option is an absolute url as a string or L<URI>
instance, which explains where the HTML was found.  It is used as base
of relative URLs found in the HTML, unless it contains as C<< <base> >>
element.

=cut

sub new {
    my $class = shift;
    (bless {}, $class)->_init( {@_} );
}

sub _init($self, $args) {
    my $html_ref = $args->{html_ref} or panic "html_ref is required";
    ref $html_ref eq 'SCALAR'        or panic "html_ref not SCALAR";
    $$html_ref =~ m!\<\s*/?\s*\w+!   or error "Not HTML: '" . substr($$html_ref, 0, 20) . "'";

    my $req = $args->{location}      or panic '"location" is mandatory';
    my $loc = $self->{HI_location} = blessed $req ? $req : URI->new($req);

    my $dom = XML::LibXML->load_html(
        string            => $html_ref,
        recover           => 2,
        suppress_errors   => 1,
        suppress_warnings => 1,
        no_network        => 1,
        no_xinclude_nodes => 1,
    );

    my $doc = $self->{HI_doc} = $dom->documentElement;
    $self->{HI_xpc} = XML::LibXML::XPathContext->new($doc);

    ### Establish the base for relative links.

    my ($base, $rc, $err);
    state $find_base_href = xpc_find '//base[@href][1]';
    if(my ($base_elem) = $find_base_href->($self)) {
        ($base, $rc, $err) = set_page_base $base_elem->getAttribute('href');
        unless($base) {
            warning __x"Illegal base href '{href}' in {url}: {err}",
                href => $base_elem->getAttribute('href'), url => $loc, err => $err;
        }
    }
    else {
        my ($base, $rc, $err) = set_page_base $loc->as_string;
        unless($base) {
            warning __x"Illegal page location '{url}': {err}", url => $loc, err => $err;
            return ();
        }
    }
    $self->{HI_base} = URI->new($base);   # base needed for other protocols (ftp)

    $self;
}

#-------------------------

=head1 Accessors

=head2 location

    my $uri = $self->location;

Readonly.  The L<URI> object which represents the C<location> parameter
which was passed as default base for relative links to C<new()>.

=cut

sub location { $_[0]->{HI_location} }

=head2 base

    my $uri = $self->base;

Readonly.  The base URI, which is used for relative links in the page.
This is the C<location>, unless the HTML contains a C<< <base href>
>> declaration.  The base URI is a string representation, in absolute
and normalized form.

=cut

sub base { $_[0]->{HI_base} }

# The root XML::LibXML::Element of the current document.
sub _doc { $_[0]->{HI_doc} }

# Returns the XPathContext for the current document.  Used via ::Util::xpc_find
sub _xpc { $_[0]->{HI_xpc} }

#-------------------------

=head1 Collecting

=head2 collectLinks 

    $hash = $self->collectLinks;

Collect all C<< <link> >> relations from the document.  The returned HASH
contains the relation (the C<rel> attribute, required) to an ARRAY of
link elements with that value.  The ARRAY elements are HASHes of all
attributes of the link and and all lower-cased.  The added C<href_uri>
key will be a normalized, absolute translation of the C<href> attribute.
=cut

#XXX Feeling lonely in this file.

sub collectLinks($self) {
    return $self->{HI_links} if $self->{HI_links};
    my $base = $self->base;

    state $find_link_rel = xpc_find '//link[@rel]';

    my %links;
    foreach my $link ($find_link_rel->($self)) {
        my $attrs = get_attributes $link;
        $attrs->{href} = absolute_url($attrs->{href}, $base)
            if exists $attrs->{href};

        push @{$links{delete $attrs->{rel}}}, $attrs;
    }

    $self->{HI_links} = \%links;
}

=head2 collectMetaClassic 

    my $hash = $html->collectMetaClassic(%options);

Returns a HASH reference with all C<< <meta> >> information of traditional content:
the single C<charset> and all C<http-equiv> records, plus the subset of names which
are listed on F<https://www.w3schools.com/tags/tag_meta.asp>.  People defined far too
many names to be useful for everyone.

Example:

    {  'http-equiv' => { 'content-type' => 'text/plain' },
        charset => 'UTF-8',
        name => { author => 'John Smith' , description => 'The John Smith\'s page.'},
    }

=head2 collectMetaNames

   my $hash = $html->collectMetaNames(%options);

Returns a HASH with all C<< <meta> >> records which have both a C<name> and a
C<content> attribute.  These are used as key-value pairs for many, many different
purposes.

Example:

   { author => 'John Smith' , description => 'The John Smith\'s page.'}

=head2 collectMeta

   my $array = $html->collectMeta(%options);

Returns an ARRAY of B<all> kinds of C<< <meta> >> records, which have a wide
variety of fields and may be order dependend!!!

Example:

   [ { http-equiv => 'Content-Type', content => 'text/html; charset=UTF-8' },
     { name => 'viewport', content => 'width=device-width, initial-scale=1.0' },
   ]

=cut

# All collectMeta* in ::Meta.pm mixin

=head2 collectReferencesFor

    $array = $self->collectReferencesFor($tag, $attr, %filter);

Returns an ARRAY of unique normalized URIs, which where found with the
C<$tag> attribute C<$attr>.  For instance, tag C<image> attribute C<src>.
The URIs are in their textual order in the document, where only the
first encounter is recorded.

The C<%filter> rules will produce a subset of the links found.  You can
use: C<http_only> (returning only http and https links), C<mailto_only>,
C<maximum_set> (returning only the first C<n> links) and C<matching>,
returning links matching a certain regex.

=head2 collectReferences

    $hash = $self->collectReferences(%filter);

Collects all references from document.  Method C<collectReferencesFor()>
is called for a list of known tag/attribute pairs, and returned as a
HASH of ARRAYs.  The keys of the HASH have format "$tag\_$attribute".
=cut

### collectReferences*() are in mixin file ::References


=head2 collectOpenGraph

    $hash = $self->collectOpenGraph;

=cut

### collectOpenGraph() is in mixin file ::OpenGraph

=head1 SEE ALSO

L<URI::Fast>, L<XML::LibXML>, L<Log::Report>

=head1 AUTHORS and COPYRIGHT
    
    Mark Overmeer
    CPAN ID: MARKOV
    markov at cpan dot org

    Красимир Беров
    CPAN ID: BEROV
    berov на cpan точка org
    https://studio-berov.eu

This is free software, licensed under: The Artistic License 2.0 (GPL
Compatible) The full text of the license can be found in the LICENSE
file included with this module.
=cut

1;

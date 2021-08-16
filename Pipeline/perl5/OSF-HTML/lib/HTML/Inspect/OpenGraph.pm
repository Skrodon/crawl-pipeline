
package HTML::Inspect;   # role OpenGraph

use strict;
use warnings;
use utf8;
no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

use Log::Report 'html-inspect';
use XML::LibXML ();

my @sub_types = qw/article book music profile video website/;
my %default_prefixes =
  ( og       => 'https://ogp.me/ns#',
    map +($_ => "https://ogp.me/ns/$_#"), @sub_types,
  );
my %namespace2prefix = reverse %default_prefixes;

# When the property itself does not contain an attribute, but we know
# that it may have attributes ("structured properties"), we need to create
# a HASH which stores this content.  We want consistent output, whether
# the attributes are actually present or not.
my %is_structural = (
   'og:image'    => 'url',
   'og:video'    => 'url',
   'og:audio'    => 'url',
   'og:locale'   => 'this',
   'music:album' => 'location',     # not sure about this one
   'music:song'  => 'description',  # not sure about this one
   'video:actor' => 'profile',
);

# Some properties or attributes can appear more than once.  They will always
# be collected as ARRAY, even if there is only one presence: this helps
# implementors.
my %is_array  = map +($_ => 1), qw/
    article:author
    article:tag
    book:author
    book:tag
    music:album
    music:musician
    music:song
    og:audio
    og:image
    og:locale:alternate
    og:video
    video:actor
    video:director
    video:tag
    video:writer
/;

=encoding utf-8

=head1 NAME

HTML::Inspect::OpenGraph - extract OpenGraph information from HTML

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 collectOpenGraph

    my $data = $self->collectOpenGraph

=cut

my $X_META_PROPERTY = XML::LibXML::XPathExpression->new('//meta[@property]');
sub collectOpenGraph($self, %args) {
    return $self->{HIO_og} if $self->{HIO_og};

    # Create a map which translates the used prefix in the HTML, to the prefered
    # prefix from the OGP specification.
    my $prefer = $self->{HIO_pref_prefix} = {};  
    my $nss    = $self->{HIO_nss}         = {};  
    foreach my $def (map $_->getAttribute('prefix'), $self->doc->findnodes('//[@prefix]')) {
        while(my ($prefix, $ns) = $def =~ m!(\w+)\:\s*(\S+)!g)
        {   $prefer->{$prefix} = $namespace2prefix{$ns} // $prefix;
            $nss->{$prefix} = $nss;     #XXX needed?
        }
    }

    my $data = $self->{HIO_og} = {};
    foreach my $meta ($self->doc->findnodes($X_META_PROPERTY)) {
        my ($used_prefix, $name, $attr) = split /\:/, lc $meta->getAttribute('property');
        my $content  = _trimss $meta->getAttribute('content');
        my $prefix   = $self->{HIO_pref_prefix}{$used_prefix} || $used_prefix;
        my $property = "$prefix:$name";
        my $table    = $data->{$prefix} ||= {};

        if($attr) {
            if(my $structure = $is_array{$property} ? $table->{$name}[-1] : $table->{$name}) {
               if($is_array{"$property:$attr"}) {
                   push @{$structure->{$attr}}, $content;
               }
               else {
                   $structure->{$attr} = $content;
               }
            }
            # ignore attributes without starting property
        }
        elsif(my $default_attr = $is_structural{$property}) {
            if($is_array{$property}) {
                push @{$table->{$name}}, { $default_attr => $content };
            }
            else {
                $table->{$name} = { $default_attr => $content };
            }
        }
        else {
            $table->{$name} = $content;
        }
    }
    $data;
}

=head1 AUTHORS and COPYRIGHT
    
    Mark Overmeer
    CPAN ID: MARKOV
    markov at cpan dot org
    https://solutions.overmeer.net/

    Красимир Беров
    CPAN ID: BEROV
    berov на cpan точка org
    https://studio-berov.eu

This is free software, licensed under:

The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the LICENSE file included with
this module.

This distribution contains other free software  and content which belongs to
their respective authors.
=cut

1;
1;

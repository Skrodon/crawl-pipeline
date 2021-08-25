package HTML::Inspect;  # Micin

use strict;
use warnings;
use utf8;

no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

use Log::Report 'html-inspect';

use HTML::Inspect::Util       qw(trim_attr xpc_find);

# According to https://www.w3schools.com/tags/tag_meta.asp
# There are far too many other fields which are not interesting.
my @classic_names = qw/
   application-name
   author
   description
   generator
   keywords
   viewport
/;

sub collectMetaClassic($self, %args) {
    return $self->{HIM_classic} if $self->{HIM_classic};

    my %names;
    my $all_names = $self->collectMetaNames;
    $names{$_} = $all_names->{$_}
        for grep defined $all_names->{$_}, @classic_names;

    my %meta = (name => \%names);

    # Take all http-equiv fields, because there is no restricted list.
    state $http_equiv = xpc_find '//meta[@http-equiv]';
    foreach my $eq ($http_equiv->($self)) {
        my $http    = $eq->getAttribute('http-equiv');
        my $content = $eq->getAttribute('content') // next;
        $meta{'http-equiv'}{lc $http} = trim_attr $content;
    }

    state $find_charset = xpc_find '//meta[@charset]';
    if(my ($elem) = $find_charset->($self)) {
        $meta{charset} = lc trim_attr $elem->getAttribute('charset');
    }

    $self->{HIM_classic} = \%meta;
}

sub collectMetaNames($self, %args) {
    return $self->{HIM_names} if $self->{HIM_names};

    my %names;

    if(my $all = $self->{HIM_all}) {
        # Reuse data already collected
        $names{$_->{name}} = $_->{content}
           for grep { exists $_->{name} && exists $_->{content} } @$all;
    }
    else {
        state $find_names = xpc_find '//meta[@name and @content]';

        $names{trim_attr $_->getAttribute('name')} = trim_attr $_->getAttribute('content')
            for $find_names->($self);
    }

    $self->{HIM_names} = \%names;
}

sub collectMeta($self, %args) {
    return $self->{HIM_all} if $self->{HIM_all};

    my @meta;
    state $find_meta = xpc_find '//meta';

    foreach my $link ($find_meta->($self)) {
        my %attrs = map +($_->name => $_->value),
            grep $_->isa('XML::LibXML::Attr'), $link->attributes;
        push @meta, \%attrs;
    }

    $self->{HIM_all} = \@meta;
}

=head1 SEE ALSO

L<URI::Fast>, L<XML::LibXML>, L<Log::Report>

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

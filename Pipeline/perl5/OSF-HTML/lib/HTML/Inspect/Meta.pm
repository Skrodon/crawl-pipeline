#line 1 Inspect.pm
# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

### This module handles various generic extractions of <meta> elements.

package HTML::Inspect;    # Mixin

use strict;
use warnings;
use utf8;

no warnings 'experimental::lexical_subs';    # needed if $] < 5.026;
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

use Log::Report 'html-inspect';

use HTML::Inspect::Util qw(trim_attr xpc_find get_attributes);

# According https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta/name
# There are far too many other fields which are not interesting.
my @classic_names = qw/
    application-name
    author
    color-scheme
    creator
    description
    generator
    googlebot
    keywords
    publisher
    referrer
    robots
    viewport
    theme-color
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

    state $find_meta = xpc_find '//meta';
    $self->{HIM_all} = [ map get_attributes($_), $find_meta->($self) ];
}

1;

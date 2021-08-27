package HTML::Inspect;    # Mixin

use strict;
use warnings;
use utf8;

no warnings 'experimental::lexical_subs';
no warnings 'experimental::signatures';
use feature qw (:5.20 lexical_subs signatures);

use Log::Report 'html-inspect';

use HTML::Inspect::Util qw(xpc_find absolute_url);
use List::Util qw(uniq);

# A map: for which tag which attributes to be considered as links?
# We can add more tags and types of links later.
my %referencing_attributes = (
    a      => 'href',
    area   => 'href',
    base   => 'href',     # could be kept from the start, would add complexity
    embed  => 'src',
    form   => 'action',
    iframe => 'src',
    img    => 'src',
    link   => 'href',     # could use collectLinks(), but probably slower by complexity
    script => 'src',
);
sub _refAttributes($thing) { return \%referencing_attributes }    # for testing only

sub collectReferences($self) {
    return $self->{HIR_refs} if $self->{HIR_refs};
    my $base = $self->base;

    state %find = map +("$_\_$referencing_attributes{$_}" => xpc_find "//$_\[\@$referencing_attributes{$_}\]"),
      keys %referencing_attributes;

    my %refs;
    while (my ($tag, $attr) = each %referencing_attributes) {
        my @attrs = uniq map absolute_url($_->getAttribute($attr), $base), $find{"${tag}_$attr"}->($self);

        $refs{"${tag}_$attr"} = \@attrs if @attrs;
    }

    $self->{HIR_refs} = \%refs;
}

1;

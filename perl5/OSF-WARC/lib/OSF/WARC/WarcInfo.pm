package OSF::WARC::WarcInfo;
use parent 'OSF::WARC::Record';

use JSON;

sub type() { 'warcinfo' }

sub index()
{   my $self = shift;
    $self->{OWW_index} ||= $self->warcFields;
}

sub fields() { keys %{$_[0]->index} }
sub value($) { $_[0]->index->{$_[1]} }

1;

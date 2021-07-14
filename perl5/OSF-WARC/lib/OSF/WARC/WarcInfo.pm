package OSF::WARC::WarcInfo;
use parent 'OSF::WARC::Record';

use JSON;

sub type() { 'warcinfo' }

sub _index()
{   my $self = shift;
    $self->{OWW_index} ||= $self->warcFields;
}

sub fields() { keys %{$_[0]->_index} }
sub value($) { $_[0]->_index->{$_[1]} }

1;

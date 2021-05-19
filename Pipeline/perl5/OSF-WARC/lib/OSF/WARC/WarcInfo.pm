package OSF::WARC::WarcInfo;
use parent 'OSF::WARC::Record';

use JSON;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'warcinfo' or die;
    $rec;
}

sub _index()
{   my $self = shift;
    $self->{OWW_index} ||= $self->warcFields;
}

sub fields() { keys %{$_[0]->_index} }
sub value($) { $_[0]->_index->{$_[1]} }

1;

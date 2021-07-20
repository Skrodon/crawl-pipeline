package OSF::WARC::Metadata;
use parent 'OSF::WARC::Record';

use JSON   qw(decode_json);

sub type() { 'metadata' }

sub _index()
{   my $self = shift;
    return $self->{OWM_index} if $self->{OWM_index};

    my $ct = lc($self->header('Content-Type') or die);
    $self->{OWM_index}
       = $ct eq 'application/warc-fields' ? $self->warcFields
       : $ct eq 'application/json'        ? decode_json ${$self->refBody}
       : die $ct;
}

sub fields() { keys %{$_[0]->_index} }
sub value($) { $_[0]->_index->{$_[1]} }

1;

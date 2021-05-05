package OSF::WARC::Metadata;
use parent 'OSF::WARC::Record';

use JSON;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'metadata' or die;
    $rec;
}

sub _index()
{   my $self = shift;
    return $self->{OWM_index} if $self->{OWM_index};

    my $ct = lc($self->header('Content-Type') or die);
    $self->{OWM_index}
       = $ct eq 'application/warc-fields' ? $self->_warc_fields
       : $ct eq 'application/json'        ? decode_json ${$self->ref_body}
       : die $ct;
}

sub fields() { keys %{$_[0]->_index} }
sub value($) { $_[0]->_index->{$_[1]} }

1;

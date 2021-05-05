package OSF::WARC::Request;
use parent 'OSF::WARC::Record';

use HTTP::Request;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'request' or die;
    $rec;
}

sub http_request()
{   my $self = shift;
    $self->{OWR_req} ||= HTTP::Request->parse(${$self->ref_body});
}

1;

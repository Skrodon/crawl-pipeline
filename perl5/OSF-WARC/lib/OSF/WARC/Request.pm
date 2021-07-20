package OSF::WARC::Request;
use parent 'OSF::WARC::Record';

use HTTP::Request;

sub type() { 'request' }

sub http_request()
{   my $self = shift;
    $self->{OWR_req} ||= HTTP::Request->parse(${$self->refBody});
}

1;

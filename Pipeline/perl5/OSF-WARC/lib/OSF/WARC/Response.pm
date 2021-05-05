package OSF::WARC::Response;
use parent 'OSF::WARC::Record';

use HTTP::Response;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'response' or die;
    $rec;
}

sub http_response()
{   my $self = shift;
    $self->{OWR_res} ||= HTTP::Response->parse(${$self->ref_body});
}

1;

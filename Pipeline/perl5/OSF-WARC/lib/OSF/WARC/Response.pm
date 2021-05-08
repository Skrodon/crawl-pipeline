package OSF::WARC::Response;
use parent 'OSF::WARC::Record';

use warnings;
use strict;

use HTTP::Response ();
use MIME::Types    ();
my $mt = MIME::Types->new;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'response' or die;
    $rec;
}

sub httpResponse()
{   my $self = shift;
    $self->{OWR_res} ||= HTTP::Response->parse(${$self->ref_body});
}

sub contentType($)
{   my $resp = $_[0]->httpResponse;
    $mt->type($resp->content_type || 'application/octet-stream');
}

1;

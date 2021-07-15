package OSF::WARC::Revisit;
use parent 'OSF::WARC::Record';

use HTTP::Response  ();

sub type() { 'revisit' }

sub status_code()
{   $_[0]->{OWR_status} ||=
      ${$_[0]->refBody} =~ m!^.*?HTTP\S+\s+([0-9]+)! ? $1 : undef;
    # $_[0]->httpResponse->code is slow
}

sub httpResponse()
{   my $self = shift;
    $self->{OWR_res} ||= HTTP::Response->parse(${$self->refBody});
}

1;

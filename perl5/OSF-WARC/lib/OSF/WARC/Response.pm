package OSF::WARC::Response;
use parent 'OSF::WARC::Record';

use warnings;
use strict;

use HTML::Inspect      ();
use HTTP::Response     ();

use MIME::Types        ();
my $mt = MIME::Types->new;

sub type() { 'response' }

sub httpResponse()
{   my $self = shift;
    $self->{OWR_res} ||= HTTP::Response->parse(${$self->refBody});
}

sub contentType($)
{   my $self = shift;
    $self->{OWR_ct} ||=
        $mt->type($self->httpResponse->content_type || 'application/octet-stream');
}

sub inspectHTML()
{   my $self = shift;
    return $self->{OWR_html} if exists $self->{OWR_html};

    my $ct = $self->contentType;
    $ct eq 'text/html' || $ct eq 'text/xhtml'
        or return $self->{OWR_html} = undef;

    my $resp = $self->httpResponse;
    my $html = $resp->decoded_content(ref => 1, alt_charset => 'cp-1252');

    my $headers = $resp->headers;
    my $base
        = $headers->header('Content-Location')
       || $headers->header('Content-Base')
       || $headers->header('Base')
       || $self->uri;               # from WARC meta

    $self->{OWR_html} = HTML::Inspect->new(
        html_ref    => $html,
        request_url => $base,
    );
}

1;

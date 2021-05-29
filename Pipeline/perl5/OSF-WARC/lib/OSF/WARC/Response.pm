package OSF::WARC::Response;
use parent 'OSF::WARC::Record';

use warnings;
use strict;

use OSF::HTML::Inspect ();
use HTTP::Response     ();

use MIME::Types        ();
my $mt = MIME::Types->new;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'response' or die;
    $rec;
}

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

    my $html = $self->httpResponse->decoded_content(ref => 1,
        alt_charset => 'cp-1252'
    );

    $self->{OWR_html} = OSF::HTML::Inspect->new(html_ref => $html);
}

1;

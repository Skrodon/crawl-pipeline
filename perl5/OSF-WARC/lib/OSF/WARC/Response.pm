package OSF::WARC::Response;
use parent 'OSF::WARC::Record';

use warnings;
use strict;

use HTML::Inspect      ();
use HTTP::Response     ();
use URI::Fast          qw(html_url);

use MIME::Types        ();
my $mt = MIME::Types->new;

sub type() { 'response' }

sub httpResponse()
{   my $self = shift;
    $self->{OWR_res} ||= HTTP::Response->parse(${$self->refBody});
}

sub contentType($)   # Returns a MIME::Type smart object
{   my $self = shift;
    $self->{OWR_ct}
      ||= $mt->type($self->httpResponse->content_type)
      ||  'application/octet-stream';
}

my %html_mimes = map +($_ => 1),
    qw!text/html text/xhtml application/xml!;

sub isHTML()
{   my $self = shift;
    $html_mimes{$self->contentType};
}

sub decodedHtmlContent()
{   $_[0]->{OWR_dec} ||= $_[0]->httpResponse->decoded_content(ref => 1, alt_charset => 'cp-1252');
}

sub inspectHTML()
{   my $self = shift;
    return $self->{OWR_html} if exists $self->{OWR_html};

    $self->isHTML
        or return $self->{OWR_html} = undef;

    my $headers = $self->httpResponse->headers;
    my $location
        = $headers->header('Content-Base')
       || $headers->header('Base')
       || $headers->header('Content-Location');

    $self->{OWR_html} = HTML::Inspect->new(
        html_ref    => $self->decodedHtmlContent,
        request_uri => defined $location ? html_url($location, $self->uri)->as_string : $self->uri;
    );
}

sub isHTML5()
{   my $self = shift;
    return $self->{OWR_is5} if exists $self->{OWR_is5};

    $self->isHTML    # any HTML based on mime-type
        or return $self->{OWR_is5} = 0;

    my $text = $self->decodedHtmlContent;
    $self->{OWR_is5} = $$text =~ m#^\W*\<!DOCTYPE\s+html[>\s]#;
}

1;

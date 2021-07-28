package OSF::CommonCrawl::Product;
use parent 'OSF::Pipeline::Product';

use warnings;
use strict;

use Log::Report 'osf-commoncrawl';

use JSON   qw(decode_json);
use URI    ();

sub _init($)
{   my ($self, $args) = @_;
    $args->{origin} = 'CommonCrawl';
    $self->SUPER::_init($args);
    $self;
}

sub _id()   { $_[0]->part('request')->recordId =~ s/^urn\:uuid\://r }
sub _name() { $_[0]->uri->as_string }

sub uri()
{   my $self = shift;
    $self->{OCP_uri} ||= URI->new($self->part('request')->uri)->canonical;
}

sub cld2()
{   my $self = shift;
    return $self->{OCP_cld2} if defined $self->{OCP_cld2};

    my $meta = $self->part('metadata') or return;
    my $cld2 = $meta->value('languages-cld2') or return;
    $self->{OCP_cld2} = decode_json $cld2;
}

# Could also use part('text')/WARC-Identified-Content-Language

sub _lang()
{   my $cld2   = shift->cld2 or return;
    my $langs  = $cld2->{languages} || [];
    (my $best) = sort { $b->{'text-covered'} <=> $a->{'text-covered'} } @$langs;
    $best ? $best->{'code-iso-639-3'} : undef;
}

sub _ct()
{   my $self = shift;

    my $ct;
    if(my $response = $self->part('response'))
    {   $ct = $response->header('WARC-Identified-Payload-Type')
           || $response->contentType;
    }
    else
    {   # We could try to use MIME::Type->mimeTypeOf($uri) to
        # autodetect the type, but that's what server software
        # usually already does for us.
    }

    $ct;
}

sub _refText()
{   my $part = $_[0]->part('text') or return;
    $part->refBody;
}

sub _rs()
{   my $part = $_[0]->part('response') or return;
    $part->httpResponse->code;
}

1;

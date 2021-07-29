package OSF::WARC::Record;

use warnings;
use strict;

use Log::Report 'osf-warc';

use POSIX   qw(SEEK_SET);
my $CRLF = "\015\012";

#!!! $body is reference to a scalar, because Perl makes copies in
#!!! some cases, which may be avoided this way.

sub new($$$)
{   my ($class, %args) = @_;
    (bless { }, $class)->_init(\%args);
}

sub _init($)
{   my ($self, $args) = @_;
    $self->{OWR_head}  = $args->{head} or panic 'Head';
    $self->{OWR_body}  = $args->{body} or panic 'Body';
    $self->{OWR_compr} = $args->{compressed};
    $self;
}

sub type()    { panic 'Type' }   # via extension
sub refBody() { $_[0]->{OWR_body} }
sub head()    { $_[0]->{OWR_head} }
sub header($) { $_[0]->{OWR_head}{$_[1]} } # $self, $field
sub uri()     { $_[0]->header('WARC-Target-URI') }
sub compressed() { $_[0]->{OWR_compr} }
sub date      { $_[0]->header('WARC-Date') }

sub recordId()
{   $_[0]->{OWR_id} ||=
        $_[0]->header('WARC-Record-ID') =~ m!\<(.+)\>! ? $1 : panic;
}

sub basedOn()
{   my $self = shift;
    return $self->{OWR_base} if exists $self->{OWR_base};

    my $h = $self->header('WARC-Concurrent-To')
         || $self->header('WARC-Refers-To')
        or return;

    $self->{OWR_base} = $h =~ m!\<(.+)\>! ? $1 : undef;
}

sub warcFields()
{   my $body = shift->refBody;
    +{ $$body =~ /^([^:]+)\:\s+(.*?)\s*$/gm };
}

sub getRecord($;$)
{   my ($self, $supply, $record_id) = @_;
    my $rec = $supply->getRecord($record_id) or return;

    return $rec if $rec->header('WARC-Type') eq $self->type;

    error "Unexpected WARC record type '{has}', expected '{need}'",
        has => $$rec->header('WARC-Type'), need => $self->type;
}

sub write($$)
{   my ($self, $outfh) = @_;
    my $head = $self->head;
    my $body = $self->refBody;

    $outfh->print(join $CRLF, 'WARC/1.0',
       (map "$_: $head->{$_}", sort keys %$head),
       '', $$body);
    $outfh->print($CRLF) if $$body =~ m!$CRLF\z!;

    $self;
}

1;

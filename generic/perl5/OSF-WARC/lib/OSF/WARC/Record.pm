package OSF::WARC::Record;

use warnings;
use strict;

use POSIX   qw(SEEK_SET);

#!!! $body is reference to a scalar, because Perl makes copies in
#!!! some cases, which may be avoided this way.

sub new($$$)
{   my ($class, $head, $body, $loc) = @_;
    bless { OWR_head => $head, OWR_body => $body, OWR_loc => $loc }, $class;
}

sub header($)
{   my ($self, $field) = @_;
    $self->{OWR_head}{lc $field};
}

sub uri()   { $_[0]->header('WARC-Target-URI') }

sub setId()
{   my $self = shift;
    $self->{OWR_set}
      ||= $self->header('WARC-Warcinfo-ID')
      ||  $self->header('WARC-Refers-To');
}

sub refBody() { $_[0]->{OWR_body} }

sub warcFields()
{   my $body = shift->ref_body;
    +{ $$body =~ /^([^:]+)\:\s+(.*?)\s*$/gm };
}

sub write($$)
{   my ($self, $outfh) = @_;
    my ($infh, $start, $size) = @{$self->{OWR_loc}};
    $infh->seek($start, SEEK_SET);
    $infh->read(my $buffer, $size);
    $outfh->write($buffer);
}

1;

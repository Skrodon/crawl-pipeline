
package OSF::WARC::Sink;
# Create a WARC file

use warnings;
use strict;

use IO::Compress::Gzip qw($GzipError);
use Fcntl   qw(SEEK_CUR SEEK_END);

sub new(%)
{   my $class = shift;
    (bless {}, $class)->_init({@_});
}

sub _init($)
{   my ($self, $args) = @_;
    my $fn = $self->{OWS_fn} = $args->{filename} or panic;
    open $self->{OWS_fh}, '>:raw', $fn
        or fault __x"Cannot write {fn}", fn => $fn;

    $self;
}

# WARC spec wants files of about 1GB
sub isFull()     { -s $_[0]->filename > 1024 * 1024 }

sub filename()   { $_[0]->{OWS_fn} }
sub _fh()        { $_[0]->{OWS_fh} }
sub index()      { $_[0]->{OWS_index} ||= {} }
sub nr_records() { scalar keys %{$_[0]->index} }

sub write($)
{   my ($self, $record) = @_;
    my $out = $self->_fh;
    $self->{OWS_recs}++;

    my $start = sysseek $out, 0, SEEK_END;

    if(my $c = $record->compressed)
    {   my ($in, $from, $size) = @_;
        sysseek $in, $from;
        sysread $in, my $zipped, $size;
        syswrite $out, $zipped;
    }
    else
    {   my $z = IO::Compress::Gzip->new($out);
        $record->write($z);
        $z->close;
    }

    $self->index->{$record->name} =
     +{ 'offset' => $start
      , 'length' => (sysseek $out, 0, SEEK_CUR) - $start
      };

    $self;
}

1;

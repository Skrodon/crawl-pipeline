
package OSF::WARC::Sink;
# Create a WARC file

use warnings;
use strict;

use Log::Report 'osf-warc';

use IO::Compress::Gzip qw($GzipError);
use Fcntl              qw(SEEK_SET SEEK_CUR SEEK_END);

use constant WARC_FULL => 1024 * 1024 * 1024;   # 1GB, according to spec

sub new(%) { my $class = shift; (bless {}, $class)->_init({@_}) }

sub _init($)
{   my ($self, $args) = @_;
    my $fn = $self->{OWS_fn} = $args->{filename} or panic;

    if($args->{reopen})
    {   open $self->{OWS_fh}, '>>:raw', $fn
            or fault __x"Cannot append to WARC {fn}", fn => $fn;
    }
    else
    {   open $self->{OWS_fh}, '>:raw', $fn
            or fault __x"Cannot write to WARC{fn}", fn => $fn;
    }

    $self->{OWS_index} = $args->{index} || {};
    $self;
}

# WARC spec wants files of about 1GB
sub isFull()     { -s $_[0]->filename >= WARC_FULL }

sub filename()   { $_[0]->{OWS_fn} }
sub _fh()        { $_[0]->{OWS_fh} }
sub index()      { $_[0]->{OWS_index} }
sub nr_records() { scalar keys %{$_[0]->index} }

sub write($$)
{   my ($self, $record, $facts) = @_;
    my $out = $self->_fh;
    $self->{OWS_recs}++;

    my $start = sysseek $out, 0, SEEK_END;

    if(my $c = $record->compressed)
    {   my ($in, $from, $size) = @$c;
        sysseek $in, $from, SEEK_SET;
        sysread $in, (my $zipped), $size;
        syswrite $out, $zipped;
    }
    else
    {   my $z = IO::Compress::Gzip->new($out);
        $record->write($z);
        $z->close;
    }

    my %data =
      ( %$facts
      , stream_offset => $start
      , stream_length => (sysseek $out, 0, SEEK_CUR) - $start
      );

    my $key;
    if($record->type eq 'warcinfo')
    {   $key  = '__WARCINFO__';
        my $info = $record->info || {};
        @data{keys %$info} = values %$info;
    }
    else
    {   $key  = $record->uri;
    }

    $self->index->{$key}{$record->type} = \%data;
    $self;
}

1;

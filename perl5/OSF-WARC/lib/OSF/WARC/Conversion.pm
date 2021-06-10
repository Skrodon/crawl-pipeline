package OSF::WARC::Conversion;
use parent 'OSF::WARC::Record';

use JSON;

sub getRecord(@)
{   my $self = shift;
    my $rec  = $self->SUPER::getRecord(@_);

    $rec->header('WARC-Type') eq 'conversion' or die;
    $rec;
}

1;

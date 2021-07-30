package OSF::Pipeline::Product;
  
use warnings;
use strict;

use Log::Report 'osf-pipeline';

sub new(%) { my $class = shift; (bless {}, $class)->_init( {@_} ) }

sub _init($)
{   my ($self, $args) = @_;
    $self->{OPP_parts}  = $args->{parts} || {};
    $self->{OPP_origin} = $args->{origin} // panic;
    $self->{OPP_name}   = $args->{name};
    $self;
}

sub stamp
{   my $self = shift;
     +{ origin       => $self->origin,
      , product_id   => $self->id,
      , name         => $self->name,
      , content_type => $self->contentType,
      , @_,
      };
}

sub part($)       { $_[0]->{OPP_parts}{$_[1]} }

sub id()          { $_[0]->{OPP_id}   ||= $_[0]->_id }
sub name()        { $_[0]->{OPP_name} ||= $_[0]->_name }
sub origin()      { $_[0]->{OPP_origin} }
sub contentType() { $_[0]->{OPP_ct}   ||= $_[0]->_ct || 'application/octet-stream' }
sub responseStatus{ $_[0]->{OPP_rs}   ||= $_[0]->_rs }

sub refPlainText()     { $_[0]->{OPP_text}  //= $_[0]->_refText // \'' }
sub contentSize()      { length ${$_[0]->refPlainText} }
sub contentWordChars() { $_[0]->{OPP_chars} //= length(${$_[0]->refPlainText} =~ s/\P{PerlWord}//gr) }
sub contentWords()     { $_[0]->{OPP_words} //= () = ${$_[0]->refPlainText} =~ m!\w+!g }

=method language
Returns the iso-639-3 code for the language which was detected the most
in the response text.
=cut

sub language()    { $_[0]->{OPP_lang} ||= $_[0]->_lang }
sub _lang()       { undef }

=method reportError $exception
Add a processing error report to the list of reported errors.  No-one is
looking into the errors at the moment.  The C<$exception> is a
M<Log::Report::Exception> which stringifies in an error text.
=cut

sub reportError($) { push @{$_[0]->{OPP_errors}}, $_[1] }

=method errors
Returns all reported processing exceptions (M<Log::Report::Exception> objects)
=cut

sub errors() { @{$_[0]->{OPP_errors} || {} } }

1;


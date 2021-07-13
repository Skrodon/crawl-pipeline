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

sub plainTextRef()     { $_[0]->{OPP_text}  //= $_[0]->_textRef // '' }
sub contentSize()      { length ${$_[0]->plainTextRef} }
sub contentWordChars() { $_[0]->{OPP_chars} //= length(${$_[0]->plainTextRef} =~ s/\P{PerlWord}//gr) }
sub contentWords()     { $_[0]->{OPP_words} //= () = ${$_[0]->plainTextRef} =~ m!\w+!g }

1;


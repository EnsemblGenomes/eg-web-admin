package EnsEMBL::Web::Factory::ModalDocuments;

### NAME: EnsEMBL::Web::Factory::ModalDocuments
### Very simple factory to produce EnsEMBL::Web::Object::ModalDocuments objects

### STATUS: Stable

use strict;
use warnings;

use base qw(EnsEMBL::Web::Factory);

sub createObjects {
  my $self = shift;
  $self->DataObjects($self->new_object('ModalDocuments', undef, $self->__data));
}


1;

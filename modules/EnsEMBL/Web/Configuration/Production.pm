package EnsEMBL::Web::Configuration::Production;

use strict;
use warnings;

sub modify_tree{
  my $self = shift;
  $self->delete_node($_) for qw(Species AttribType ExternalDb);
}

1;

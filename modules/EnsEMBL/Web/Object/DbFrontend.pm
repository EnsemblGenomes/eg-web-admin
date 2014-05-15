package EnsEMBL::Web::Object::DbFrontend;

use strict;

sub default_action {
  ## @returns the default action string for the webpages
  ## Override in child classes if another action needed as default
  return 'List';
}

1;

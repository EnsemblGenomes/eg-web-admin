package EnsEMBL::Web::Configuration::Documents;

use base qw(EnsEMBL::Web::Configuration);

use strict;
#use EnsEMBL::Admin::Component::Documents::ViewHTML;

sub caption { return ''; }

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'List';
}

sub populate_tree {
  my $self  = shift;
  my $hub   = $self->hub;

  my $menu = $self->create_node('List', 'Web Documents',
    [ 'view' => 'EnsEMBL::Admin::Component::Documents::Summary' ],
    { 'availability' => 1, 'filters' => ['WebAdmin'] }
  );
  $menu->append($self->create_node('View', '',
    [
      'view' => 'EnsEMBL::Admin::Component::Documents::View',
    ],
    { 'no_menu_entry'=>1,'availability' => 1, 'filters' => ['WebAdmin'] }
  ));
  $self->create_node( 'Edit', '',
     [], { 'availability' => 1, 'no_menu_entry' => 1,
     'command' => 'EnsEMBL::Web::Command::Documents::Edit'}
  );
  $self->create_node( 'Upload', '',
     [], { 'availability' => 1, 'no_menu_entry' => 1,
     'command' => 'EnsEMBL::Web::Command::Documents::Upload'}
  );
  $self->create_node( 'Delete', '',
     [], { 'availability' => 1, 'no_menu_entry' => 1,
     'command' => 'EnsEMBL::Web::Command::Documents::Delete'}
  );
  $self->create_node( 'Lock', '',
     [], { 'availability' => 1, 'no_menu_entry' => 1,
     'command' => 'EnsEMBL::Web::Command::Documents::Lock'}
  );
}

1;
  


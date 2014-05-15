package EnsEMBL::Web::Configuration::ModalDocuments;

use base qw(EnsEMBL::Web::Configuration);

use strict;

sub caption { return ''; }

sub set_default_action {
  my $self = shift;
  $self->{'_data'}{'default'} = 'Images';
}

sub populate_tree {
  my $self  = shift;
  my $hub   = $self->hub;
  my $pathname = $hub->function;

  my $menu = $self->create_node('Images', 'Images',
    [
      'images' => 'EnsEMBL::Admin::Component::ModalDocuments::Images',
    ],
    { 'availability' => 1, 'filters' => ['WebAdmin']}
  );
  $self->create_node('Images/View', 'Images',
    [
      'images' => 'EnsEMBL::Admin::Component::ModalDocuments::Images',
    ],
    { 'availability' => 1, no_menu_entry=>1, 'filters' => ['WebAdmin']}
  );
  $self->create_node( 'Upload', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1,
    'command' => 'EnsEMBL::Web::Command::ModalDocuments::Upload'}
  );
  $self->create_node( 'Delete', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1,
    'command' => 'EnsEMBL::Web::Command::ModalDocuments::Delete'}
  );
  $self->create_node( 'Commit', '',
    [], { 'availability' => 1, 'no_menu_entry' => 1,
    'command' => 'EnsEMBL::Web::Command::ModalDocuments::Commit'}
  );
  for my $plugin (keys %$SiteDefs::CONTENT_CONFIG){
    my $config = $SiteDefs::CONTENT_CONFIG->{$plugin};
    for my $subdir (@{$config->{'images'}}){
      my $uscore_subdir = $subdir;
      $menu->append(
        $self->create_node("Images/$plugin/$subdir", "$plugin/$subdir",
        [
          'images' => 'EnsEMBL::Admin::Component::ModalDocuments::Images',
        ],
        { 'availability' => 1, 'filters' => ['WebAdmin'],
          'url' => $hub->url({type=>'ModalDocuments',action=>'Images',
            pathname=>$plugin,subdir=>$subdir})
        }
        )
      );
    }
  }
}

1;
  


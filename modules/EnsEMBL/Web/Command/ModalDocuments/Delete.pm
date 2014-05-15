package EnsEMBL::Web::Command::ModalDocuments::Delete;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub          = $self->hub;
  my $pathname     = $hub->param('pathname');
  my $config       = $SiteDefs::CONTENT_CONFIG->{$pathname};
  my $subdir       = $hub->param('subdir');
  my $image_file   = $hub->param('file');# image file name
  my $root         = $config->{'root'};
  my $dest         = join("/",($root,$subdir,$image_file));
  my $tmp_filename = $hub->input->tmpFileName($image_file);
  if(unlink("$dest")){
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'image_delete_succeeded',
      message => "Image deleted: $pathname/$subdir/$image_file"
    );
  }
  else{
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_delete_failed',
      message => "Delete failed for $pathname/$subdir/$image_file"
    );
  }
  my $url = $hub->url({action=>'Images','pathname'=>$pathname,'subdir'=>$subdir});

  $self->ajax_redirect($url);
    
}

1;

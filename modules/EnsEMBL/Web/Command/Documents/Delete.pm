package EnsEMBL::Web::Command::Documents::Delete;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub     = $self->hub;
  my $object     = $self->object;
###The current file being edited (View)
  my $load_pathname = $hub->param('load_pathname');
  my $filename = $hub->param('filename');
###
  my $pathname = $hub->param('pathname');
  my $image_file = $hub->param('file');# image file name
  my $cfg = $object->get_config($pathname);
  my @imgpath = split('_',$pathname);
  my $pathname = shift @imgpath;
  push (@imgpath, $image_file);
  unshift(@imgpath,$cfg->{'root'});
  my $dest = join("/",@imgpath);
  if(unlink("$dest")){
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'image_delete_succeeded',
      message => "Image deleted: $image_file"
    );
  }
  else{
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_delete_failed',
      message => "Delete failed for $image_file"
    );
  }
  if($filename && $pathname){
    $self->ajax_redirect($hub->url({action=>'View',function=>$load_pathname, f=>$filename}));
  }
  else{
    $self->ajax_redirect($hub->url({action=>'List'}));
  }
    
}

1;

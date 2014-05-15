package EnsEMBL::Web::Command::Documents::Upload;

use strict;

use File::Copy;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub     = $self->hub;
  my $object     = $self->object;
  my $path = $hub->param('pathname');
  my $filename = $hub->param('filename');#not the upload filename, the current file being edited (View)
  my $image_file = $hub->param('file');# image file name
  my $action = $hub->param('action');
  my $load_pathname = $hub->param('load_pathname');
  my $plugins = $object->available_plugins;
  my @imgpath = split('_',$path);
  my $pathname = shift @imgpath;
  unshift(@imgpath,$object->abs_root($pathname));
  push (@imgpath, $image_file);
  my $dest = join("/",@imgpath);
  
    #dest: absolute path
  my $tmp_filename = $hub->input->tmpFileName($image_file);
  if(!$dest){
    unlink($tmp_filename);
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_upload_failed',
      message => "No upload directory selected"
    );
  }
  elsif($image_file !~ /png$|jpg$/i){
    unlink($tmp_filename);
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_upload_failed',
      message => "Image file rejected, not .jpg or .png: $image_file"
    );
  }
  else{
    move($tmp_filename,$dest);
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'image_upload_succeeded',
      message => "New image uploaded: $path/$image_file"
    );
  }
  if($pathname && $filename){
    $self->ajax_redirect($hub->url({action=>'View',function=>$load_pathname,f=>$filename}));
  }
  else {$self->ajax_redirect($hub->url({action=>'List'}));}
}

1;

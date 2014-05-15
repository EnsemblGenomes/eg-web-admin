package EnsEMBL::Web::Command::ModalDocuments::Upload;

use strict;

use File::Copy;
use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Command);
use Data::Dumper;
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
  if(!$dest){
    unlink($tmp_filename);
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_upload_failed',
      message => "No upload directory selected"
    );
  }
  elsif($image_file !~ /png$/i){
    unlink($tmp_filename);
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'image_upload_failed',
      message => "Image file rejected, not a .png file: $image_file"
    );
  }
  else{
    move($tmp_filename,$dest);
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'image_upload_succeeded',
      message => "New image uploaded: $pathname/$subdir/$image_file"
    );
  }
  # Grafted from EnsEMBL::Web::Command::UserData->file_uploaded()
  #  $hub->url not working with params
  #my $url = $hub->url({action=>'Images',function=>'View',pathname=>$pathname,f=>$image_file});
   my @params = map { encode_entities($_) } ($pathname, $subdir, $image_file);
   my $huburl = $hub->url({action=>'Images'});
   $huburl =~ s/[?]+.*$//;
   my $url = sprintf('%s?pathname=%s;subdir=%s;f=%s',
      $huburl,
      $params[0],
      $params[1],
      $params[2]);
      
  $self->r->content_type('text/html; charset=utf-8');
  print qq[
    <html>
    <head>
      <script type="text/javascript">
        if (!window.parent.Ensembl.EventManager.trigger('modalOpen', { href: '$url', title: 'File uploaded' })) {
          window.parent.location = '$url';
        }
      </script>
    </head>
    <body><p>UP</p></body>
    </html>
  ];
}

1;

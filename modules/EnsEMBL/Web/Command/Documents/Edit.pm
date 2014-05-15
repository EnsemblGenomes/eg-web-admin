package EnsEMBL::Web::Command::Documents::Edit;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub     = $self->hub;
  my $object  = $self->object;
  my $newcontent = $hub->param('text');
  my $pathname = $hub->param('pathname');
  my $filename = $hub->param('filename');
  $object->pathname($pathname);
  $object->filename($filename);
  my $action = $hub->param('action');
  my @images = $hub->param('images');
  my @cvs_options = $hub->param('cvs_options');
  my %params;
  map {$params{$_} = $hub->param($_)} $hub->param;
  @images = $hub->param('images');
  $params{'images'} = \@images;
  $params{'cvs_options'} = \@cvs_options;
  if($pathname && $filename && $object->open($pathname,$filename,$action)){
    if($action =~ /^commit$|^update$|^status$/i){
      my $result=$object->cvs(%params);
      $hub->session->add_data(
        type => 'message',
        function => '_info',
        code => 'doc_cvs_succeeded',
        message => $result
      );
    }
    else{ #action='View'; do the default operation:Save
      $object->content($newcontent);
      $object->write;
      $hub->session->add_data(
        type => 'message',
        function => '_info',
        code => 'doc_save_succeeded',
        message => 'Document saved'
      );
    }
  }
  elsif(!$pathname){
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'doc_save_failed',
      message => 'Select a destination'
    );
  }
  else {
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'doc_save_failed',
      message => 'Document could not be saved'
    );
  }
  if($pathname && $filename){
    $self->ajax_redirect($hub->url({action=>'View',function=>$pathname,f=>$filename}));
  }
  else {$self->ajax_redirect($hub->url({action=>'List'}));}
}

1;

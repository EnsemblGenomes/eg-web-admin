package EnsEMBL::Web::Command::Documents::Lock;

use strict;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $hub     = $self->hub;
  my $object     = $self->object;
  my $pathname = $hub->param('pathname');
  my $filename = $hub->param('filename');
  my $locktype = $hub->param('locktype');
  $object->open($pathname,$filename);
  my $status = $object->lock($locktype,$hub->user->{'email'});
  if($status){
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'locked',
      message => "$status: $pathname/$filename $locktype succeeded"
    );
  }
  else{
    $hub->session->add_data(
      type => 'message',
      function => '_error',
      code => 'locked',
      message => "$status: $pathname/$filename $locktype failed"
    );
  }
  if($filename && $pathname){
    $self->ajax_redirect($hub->url({action=>'View',function=>$pathname, f=>$filename}));
  }
  else{
    $self->ajax_redirect($hub->url({action=>'List'}));
  }
}

1;


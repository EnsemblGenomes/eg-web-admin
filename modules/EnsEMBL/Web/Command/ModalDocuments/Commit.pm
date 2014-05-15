package EnsEMBL::Web::Command::ModalDocuments::Commit;

use strict;
use Data::Dumper;

use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my %params;
  my $hub     = $self->hub;
  my $object  = $self->object;
  map {$params{$_} = $hub->param($_)} $hub->param;
  my $action = $hub->param('action');
  my $pathname = $hub->param('pathname');
  my $subdir = $hub->param('subdir');
  my $filename = $hub->param('filename');
  my $localpath = "$subdir/$filename";
  my $root      = $SiteDefs::CONTENT_CONFIG->{$pathname}->{'root'};
  my $fullpath  = "$root/$localpath";
  $params{'file'} = $fullpath;
  $params{'tag'} = $params{'tag_1'} || $params{'tag_2'};
  my @cvs_options = $hub->param('cvs_options');
  $params{'cvs_options'} = \@cvs_options;
  if($action =~ /^commit$|^update$/i){
    my $result=$object->cvs(%params);
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'cvs_succeeded',
      message => $result
    );
  }
  else{
    $hub->session->add_data(
      type => 'message',
      function => '_info',
      code => 'cvs_not_recognized',
      message => 'CVS operation not recognized'
    );
  }
  my $url = $hub->url({type=>'ModalDocuments',action=>'Images',pathname=>$pathname,subdir=>$subdir,f=>$filename}); 
  $self->ajax_redirect($url);

}

1;


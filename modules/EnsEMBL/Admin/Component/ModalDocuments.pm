package EnsEMBL::Admin::Component::ModalDocuments;

use strict;

use POSIX qw/strftime/;
use Cvs;

use base qw(EnsEMBL::Admin::Component::Documents);

# MOVED to parent
#
# sub md_open {
#   my ($self)=@_;
#   my $object  = $self->object;
#   my $hub = $self->hub;
#   my $pathname  = $object->{_md_data}->{'pathname'} = $hub->param('pathname');
#   my $filename      = $object->{_md_data}->{'filename'} = $hub->param('f') || $hub->param('filename');
#   my $subdir    = $object->{_md_data}->{'subdir'} = $hub->param('subdir');
#   my $root      = $SiteDefs::CONTENT_CONFIG->{$pathname}->{'root'};
#   my $localpath = "$subdir/$filename";
#   my $fullpath  = "$root/$localpath";
#   my $sandbox   = $root;
#   $sandbox      =~ s/^$SiteDefs::ENSEMBL_SERVERROOT//;
#   $object->{_md_data}->{'sandbox'} = $sandbox;
#   my $info      = $object->{_md_data}->{'cvs_status'} = $self->object->cvs('action'=>'info','file'=>$fullpath);
# }

sub cvs_form {
  my ($self,$action,$label)=@_;
  $self->md_open() unless exists $self->object->{_md_data};
  my $hub=$self->hub;
  my $cfg = $self->object->{_md_data};
  my $pathname = $cfg->{'pathname'};
  my $subdir = $cfg->{'subdir'};
  my $filename = $cfg->{'filename'};
  my $cvs_status = $cfg->{'cvs_status'};
  my @tags = reverse $cvs_status->tags;
  my $datetime   = strftime("%D %T",localtime);
  my $url = $hub->url({type=>'ModalDocuments',action=>'Commit',function=>$pathname,f=>$filename});# action here is the name of the Command module
  my $form = $self->modal_form('preview', $url,{no_button=>1, id=>'image_cvs_form_id'});
  $form->add_fieldset()->set_attribute('class', 'general_options');
  $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  $form->add_element( type => 'Hidden', name => 'subdir', value=> $subdir);
  $form->add_element( type => 'Hidden', name => 'filename', value=> $filename);
  $form->add_element( type => 'Hidden', name => 'action', value=>$action);

  if($action eq 'update'){
    $form->add_fieldset()->set_attribute('class', 'update');

    my @rev_options = ({value=>'HEAD',caption=>'HEAD',selected=>1});
    for my $tag (reverse @tags){
      my $tagrev = $cvs_status->tag_revision($tag);
      push (@rev_options,{value=>$tag,caption=>"$tag ($tagrev)",checked=>0});
    }
    $form->add_element(type=>'Dropdown',name=>'tag_2',label=>'Release branch','values'=> \@rev_options);
    $form->add_element( type => 'String', size=>'128', name => 'tag_1', label=>'or manually enter revision (overrides branch selection)',value=>"");
  
    $form->add_element( type => 'Checklist', name => 'cvs_options',label=>'Options', 'values'=>[
      {caption=>'Overwrite local if modified',value=>'overwrite', checked=>0,class=>undef},
    ]);
  }

  elsif($action eq 'commit'){
    $form->add_fieldset()->set_attribute('class', 'commit');
    $form->add_element( type => 'String', size=>'128', name => 'comment', label=>'Comment',value=>"Updated $datetime" , notes=>undef);
    $form->add_element( type => 'String', size=>'128', name => 'username', label=>'CVS User',value=>"" );
    $form->add_element( type => 'Password', size=>'128', name => 'password', label=>'CVS Password',value=>"" );

  }
  $form->add_element( type => 'Submit', name => 'submit', value=>$label || uc $action );

  return $form->render;
}


1;

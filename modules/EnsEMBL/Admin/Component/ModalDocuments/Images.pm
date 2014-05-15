package EnsEMBL::Admin::Component::ModalDocuments::Images;

use strict;

use base qw(EnsEMBL::Admin::Component::ModalDocuments);

sub caption {
  return '';
}

sub content {
  my $self    = shift;
  my $hub = $self->hub;
  my $pathname = $self->hub->param('pathname');
  my $subdir = $self->hub->param('subdir');
  my $filename = $self->hub->param('f');
  my $content = '';
  if($pathname && $subdir && $filename){
    $content .= $self->detail_view($pathname,$subdir,$filename);
  }
  elsif($pathname && $subdir){
    $content .= $self->upload_form($pathname,$subdir);
    $content .= $self->images_table($pathname,$subdir);
  }
  else{
    my $message = $self->dom->create_element('div',{class=>'plain-box'});
    $message->append_child('h3',{inner_HTML=>"Image directories"});
    my $cfg=$self->object->get_config;
    foreach $pathname (keys %$cfg){
      next unless $pathname;
      my $box = $message->append_child('div',{class=>'tinted-box'});
      $box->append_child('h3',{inner_HTML=>$pathname});
      my $map = $box->append_child('ul');
      foreach $subdir (@{$cfg->{$pathname}->{'images'}}){
        opendir(my $dh, $cfg->{$pathname}->{'root'} . "/$subdir");
        my @files = map { $_ !~ /^./ || [] } readdir($dh);
        close(DH);
        my $url = $hub->url({type=>'ModalDocuments',action=>'Images',pathname=>$pathname,subdir=>$subdir});
        $map->append_child('li',{inner_HTML=>sprintf('%s: %s files',$subdir,scalar @files)});
      }
    }
    $content = $message->render;
  }
  return $content;
}

sub detail_view {
  my ($self,$pathname,$subdir,$filename)=@_;
  my $root      = $SiteDefs::CONTENT_CONFIG->{$pathname}->{'root'};
  my $localpath = "$subdir/$filename";
  my $fullpath  = "$root/$localpath";
  my $sandbox   = $root;
  $sandbox      =~ s/^$SiteDefs::ENSEMBL_SERVERROOT//;
  my $info      = $self->object->cvs('action'=>'info','file'=>$fullpath);
  my $status    = $info->success ? $info->status : $info->error;
  my $rev       = $info->repository_revision if $info->success;
  my $sticky    = $info->sticky_tag if $info->success;
  my $cvsurl    = $self->object->viewcvs_url($pathname,$subdir,$filename);

  my $content   = $self->dom->create_element('div',{class=>"tinted-box"});
  $content->append_child('h3',{inner_HTML=>$filename});
###Delete button
  my $form = $self->modal_form('delete', $self->hub->url({function=>'Images',action=>'Delete'}),{label=> 'Delete'});
  $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  $form->add_element( type => 'Hidden', name => 'subdir', value=> $subdir);
  $form->add_element( type => 'Hidden', name => 'file', value=> $filename);
  $content->append_child('p',{inner_HTML=>$form->render});
###/Delete button
  my $details   = $content->append_child('dl');
  $details->append_child('dt',{inner_HTML=>'source'});
  $details->append_child('dd',{inner_HTML=>sprintf(qq[<a href="$cvsurl" target="_blank">$sandbox/$localpath</a>])});
  $details->append_child('dt',{inner_HTML=>'status'});
  $details->append_child('dd',{inner_HTML=>$status});
  $details->append_child('dt',{inner_HTML=>'revision'});
  $details->append_child('dd',{inner_HTML=>$rev});
  $details->append_child('dt',{inner_HTML=>'branch'});
  $details->append_child('dd',{inner_HTML=>$sticky || "-"});

  $content->append_child('hr');
  $content->append_child('div',{style=>'overflow:scroll;'})->append_child('a',{target=>'_blank',href=>"/$localpath"})->append_child('img',{src=>"/$localpath"});

  my $commit_form = $self->cvs_form('commit','Commit');
  my $update_form = $self->cvs_form('update','Load');

  my $wrapper = sprintf(qq{
<div class="column-wrapper js_panel">
  <div class="column-two js_panel"><div class="column-padding no-left-margin js_panel">
    %s
  </div></div>
  <div id="Configuration" class="column-two js_panel"><div class="column-padding no-right-margin js_panel">
    <div class="tinted-box no-top-margin js_panel">
      <h3>Load revision</h3>
    %s
    </div>
    <div class="tinted-box no-top-margin js_panel">
      <h3>CVS Commit</h3>
    %s
    </div>
  </div></div>
</div>},$content->render,$update_form,$commit_form);
  return $wrapper;
}

sub upload_form {
  my ($self,$pathname,$subdir) = @_;
  my $hub = $self->hub;
  my $url = $hub->url({action=>'Upload'});
  my $form = $self->modal_form('upload', $url,{label=> 'Upload',class=>'_eg_upload_form'});
  $form->add_fieldset("Upload to $pathname/$subdir","_eg_upload_form");
  $form->add_element(type => 'File', name => 'file', label => 'Upload file');
  $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  $form->add_element( type => 'Hidden', name => 'subdir', value=> $subdir);
  my $content = $form->render();
  return  $content;
}

sub images_table{
  my ($self,$pathname,$subdir) = @_;
  my $hub = $self->hub;
  my $object = $self->object;
  $pathname ||= $object->pathname;
  my $filename= $object->filename;
  my $content = qq{<div class="notes"><p>Use the Image URL below to insert an image in your web document</p></div>};
  my @table_rows = ();
  my $plugin_images = $object->get_images($pathname,$subdir);
  my %completed;
  foreach my $subdir (keys %{$plugin_images}){
    my $img_pathname = "$pathname/$subdir";
    foreach my $image_file(@{$plugin_images->{$subdir}}){
     #my $form = $self->modal_form('delete', $hub->url({function=>'Images',action=>'Delete'}),{label=> 'Delete'});
     #$form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
     #$form->add_element( type => 'Hidden', name => 'subdir', value=> $subdir);
     #$form->add_element( type => 'Hidden', name => 'file', value=> $image_file);

      my $image_path = "/$subdir/$image_file";
      push(@table_rows,
        {filename=>qq(<input type="text" class="click_highlight" size="60" value="$image_path"),
        #image=> qq(<a href="$image_path" target="_blank">$image_file</a>),
         image=> sprintf(qq{<a class="constant modal_link" href="%s">Details</a>},$hub->url({pathname=>$pathname,subdir=>$subdir,f=>$image_file})),
        #form=>$form->render
        }
      );
    }
  }
  my $table = new EnsEMBL::Web::Document::Table([
    { key=>'filename',  title=>'Image URL', align => 'left',  width=>'45%' },
    { key=>'image',     title=>'',   align => 'left', width=>'45%' }, 
   #{ key=>'form',  title=>'', align => 'right',  width=>'15%' },
    ],
    \@table_rows,
    {}
  );
  if(! @table_rows){
    return '';
  }
  $content .= qq{<h3>$pathname Images</h3>\n} . $table->render;
  return $content;
}
1;


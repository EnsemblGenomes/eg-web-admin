package EnsEMBL::Admin::Component::Documents;

use POSIX qw/strftime/;
use Cwd;
use Template;
use EnsEMBL::Web::Controller::SSI;

use base qw/EnsEMBL::Web::Component/;

sub _init {
  my $self = shift;
  $self->cacheable( 0 );
  $self->ajaxable(  0 );
  $self->configurable( 0 );
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $pathname = $hub->function;
  my $file_title = $hub->param('f');
  my $action = $hub->action;
  if($action && $file_title){
    $object->open($pathname,$file_title,$action);
  }
  return;
}

sub tool_buttons {
  my ($self)=@_;
  my $pathname = $self->hub->function;
  my $hub = $self->hub;
  my $tools = $self->dom->create_element('div',{class=>'other_tool'});
  $tools->append_child('a', {'class' => 'modal_link data ', 'href' => $hub->url({'type'=>'ModalDocuments','function'=>$pathname}), 'inner_HTML' => 'Document Tools'});
  return $tools->render;
}

sub md_open {
  my ($self)=@_;
  my $object  = $self->object;
  my $hub = $self->hub;
  my $pathname  = $object->{_md_data}->{'pathname'} = $hub->param('pathname') || $hub->function;
  my $filename      = $object->{_md_data}->{'filename'} = $hub->param('f') || $hub->param('filename');
  my $subdir    = $object->{_md_data}->{'subdir'} = $hub->param('subdir') || $pathname;
  $subdir =~ s/^[^_]*_// unless $hub->param('subdir');
  $subdir =~ s/_/\//g unless $hub->param('subdir');
  $subdir = "" if ($subdir =~ /^root$/i);
  $pathname =~ s/^([^_]+)_.*$/\1/ unless $hub->param('pathname');
  my $root      = $SiteDefs::CONTENT_CONFIG->{$pathname}->{'root'};
  my $localpath = "$subdir/$filename";
  my $fullpath  = "$root/$localpath";
  my $sandbox   = $root;
  $sandbox      =~ s/^$SiteDefs::ENSEMBL_SERVERROOT//;
  $object->{_md_data}->{'sandbox'} = $sandbox;
  my $info      = $object->{_md_data}->{'cvs_status'} = $self->object->cvs('action'=>'info','file'=>$fullpath);
}

sub doc_select_box {
  my ($self) = @_;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my @options = ('<option value="/common/Documents/">-- Select File --</option>');
  my $available_docs  = $object->available_documents;
  while (my ($title, $file) = splice @$available_docs, 0, 2) {
    push(@options,sprintf('<option value="%s">%s</option>', $file, $title));
  }
  my $configs = $SiteDefs::CONTENT_CONFIG;
  foreach my $plugin(sort keys %$configs){
    my $cfg=$SiteDefs::CONTENT_CONFIG->{$plugin};
    my $root = $cfg->{'root'};
    for my $branch (@{$cfg->{'htdocs'}}){
      my $path = "";
      if(exists $cfg->{$branch}){
        $path = $cfg->{$branch}; # absolute path give in config
      }
      else{
        $path = "$root/$branch";
      }
      opendir(my $dh, "$path" ) or warn "cannot open $path" && next;
      my @files = grep { /^[^.]/ &! /^stats_/ &! /png$|jpg$|gif$|ico$|lock$/i && -f "$path/$_" } readdir($dh);
      closedir $dh;
      my $pathname = sprintf("%s/%s",$plugin,$branch);
      $pathname =~ s/\//_/g;
      push(@options,qq( <optgroup label="$pathname">));
      push(@options,
        map{
          sprintf(qq{<option value="%s">%s</option>},
            $hub->url({type=>'Documents',action=>'View',function=>$pathname,f=>$_}),
            $_
          )
        } @files
      );
      push(@options,qq( </optgroup>));
    }
  }
  return sprintf(qq[
<div class='_eg_upload_form panel_js'>
  <fieldset>
    <h2>View Document</h2>
    <div class="static_all_species">
      <form action="#">
        <div>
          <select name="species" class="dropdown_redirect">%s
          </select>
        </div>
      </form>
    </div>
  </fieldset>
</div>],join('\n',@options));
}

sub _view_content {
  my $self    = shift;
  my $object  = $self->object;
  my $pathname = $self->hub->function;
  my $action = $self->hub->action;
  return $self->_process_tt2() if($object->filename =~ /\.tt2$/);
## Try to get this working: process pages with INCLUDE and SCRIPT bits
 #return EnsEMBL::Web::Controller::SSI::template_INCLUDE(undef,
 #  $object->local_uri) if($pathname && $action && $object->path);
  return $object->content if($pathname && $action && $object->path);
  return sprintf('<h2>Document not found</h2><p>There was no document found corresponding to <b>%s</b></p>', $pathname) if $pathname; 
}

sub _process_tt2 {
  my $self = shift;
  my $object  = $self->object;
  my $cfg = $object->{'_config'};
  my @paths = map { $cfg->{'root'} . "/" . $_ } @{ $cfg->{'htdocs'} };
  my $tpl = Template->new({INCLUDE_PATH=>\@paths,ABSOLUTE=>1}); 
  my $content="";
  $tpl->process($object->filename,{},\$content) or warn $tpl->error();
  if(!$content){#fall back to raw content
    $content = $object->content;
  }
  return $content;
} 

sub _commit_form{
  my $self       = shift;
  my $hub        = $self->hub;
  my $action     = $hub->action;
  my $object     = $self->object;
  my $pathname   = $object->pathname;
  my $filename   = $object->filename;
  $self->md_open() unless exists $self->object->{_md_data};
  my $cfg = $self->object->{_md_data};
  my $cvs_status = $cfg->{'cvs_status'};
  my $status     = $object->cvs(action=>'status');
  my $sticky_tag = $object->{'sticky_tag'};
  my $datetime   = strftime("%D %T",localtime);
  my $viewcvs = $object->viewcvs_url($pathname,$filename);
  my $url = $hub->url({type=>'Documents',action=>'Edit',function=>$pathname,f=>$filename});
  my $form = $self->modal_form('preview', $url,{class => 'two_col_form', no_button=>1, id=>'cvs_form_id'});
  $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  $form->add_element( type => 'Hidden', name => 'filename', value=> $filename);
  $form->add_element( type => 'String', size=>'128',name => 'comment', label=>'Comment',value=>"Updated $datetime" );
  $form->add_element( type => 'String', size=>'128',name => 'username', label=>'CVS User',value=>"" );
  $form->add_element( type => 'Password', size=>'128',name => 'password', label=>'CVS Password',value=>"" );
  $form->add_element( type =>'Dropdown', name=>'action', value=>'Commit', label=>'CVS Action', values=>[
    {value=>'commit',caption=>'Commit'},
    {value=>'update',caption=>'Update'},
    ],
  selected=>'Commit', caption=>'CVS command');
###### new dropdown selector
  my @rev_options = ({value=>'HEAD',caption=>'HEAD',selected=>1});
  my @tags = reverse grep {! /branchpoint$/i } $cvs_status->tags;
  for my $tag (reverse @tags){
    my $tagrev = $cvs_status->tag_revision($tag);
    push (@rev_options,{value=>$tag,caption=>"$tag ($tagrev)",checked=>0});
  }
  $form->add_element(type=>'Dropdown',name=>'tag_2',class=>'dropdown_select_tag',label=>'Target','values'=> \@rev_options, notes=>'Select target branch, or manually enter a revision number below');
######
# my $revisions = $self->dom->create_element('div');
# $revisions->append_child('a',{class=>'toggle closed',href=>'#',rel=>'tags_table',inner_HTML=>'Update to a specific revision number or tag (leave blank to update to the latest trunk revision'});
# my $revtable = $revisions->append_child('table',{id=>'tags_table',class=>'toggleable',style=>'display:none'});
# $revtable->append_child('tr')->append_child('th',{inner_HTML=>'click to select:'});
# map {$revtable->append_child('tr')->append_child('td')->append_child('span',{class=>'click_update_tag', inner_HTML=>$_})}  @{$object->{'tags'}};

  $form->add_element( type => 'String', size=>'128',name => 'tag',class=>'_tag', label=>'Revision',value=>"",
    # notes=>scalar @{$object->{'tags'}} ? $revisions->render : ''
   );
  $form->add_element( type => 'Checklist', name => 'cvs_options',label=>'Options', 'values'=>[
    {caption=>'Overwrite local file if modified (for Update)',value=>'overwrite', checked=>0},
  ]);

  $form->add_element( type => 'Submit', name => 'submit', value=>"Execute" );

  my $note=$form->append_child('div',{class=>"info"});
  $note->append_child('h3',{'inner_HTML'=>"Committing changes to CVS"});

  my $content = $self->dom->create_element('div', {'class' => 'content'});

  $note->append_child('p',{inner_HTML=>qq[The complete CVS log is available here: <a href="$viewcvs" target="_blank">ViewCVS Log</a>],'style'=>{'margin'=>'2em 1em'},});

  $note->append_child('p',{inner_HTML=>$status,'style'=>{'margin'=>'2em 1em','font-weight'=>'bold'}});
  my $legend = $note->append_child('ul');
  $legend->append_child('li',{inner_HTML=>"<em>Up-to-date</em>: no commit needed"});
  $legend->append_child('li',{inner_HTML=>"<em>Locally Modified</em>: changed, not yet committed"});
  $legend->append_child('li',{inner_HTML=>"<em>Unknown</em>: new file, not yet committed"});
  

  return $form->render . $content->render;
}

sub _edit_form {
  my $self    = shift;
  my $hub     = $self->hub;
  my $action = $hub->action;
  my $object  = $self->object;
  my $pathname= $object->pathname;
  my $filename= $object->filename;
  my $content = $object->content;
  my $locktype = 'Lock';
  my $status = $object->lock('status');
  if($status){
    if($status eq $hub->user->{'email'}){#I am the locker
      $hub->session->add_data(
        type => 'message',
        function => '_info',
        code => 'locked',
        message => "You ($status) have LOCKED $pathname/$file"
      );
      $locktype = 'Unlock';
    }
    else { # I am not the locker
      $hub->session->add_data(
        type => 'message',
        function => '_error',
        code => 'locked',
        message => "$pathname/$filename has been LOCKED by $status"
      );
      $locktype = "Steal";
    }
  }

### Lock button
  my $lock_url = $hub->url({type=>'Documents',action=>'Lock',function=>$pathname,f=>$filename});
  my $lockform = $self->modal_form('lock', $lock_url,{label=> $locktype, 'no_button'=>1});
  $lockform->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  $lockform->add_element( type => 'Hidden', name => 'filename', value=> $filename);
  $lockform->add_element( type => 'Hidden', name => 'locktype', value=> $locktype);
  $lockform->add_element( type => 'Submit', name => 'submit', value=> $locktype,label=>'Lock/Unlock file for editing', notes=> $locktype=~/^steal$/i ? "Replace lock created by $status":undef );
  if($locktype =~ /^steal$/i){return $lockform->render;}
###
  else{
    my $url = $hub->url({type=>'Documents',action=>'Edit',function=>$pathname,f=>$filename});
    my $form = $self->modal_form('edit', $url,{class => "_eg_tinymce",'no_button'=>1, id=>'eg_tinymce_edit_field'});
    $form->add_element( type => 'Text', name => 'text',id=>'_document_edit_tab',class=>'_eg_tinymce', value=>$content, autocomplete=>'off' );
    $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
    $form->add_element( type => 'Hidden', name => 'filename', value=> $filename);
    $form->add_element( type => 'Hidden', name => 'action', value=> $action );
    $form->add_element( type => 'Reset', name => 'reset', value=> 'Reset',label=>'Reset the editor, reload the file', class=>'click_to_reset',notes=>"The editor may display your browser's cache of your last entry. Click <em>Restore</em> to reload the file in the editor." );
    $form->add_element( type => 'Submit', name => 'submit', value=> 'Save',label=>'Save changes to disk' );
    return $lockform->render . $form->render;
  }
}

sub _upload_form {
  my ($self,$options) = @_;
  my $hub = $self->hub;
  my $object  = $self->object;
  my $action = $self->hub->action;
  my $pathname= $object->pathname;
  my $filename= $object->filename;
  my $url = $hub->url({action=>'Upload'});
  my $form = $self->modal_form('upload', $url,{label=> 'Upload',target=>'_top',class=>'_eg_upload_form'});
  $form->add_fieldset("New Image","_eg_upload_form");
  $form->add_element( type => 'File', name => 'file', label => 'Upload file' );
  if($options){#provide a selector for the destination
    my ($default_plugin) = @{$object->uploadable_plugins};
    $form->add_element( type => 'radiolist', name => 'pathname',label=>'Destination', values=> $self->_plugin_option_list('images'), value=>$default_plugin, class=>'_eg_upload_form' );
  }
  else{
    $form->add_element( type => 'Hidden', name => 'pathname', value=> $pathname);
  }
  $form->add_element( type => 'Hidden', name => 'load_pathname', value=> $pathname);
  $form->add_element( type => 'Hidden', name => 'filename', value=> $filename);
  $form->add_element( type => 'Hidden', name => 'action', value=> $action );
  $form->force_reload_on_submit($hub->url({action=>'View',function=>$pathname,f=>$filename}));
  my $content = $form->render({'target'=>'_self'});
  $content =~ s/target="[^"]+/target="_self"/;
  return  $content;
}

sub _plugin_option_list{
  my ($self,$type) = @_;
  my @options = ();
  my $plugins = $SiteDefs::CONTENT_CONFIG;
  for my $plugin(keys %$plugins){
    my $cfg = $plugins->{$plugin};
    for my $path ( @{$cfg->{$type}} ){
      my $pathname = sprintf("%s/%s",$plugin,$path);
      $pathname =~ s/\//_/g;
      push(@options,{value=>$pathname,caption=>sprintf("%s/%s",$plugin,$path)}) if (-d sprintf("%s/%s",$cfg->{'root'},$path));
    }
  }
  my @sorted = sort @options;
  return \@sorted;
}

  

sub _new_doc_form{
  my $self    = shift;
  my $hub     = $self->hub;
  my $action = $hub->action;
  my $object  = $self->object;
  my $pathname= $object->pathname;
  my $filename= $object->filename;
  my ($default_plugin) = keys %{$object->available_plugins};

  my $url = $hub->url({type=>'Documents',action=>'Edit',function=>$pathname,f=>$filename});
  my $form = $self->modal_form('preview', $url,{class => "_eg_upload_form", label=> 'Create' });
  $form->add_fieldset("New Document","_eg_upload_form");
  $form->add_element( type => 'String', name => 'filename',label=>'Filename (use extensions .html or .inc)');
  $form->add_element( type => 'radiolist', name => 'pathname',label=>'Destination', values=> $self->_plugin_option_list('htdocs'),value=>$default_plugin, class=>'_eg_upload_form' );
  $form->add_element( type => 'Hidden', name => 'action', value=> 'View' );

  return sprintf('%s', $form->render);

}
  


sub _images_table{
  my ($self,$pathname,$imgdir) = @_;
  my $hub = $self->hub;
  my $object = $self->object;
  $pathname ||= $object->pathname;
  my $filename= $object->filename;
  my $content = qq{<div class="notes"><p>Use the Image URL below to insert an image in your web document</p></div>};
  my @table_rows = ();
  my $plugin_images = $object->get_images($pathname,$imgdir);
  my %completed;
  foreach my $image_dir (keys %{$plugin_images}){
    my $img_pathname = "$pathname/$image_dir";
    $img_pathname =~ s/\//_/g;
   #my $viewcvs = $object->viewcvs_url($img_pathname);
    foreach my $image_file(@{$plugin_images->{$image_dir}}){
### OK to reuse $object to get cvs status for image files
#     $object->open($img_pathname,$image_file);
#     my $cvs_status = $object->cvs('action'=>'status');
###
      my $image_path = "/$image_dir/$image_file";
      my $form = $self->modal_form('delete', $hub->url({action=>'Delete'}),{label=> 'Delete'});
      $form->add_element( type => 'Hidden', name => 'pathname', value=> $img_pathname);
      $form->add_element( type => 'Hidden', name => 'load_pathname', value=> $pathname);
      $form->add_element( type => 'Hidden', name => 'filename', value=> $filename);
      $form->add_element( type => 'Hidden', name => 'file', value=> $image_file);
      push(@table_rows,
        {filename=>qq(<input type="text" class="click_highlight" size="60" value="$image_path"),
         image=> qq(<a href="$image_path" target="_blank">$image_file</a>),
    #    status=> $cvs_status,
         form=>$form->render
        }
      );
    }
  }
  my $table = new EnsEMBL::Web::Document::Table([
    { key=>'filename',  title=>'Image URL', align => 'left',  width=>'45%' },
    { key=>'image',     title=>'click to view full size',   align => 'left', width=>'45%' }, 
   #{ key=>'status',    title=>'Status'},
    { key=>'form',  title=>'', align => 'right',  width=>'15%' },
    ],
    \@table_rows,
    {}
  );
  if(! @table_rows){
    return '';
  }
  $pathname =~ s/_.*$//;
 #$content .= qq{<h3>$pathname Images</h3> <a href="$viewcvs" target="_blank">ViewCVS Log</a>\n} . $table->render;
  $content .= qq{<h3>$pathname Images</h3>\n} . $table->render;
  return $content;
}

1;

package EnsEMBL::Admin::Component::Documents::View;

use strict;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption {
  return '';
}

sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $html = $self->doc_select_box;
  my $content = $self->dom->create_element('div', {'class' => '_tabselector'});
  my $buttons = $content->append_child('div', {'class' => 'ts-buttons-wrap'});
  my $tabs    = $content->append_child('div', {'class' => 'spinner ts-spinner _ts_loading'});
  $self->md_open() unless exists $object->{_md_data};
  my $editable = 1;
  my $cvs_status = $object->{_md_data}->{cvs_status};
  if($cvs_status->success && $cvs_status->status =~ /needs\s*patch/i){
    $editable = 0;
    my $note=$self->dom->create_element('div',{class=>"error"});
    $note->append_child('h3',{'inner_HTML'=>"Editing disabled: file out of date"});
    $note->append_child('div',{class=>'message-pad',inner_HTML=>'Please UPDATE from CVS before editing'});
    $html .= $note->render;
  }
      
  $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#view", 'inner_HTML' => 'Current Version'});
  $tabs->append_child('div', {id=>'_document_view_tab','class' => '_ts_tab ts_tab ts-spinner eg_tab', 'inner_HTML'  => $self->_view_content }); 
  if($editable){
    $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#edit", 'inner_HTML' => 'Edit'});
    $tabs->append_child('div', {'class' => '_ts_tab ts_tab edit ts-spinner eg_tab', 'inner_HTML'  => $self->_edit_form }); 
  }
  $buttons->append_child('a', {'class' => '_ts_button ts-button', 'href' => "#cvs", 'inner_HTML' => 'CVS'});
  $tabs->append_child('div', {id=>'_document_cvs_tab','class' => '_ts_tab ts_tab ts-spinner eg_tab', 'inner_HTML'  => $self->_commit_form }); 

  my $revision_note = sprintf('Editing %s',$object->{'sticky_tag'} ? 'Release revision ' . $object->{'sticky_tag'} : 'trunk revision'); 
  $content->prepend_child('div',{class=>'warning'})->append_child('p',{inner_HTML=>$revision_note,style=>'font-weight:bold;'}) if($object->{'sticky_tag'});

  $html .= $self->tool_buttons . $content->render;
  return $html;
}

1;


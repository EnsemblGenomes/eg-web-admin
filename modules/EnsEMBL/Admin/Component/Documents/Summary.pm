package EnsEMBL::Admin::Component::Documents::Summary;

use strict;
use Data::Dumper;

use base qw(EnsEMBL::Admin::Component::Documents);

sub caption {
  return '';
}


sub content {
  my $self    = shift;
  my $object  = $self->object;
  my $hub     = $self->hub;
  my $content = '';
  $content .= $self->doc_select_box;
  $content .= $self->_new_doc_form;
  my $tools = $self->dom->create_element('div',{class=>'other_tool'});
  $tools->append_child('a', {'class' => 'modal_link data ', 'href' => "/ModalDocuments", 'inner_HTML' => 'Document Tools'});
  $content .= $tools->render;
  return $content;
}

1;


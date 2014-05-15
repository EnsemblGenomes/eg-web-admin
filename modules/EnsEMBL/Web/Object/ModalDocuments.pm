package EnsEMBL::Web::Object::ModalDocuments;

use base qw(EnsEMBL::Web::Object::Documents);

sub viewcvs_url {
  my ($self,$pathname,$subdir,$filename)=@_;
  my $cfg = $self->get_config($pathname);
  my $localpath = sprintf("%s/%s",$cfg->{'root'},$subdir);
  $localpath .= "/$filename" if $filename;
  $localpath =~ s/$SiteDefs::ENSEMBL_SERVERROOT\///;
  return sprintf("http://cvs.sanger.ac.uk/cgi-bin/viewvc.cgi/%s?root=ensembl",$localpath,$filename);
}

1;


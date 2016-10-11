package EnsEMBL::EGAdmin::SiteDefs;
use strict;


sub update_conf {   
  $SiteDefs::ENSEMBL_BLAST_ENABLED = 0;
  $SiteDefs::ENSEMBL_MART_ENABLED = 0;
  $SiteDefs::ENSEMBL_WEBADMIN_HEALTHCHECK_FIRST_RELEASE = 60;
}

1;

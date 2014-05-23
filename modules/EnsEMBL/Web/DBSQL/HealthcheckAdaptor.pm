package EnsEMBL::Web::DBSQL::HealthcheckAdaptor;

### A simple adaptor to fetch news and help from the ensembl_website database
### For full CRUD functionality, see public-plugins/orm, which uses the Rose::DB::Object
### ORM framework

use strict;
use warnings;
no warnings 'uninitialized';

use DBI;

sub new {
  my ($class, $hub) = @_;

    my $self = {
    'NAME' => $hub->species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'NAME'},
    'HOST' => $hub->species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'HOST'},
    'PORT' => $hub->species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'PORT'},
    'USER' => $hub->species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'USER'},
    'PASS' => $hub->species_defs->multidb->{'DATABASE_HEALTHCHECK'}{'PASS'},
  };
  bless $self, $class;
  return $self;
}

sub db {
  my $self = shift;
  return unless $self->{'NAME'};
  $self->{'dbh'} ||= DBI->connect(
      "DBI:mysql:database=$self->{'NAME'};host=$self->{'HOST'};port=$self->{'PORT'}",
      $self->{'USER'}, "$self->{'PASS'}"
  );
  return $self->{'dbh'};
}

sub is_running {
  my $self = shift;
  my $locked = $self->db->selectrow_array("SHOW TABLES LIKE 'hc_lock'");
  return !!$locked;
}

1;

package EnsEMBL::Web::Document::HTML::SpeciesList;

## Alternative species listing style, that can show multiple links per species

use strict;

sub render {
  my $self         = shift;
  my $species_defs = $self->species_defs;
  my @species      = $self->_species_by_dataset;
  my $healthchecks = $species_defs->databases->{'DATABASE_HEALTHCHECK'};
  my $html;
  
  # EG
  my $staging_site = 'http://test.' . $species_defs->GENOMIC_UNIT . '.ensembl.org';

  if ($healthchecks) {
    $html = qq(
<h2>Healthchecks</h2>
<ul>
  <li><a href="/Healthcheck/Summary">Healthcheck summary</a></li>
  <li><a href="/Healthcheck/DBList">List of databases</a></li>
</ul>
);
  }

  $html .= qq(<h3>Species</h3>
<table style="width:100%">
  <tr>
  );

  my $columns = 2;
  my $column_width = int((100 / $columns) - 8);
  my $total = @species;
  my $break = int($total / $columns);
  $break++ if $total % $columns;
  ## Reset total to number of cells required for a complete table
  $total = $break * $columns;
  if(400 < $total){
    $html .= sprintf('<td>%s species - table omitted</td>', $total);
    $total = 0;
  }
  
  my $row = -1;
  for (my $i=0; $i < $total; $i++) {
    my $col = int($i % $columns);
    if ($col == 0 && $i < $total - 1) {
       $html .= qq(</tr>\n<tr>);
    }
    $row++ if $col == 0;
    my $j = $row + $break * $col;
    
    
    my $dir = $species[$j]->{name};
    (my $name = $species[$j]->{name}) =~ s/_/ /g;
    my $thumb = $species[$j]->{dataset};

    $html .= qq(<td style="width:8%;text-align:right;padding-bottom:1em">);
    if ($dir) {
      $html .= qq(<img src="/i/species/48/$thumb.png" alt="$name" width="48" height="48">);
    }
    else {
      $html .= '&nbsp;';
    }
    $html .= qq(</td>\n<td style="width:$column_width%;padding:2px;padding-bottom:1em">);
    if ($dir) {
      if ($healthchecks) {
        $html .= qq(<span style="font-weight:bold;font-size:1.1em">$name</span><br /><a href="/$dir/Healthcheck/Details/Species">Healthcheck</a> 
          | <a href="${staging_site}/$dir/">View on staging</a>);
      }
      else {
        $html .= qq(<a href="/$dir/" style="font-weight:bold;font-size:1.1em;text-decoration:none">$name</a>);
      }
    }
    else {
      $html .= '&nbsp;';
    }
    $html .= '</td>';
  }

  $html .= qq(
</tr>
</table>);
  
  return $html;
}

sub _species_by_dataset {
  my ($self) = @_;
  my $species_defs = $self->species_defs;
  my @species;
  foreach my $dataset (@{$species_defs->ENSEMBL_DATASETS}) {
    foreach (sort @{$species_defs->get_config($dataset, 'DB_SPECIES')}) {
      push(@species, {name => $_, dataset => $dataset});
    }
  }
  return @species;
}

1;

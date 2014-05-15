package EnsEMBL::Web::Document::Element::Logo;

use strict;

sub site_menu {
  return q{
    <span class="print_hide">
      <span id="site_menu_button">&#9660;</span>
      <ul id="site_menu" style="display:none">
        <li><a href="http://admin.bacteria.ensembl.org">Ensembl Bacteria Admin</a></li>
        <li><a href="http://admin.protists.ensembl.org">Ensembl Protists Admin</a></li>
        <li><a href="http://admin.fungi.ensembl.org">Ensembl Fungi Admin</a></li>
        <li><a href="http://admin.plants.ensembl.org">Ensembl Plants Admin</a></li>
        <li><a href="http://admin.metazoa.ensembl.org">Ensembl Metazoa Admin</a></li>
        <li><a href="http://admin.ensembl.org">Ensembl Vertebrates Admin</a></li>
      </ul>
    </span>
  };
}

1;

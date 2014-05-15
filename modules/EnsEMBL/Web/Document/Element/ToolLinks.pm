# $Id: ToolLinks.pm,v 1.1 2011-02-16 11:03:34 nl2 Exp $

package EnsEMBL::Web::Document::Element::ToolLinks;

### Generates links to site tools - BLAST, help, login, etc (currently in masthead)

use strict;

use base qw(EnsEMBL::Web::Document::Element);

sub content {
  return '<ul class="tools"><li class="last"><a class="constant" href="/info/">Help &amp; Documentation</a></li></ul>'
}

1;

package Judge::View::HTML;

use strict;
use warnings;
use utf8;

use base 'Catalyst::View::Xslate';

__PACKAGE__->config(
  encoding => undef,
  template_extension => '.tx',
  encode_body => 0
);

1;


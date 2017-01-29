package Judge;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime;

# -Debug
use Catalyst qw/
  ConfigLoader
  Redirect
  Static::Simple
  Session
  Session::State::Cookie
  Session::Store::FastMmap
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
  name => 'Judge',
  encoding => 'UTF-8',
  default_view => 'HTML',
  disable_component_resolution_regex_fallback => 1,
  'Plugin::Static::Simple' => {
    ignore_extensions => [qw(asp php)],
  },
);

__PACKAGE__->setup();

1;

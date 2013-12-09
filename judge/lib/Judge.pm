package Judge;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

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
  disable_component_resolution_regex_fallback => 1,
);

__PACKAGE__->setup();

1;

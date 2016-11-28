package Judge::Controller::Root;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config(namespace => '');

use Settings;
use User;

sub index :Path :Args(0) {
  my ($self, $c) = @_;

  # Is our user signed in?
  my $user = User::get($c);

  $c->stash(
    user => $user,
  );
}

sub default :Path {
  my ($self, $c) = @_;

  $c->stash(
    template => '404.tx',
    title => 'Not Found',
  );
   $c->response->status(404);
}

sub end
  :ActionClass('RenderView') {
}

__PACKAGE__->meta->make_immutable;

1;

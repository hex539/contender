package Judge::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config(namespace => '');

use Settings;

sub index :Path :Args(0) {
  my ($self, $c) = @_;
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

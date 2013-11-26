package Judge::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
__PACKAGE__->config(namespace => '');

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->redirect($c->uri_for('/contest/11/problems'));
}

sub end
  :ActionClass('RenderView') {
}

__PACKAGE__->meta->make_immutable;

1;

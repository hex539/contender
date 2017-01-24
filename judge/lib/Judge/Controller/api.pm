package Judge::Controller::api;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

use Database;
use Judge::Model::User;
use JSON;

BEGIN { extends 'Catalyst::Controller::REST'; }

sub api_root
  :Chained("/")
  :PathPart("api")
  :Args(0) {
  my ($self, $c) = @_;
  Judge::Model::User::force($c);

  $self->status_ok(
    $c,
    entity => {
      endpoints => ['affiliations'],
    },
  );
}

sub affiliations : Local : ActionClass('REST') {}
sub affiliations_GET
   :Chained("/api")
   :PathPart("affiliations")
   :Args(0) {

  my ($self, $c) = @_;

  $self->status_ok(
    $c,
    entity => [{
      affilid => 1,
      shortname => 'Bath',
      name => 'University of Bath',
      country => 'GBR',
    }],
  );
}

sub teams : Local : ActionClass('REST') {}
sub teams_GET
    :Chained("/api")
    :PathPart("teams")
    :Args(0) {
  my ($self, $c) = @_;

  my @teams = (
    {
      id => 555,
      name => 'Test Team',
    },
  );

  $self->status_ok(
    $c,
    entity => \@teams,
  );
}

sub scoreboard : Local : ActionClass('REST') {}
sub scoreboard_GET
    :Chained("/api")
    :PathPart("scoreboard")
    :Args(0) {
  my ($self, $c) = @_;
  my $contest_id = 1;

  my @rows = ();
  push @rows, {
    rank => 1,
    team => 555,
    score => {
      num_solved => 7,
      total_time => 1157,
    },
    problems => [
      {
        label => "A",
        num_judged => 1,
        num_pending => 0,
        solved => JSON::true,
        time => 33,
      }
    ],
  };

  $self->status_ok(
    $c,
    entity => \@rows,
  );
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(default => 'application/json');

1;

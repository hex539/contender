package Judge::Controller::api;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

use Database;
use Judge::Model::User;
use Judge::Model::Scoreboard;
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

sub contest : Local : ActionClass('REST') {}
sub contest_GET
    :Chained("/api")
    :PathPart("contest")
    :Args(0) {
  my ($self, $c) = @_;

  my $contest = db->resultset('contests')->find({
    visible => 1,
  });
  if (not defined $contest) {
    $self->status_no_content;
    return;
  }

  $self->status_ok(
    $c,
    entity => {
      id => $contest->id,
      shortname => $contest->shortname,
      name => $contest->name,
      start => $contest->start_time,
      length => ($contest->window_duration // $contest->duration),
      penalty => $contest->penalty,
    },
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

  my $user = Judge::Model::User::get($c) // die 'no user';
  my $contest = db->resultset('contests')->find({
    visible => 1,
   }) // die 'no contest';

  my $scoreboard = Judge::Model::Scoreboard->new(
    contest => $contest,
    user => $user
  ) // die 'no scoreboard';

  my $problems = $scoreboard->problems;

  my @rows = ();
  my $rank = 0;
  for my $row (@{$scoreboard->scoreboard_rows}) {
    $rank++;

    push @rows, {
      rank => $rank,
      team => $row->{user}->id,
      score => {
        num_solved => $row->{score},
        total_time => $row->{penalty},
      },
      problems => [
        map {{
          label => $_->shortname,
          num_judged => $row->{$_->id}->{attempts},
          num_pending => 0,
          solved => ($row->{$_->id}->{solved} ? JSON::true : JSON::false),
          time => ($row->{$_->id}->{solved} && $row->{$_->id}->{when}),
        }} @{$problems},
      ],
    };
  }

  $self->status_ok(
    $c,
    entity => \@rows,
  );
}

__PACKAGE__->meta->make_immutable;
__PACKAGE__->config(default => 'application/json');

1;

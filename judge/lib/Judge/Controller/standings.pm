package Judge::Controller::standings;
use Moose;
use namespace::autoclean;

use Database;
use Judge::Model::Scoreboard;
use Judge::Model::User;
use Text::Markdown qw(markdown);
use File::Basename;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub standings
  :Chained("/contest/index")
  :PathPart("standings")
  :Args(0) {

  my ($self, $c) = @_;

  my $contest = $c->stash->{contest};
  my $user = Judge::Model::User::get($c);

  my $scoreboard = Judge::Model::Scoreboard->new(
    user => $user,
    contest => $contest,
  );

  $c->stash(
    template => 'standings.tx',
    title => 'Standings',
    tab => 'Standings',

    problems => $scoreboard->problems,
    rankings => $scoreboard->scoreboard_rows,
    attempts => $scoreboard->problem_attempts,
  );
}

__PACKAGE__->meta->make_immutable;

1;

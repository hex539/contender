package Judge::Controller::edit_problem;
use Moose;
use namespace::autoclean;

use File::Slurp;
use Database;
use User;
use Problem;
use HTML::Defang;
use Text::Markdown qw(markdown);
use File::Spec::Functions;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

my $judgeroot = '/home/judge/data';

sub edit_problem
  :Chained("/problem/problem")
  :PathPart("edit")
  :Args(0) {

  my ($self, $c) = @_;

  my $user = User::force($c);
  $c->detach('/default') unless $user->administrator;

  my $problem = $c->stash->{problem};
  my $id = $problem->id;

  $c->stash(
    template => 'edit_problem.tx',
  );
}

__PACKAGE__->meta->make_immutable;

1;

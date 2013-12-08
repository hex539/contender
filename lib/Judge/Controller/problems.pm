package Judge::Controller::problems;
use Moose;
use namespace::autoclean;

use Database;
use User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

my $judgeroot = '/home/judge/data';

sub problems
  :Chained("/contest/index")
  :PathPart("problems")
  :Args(0){

  my ($self, $c) = @_;

  my $problems = [db->resultset('problems')->search({contest_id => $c->stash->{contest}->id}, {order_by => 'shortname'})->all];
  my %solved = ();

  if (my $user = $c->stash->{user}) {
    my $results = db->resultset('submissions')->search({
      contest_id => $c->stash->{contest}->id,
      user_id => $user->id,
    }, {
      join => 'problem_id'
    });

    while (my $row = $results->next) {
      next unless $row->status;

      $solved{$row->problem_id->id} //= 'no';

      if ($row->status eq 'OK') {
        $solved{$row->problem_id->id} = 'yes';
      }
    }
  }

  my $subtabs = [map {{
    href => '/contest/' . $c->stash->{contest}->id . '/problem/' . ($_->shortname || '?'),
    name => $_->shortname,
  }} db->resultset('problems')->search({contest_id => $c->stash->{contest}->id}, {order_by => 'shortname'})->all];

  $c->stash(
    template => 'problems.tx',
    title => 'Problem list',
    tab => 'Problems',
    subtabs => $subtabs,

    problems => $problems,
    solved => \%solved,
  );
}

__PACKAGE__->meta->make_immutable;

1;

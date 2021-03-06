package Judge::Controller::problems;
use Moose;
use namespace::autoclean;

use Database;
use Judge::Model::User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

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

      $solved{$row->problem_id->id} //= {
        attempts => 0,
        pending => 0,
        solved => 0,
      };
      if (1) {
        $solved{$row->problem_id->id}->{attempts}++;
      }
      if ($row->status eq 'WAITING') {
        $solved{$row->problem_id->id}->{pending}++;
      }
      if ($row->status eq 'OK') {
        $solved{$row->problem_id->id}->{solved}++;
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

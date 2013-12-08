package Judge::Controller::problem;
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

sub problem
  :Chained("/contest/index")
  :PathPart("problem")
  :Args(1) {

  my ($self, $c, $id) = @_;

  my $problem = db->resultset('problems')->find({contest_id => $c->stash->{contest}->id, shortname => $id});
  $c->detach('404') unless $problem;

  my $statement = '';

  eval {
    use Text::Xslate qw(mark_raw);
    $statement = read_file(catfile($judgeroot, 'problems', $problem->id, 'statement.markdown'));
    $statement = markdown $statement;
    $statement = HTML::Defang->new(fix_mismatched_tags => 1)->defang($statement);
    $statement = mark_raw($statement);
  };

  my $subtabs = [map {{
    href => '/contest/' . $c->stash->{contest}->id . '/problem/' . $_->shortname,
    name => $_->shortname,
  }} db->resultset('problems')->search({contest_id => $c->stash->{contest}->id}, {order_by => 'shortname'})->all];

  $c->stash(
    template => 'problem.tx',
    title => 'Problem ' . $problem->shortname,
    tab => 'Problems',

    subtabs => $subtabs,
    subtab => $problem->shortname,

    problem => $problem,
    statement => $statement,
    samples => Problem::tests($problem, 'sample'),
  );
}

__PACKAGE__->meta->make_immutable;

1;

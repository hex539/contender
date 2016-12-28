package Judge::Controller::problem;
use Moose;
use namespace::autoclean;

use File::Slurp;
use Database;
use Judge::Model::User;
use Judge::Model::Problem;
use HTML::Defang;
use Text::Markdown qw(markdown);
use File::Spec::Functions;
use Settings;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub problem
  :Chained("/contest/index")
  :PathPart("problem")
  :CaptureArgs(1) {

  my ($self, $c, $id) = @_;

  my $problem = db->resultset('problems')->find({contest_id => $c->stash->{contest}->id, shortname => $id});
  $c->detach('/default') unless $problem;

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
  );
}

sub view
  :Chained("problem")
  :PathPart("")
  :Args(0) {

  my ($self, $c) = @_;

  my $problem = $c->stash->{problem};

  my $statement = '';
  eval {
    $statement = read_file(catfile(judgeroot, 'problems', $problem->id, 'statement.markdown'));
  };
  eval {
    use Text::Xslate qw(mark_raw);
    $statement = markdown $statement;
    $statement = HTML::Defang->new(fix_mismatched_tags => 1)->defang($statement);
    $statement = mark_raw($statement);
  };

  $c->stash(
    statement => $statement,
    samples => Judge::Model::Problem::tests($problem, 'sample'),
  );
}

__PACKAGE__->meta->make_immutable;

1;

package Judge::Controller::problem;
use Moose;
use namespace::autoclean;

use File::Slurp;
use Database;
use User;
use HTML::Defang;
use Text::Markdown qw(markdown);
use DateTime::Format::MySQL;
use HTML::Entities;
use File::Basename;
use File::Spec::Functions;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

my $judgeroot = '/home/judge/data';

sub tests {
  my $self = shift;
  my %types = map {$_ => 1} @_;

  use File::Spec::Functions;
  my $testdir = catdir($judgeroot, 'problems', $self->id, 'tests');
  my @results = ();

  opendir ((my $dir), $testdir);
  while (readdir $dir) {
    if ((my $name = $_) =~ /([a-zA-Z]+)(\d+)\.in/) {
      my $type = $1;
      my $num = $2;

      next if %types and not exists $types{$type};

      push @results, {
        type    => $type,
        id      => int($num),
        input   => scalar read_file("$testdir/$type$num.in"),
        output  => scalar read_file("$testdir/$type$num.out"),
      };
    }
  }
  closedir $dir;

  return [sort {($a->{type} cmp $b->{type}) || ($a->{id} <=> $b->{id})} @results];
}

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
    samples => tests($problem, 'sample'),
  );
}

__PACKAGE__->meta->make_immutable;

1;

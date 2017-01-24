package Judge::Controller::submission;
use Moose;
use namespace::autoclean;

use Database;
use File::Slurp;
use File::Spec::Functions;
use HTML::Defang;
use HTML::Entities;
use Judge::Model::Problem;
use Settings;
use Text::Xslate qw(mark_raw);
use Judge::Model::User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub format_table {
  {
     Alert => ["<font color=\"#0000ff\">", "</font>"],
     BaseN => ["<font color=\"#007f00\">", "</font>"],
     BString => ["<font color=\"#c9a7ff\">", "</font>"],
     Char => ["<font color=\"#ff00ff\">", "</font>"],
     Comment => ["<font color=\"#7f7f7f\"><i>", "</i></font>"],
     DataType => ["<font color=\"#0000ff\">", "</font>"],
     DecVal => ["<font color=\"#00007f\">", "</font>"],
     Error => ["<font color=\"#ff0000\"><b><i>", "</i></b></font>"],
     Float => ["<font color=\"#00007f\">", "</font>"],
     Function => ["<font color=\"#007f00\">", "</font>"],
     IString => ["<font color=\"#ff0000\">", ""],
     Keyword => ["<b>", "</b>"],
     Normal => ["", ""],
     Operator => ["<font color=\"#ffa500\">", "</font>"],
     Others => ["<font color=\"#b03060\">", "</font>"],
     RegionMarker => ["<font color=\"#96b9ff\"><i>", "</i></font>"],
     Reserved => ["<font color=\"#9b30ff\"><b>", "</b></font>"],
     String => ["<font color=\"#ff0000\">", "</font>"],
     Variable => ["<font color=\"#0000ff\"><b>", "</b></font>"],
     Warning => ["<font color=\"#0000ff\"><b><i>", "</b></i></font>"],
  }
}

sub highlighter {
  @_ == 1 or die;
  my $ext = shift;

  state $substitutions = {
   "<" => "&lt;",
   ">" => "&gt;",
   "&" => "&amp;",
   "\t" => "  ",
  };
  my @hl_args = (substitutions => $substitutions, format_table => format_table);

  my $hl = undef;
  eval {
    if ($ext eq 'py' or $ext eq 'pypy' or $ext eq 'python') {
      use Syntax::Highlight::Engine::Kate::Python;
      $hl = new Syntax::Highlight::Engine::Kate::Python(@hl_args);
    }
    elsif ($ext eq 'cc' or $ext eq 'c' or $ext eq 'cpp' or $ext eq 'cxx') {
      use Syntax::Highlight::Engine::Kate::Cplusplus;
      $hl = new Syntax::Highlight::Engine::Kate::Cplusplus(@hl_args);
    }
    elsif ($ext eq 'java') {
      use Syntax::Highlight::Engine::Kate::Java;
      $hl = new Syntax::Highlight::Engine::Kate::Java(@hl_args);
    }
    elsif ($ext eq 'matlab' or $ext eq 'm' or $ext eq 'octave') {
      use Syntax::Highlight::Engine::Kate::Matlab;
      $hl = new Syntax::Highlight::Engine::Kate::Matlab(@hl_args);
    }
  };
  return $hl;
}

sub submission
  :Chained("/contest/index")
  :PathPart("submission")
  :Args() {

  my ($self, $c, $submission_id) = @_;

  my $user = Judge::Model::User::get($c);
  if (not $c->stash->{contest}->openbook) {
    $user //= Judge::Model::User::force($c);
  }

  $submission_id = hashids->decrypt($submission_id);

  my $submission = db->resultset('submissions')->find({
    contest_id => $c->stash->{contest}->id,
    'me.id' => $submission_id,
  }, {
    join => 'problem_id',
  });

  return $c->detach('/default') if not $submission;
  return $c->detach('/default') if not $c->stash->{contest}->openbook and (not defined $user || $user->id != $submission->user_id->id && not $user->administrator);
  my $id = $submission->id;

  my $source = '';
  my $compiler_output = '';

  eval {
    $compiler_output = read_file(judgeroot . "/submissions/$id/compile.log") || '';
    $compiler_output =~ s/^\s+\n//g;
    $compiler_output =~ s/\s+$//g;
  };

  eval {
    my $jr = judgeroot;
    my $fname = `ls "$jr/submissions/$id/" | fgrep -v .log`;
    $fname =~ s/\s//g;
    $source = read_file(judgeroot . "/submissions/$id/$fname");
    $source =~ s/^\s+\n//g;
    $source =~ s/\s+$//g;

    (my $ext = $fname) =~ s/^.*\.//g;
    if (my $hl = highlighter($ext)) {
      $source = $hl->highlightText($source);
    }
  };

  $source = HTML::Defang->new(fix_mismatched_tags => 1)->defang($source);

  my @test_types = ('sample');
  if ($c->stash->{contest}->openbook || Judge::Model::User::get($c) && Judge::Model::User::get($c)->administrator) {
    # Allow visibility of all test cases for open contests or signed-in administrators
    push @test_types, 'secret';
  }
  my $tests = Judge::Model::Problem::tests($submission->problem_id, @test_types);

  my %verdicts = map {$_->testcase => $_->status} db->resultset('judgements')->search({
    submission_id => $submission_id,
  })->all;

  for my $test (@$tests) {
    $test->{received} = '';
    eval {
      $test->{received} = read_file(catfile(judgeroot, 'runs', $submission->id, $test->{type} . $test->{id} . '.out'));
    };
    $test->{stderr} = '';
    eval {
      $test->{stderr} = read_file(catfile(judgeroot, 'runs', $submission->id, $test->{type} . $test->{id} . '.err'));
    };

    $test->{input} = substr $test->{input}, 0, 2048;
    $test->{output} = substr $test->{output}, 0, 2048;
    $test->{received} = substr $test->{received}, 0, 2048;
    $test->{status} = $verdicts{$test->{type} . $test->{id}} // 'WAITING';
  }

  $c->stash(
    template => 'submission.tx',
    title => 'Submission #' . int($submission_id),
    tab => 'Submissions',
    user => $user,

    submission => $submission,
    source => mark_raw($source),
    compiler_log => $compiler_output,
    tests => $tests,
  );
}

__PACKAGE__->meta->make_immutable;

1;

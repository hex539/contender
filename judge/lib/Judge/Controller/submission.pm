package Judge::Controller::submission;
use Moose;
use namespace::autoclean;

use Database;
use File::Slurp;
use File::Spec::Functions;
use HTML::Defang;
use HTML::Entities;
use Judge::Model::Problem;
use Judge::View::SourceCode;
use Settings;
use Text::Xslate qw(mark_raw);
use Judge::Model::User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

use constant MAX_IO_LENGTH => 2048;

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
  if (not $c->stash->{contest}->openbook) {
    return $c->detach('/default') if not $user
        || $user->id != $submission->user_id->id && not $user->administrator;
  }

  my $source = '';
  my $compiler_output = '';

  eval {
    $compiler_output = read_file(catfile(judgeroot, 'submissions', $submission->id, 'compile.log'));
    $compiler_output //= '';
    $compiler_output =~ s/^\s+\n//g;
    $compiler_output =~ s/\s+$//g;
  };

  eval {
    my $submission_dir = catdir(judgeroot, "submissions", $submission->id);
    opendir(my $dh, $submission_dir) or die "Can't open submission directory";

    my @submission_files = grep {!/^\.|\.log$/ && -f "$submission_dir/$_"} readdir $dh;

    @submission_files or die("No files for submission " . $submission->id);

    $source = read_file(catfile($submission_dir, $submission_files[0]));
    $source =~ s/^\s+\n//g;
    $source =~ s/\s+$//g;

    (my $ext = $submission_files[0]) =~ s/^.*\.//g;
    if (my $hl = Judge::View::SourceCode::highlighter($ext)) {
      $source = $hl->highlightText($source);
    }
  };

  $source = HTML::Defang->new(fix_mismatched_tags => 1)->defang($source);

  my @test_types = ('sample');
  if ($c->stash->{contest}->openbook || defined($user) && $user->administrator) {
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
      $test->{received} = read_file(catfile(judgeroot, 'runs', $submission->id, $test->{type} . $test->{id} . '.out')) // '';
    };
    $test->{stderr} = '';
    eval {
      $test->{stderr} = read_file(catfile(judgeroot, 'runs', $submission->id, $test->{type} . $test->{id} . '.err')) // '';
    };

    $test->{input} = substr $test->{input}, 0, MAX_IO_LENGTH;
    $test->{output} = substr $test->{output}, 0, MAX_IO_LENGTH;
    $test->{received} = substr $test->{received}, 0, MAX_IO_LENGTH;
    $test->{status} = $verdicts{$test->{type} . $test->{id}} // 'WAITING';
  }

  $c->stash(
    template => 'submission.tx',
    title => 'Submission #' . $submission->id,
    tab => 'Submissions',
    user => $user,

    submission => $submission,
    source => mark_raw($source),
    compiler_log => $compiler_output,
    tests => $tests,
  );
}

__PACKAGE__->meta->make_immutable;

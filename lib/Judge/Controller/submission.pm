package Judge::Controller::submission;
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

sub submission
  :Chained("/contest/index")
  :PathPart("submission")
  :Args() {

  my ($self, $c, $submission_id) = @_;
  my $user = User::force($c);

  my $submission = db->resultset('submissions')->search({
    contest_id => $c->stash->{contest}->id,
    'me.id' => $submission_id,
  }, {
    join => 'problem_id',
  })->next;

  return if not $submission;
  return if not $user->administrator and $user->id != $submission->user_id->id;

  my $source = '';

  eval {
    my $id = $submission->id;
    my $fno = `ls $judgeroot/submissions/$id/`;
    chomp $fno;
    $source = read_file("$judgeroot/submissions/$id/$fno");
    $source =~ s/^\s+\n//g;
    $source =~ s/\s+$//g;

    state $substitutions = {
       "<" => "&lt;",
       ">" => "&gt;",
       "&" => "&amp;",
       "\t" => "  ",
    };
    state $format_table = {
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
    };

    (my $ext = $fno) =~ s/^.*\.//g;
    my $hl = undef;

    if ($ext eq 'py' or $ext eq 'pypy' or $ext eq 'python') {
      use Syntax::Highlight::Engine::Kate::Perl;
      $hl = new Syntax::Highlight::Engine::Kate::Perl(substitutions => $substitutions, format_table => $format_table);
    }
    elsif ($ext eq 'cc' or $ext eq 'c' or $ext eq 'cpp' or $ext eq 'cxx') {
      use Syntax::Highlight::Engine::Kate::Cplusplus;
      $hl = new Syntax::Highlight::Engine::Kate::Cplusplus(substitutions => $substitutions, format_table => $format_table);
    }
    elsif ($ext eq 'java') {
      use Syntax::Highlight::Engine::Kate::Java;
      $hl = new Syntax::Highlight::Engine::Kate::Java(substitutions => $substitutions, format_table => $format_table);
    }
    elsif ($ext eq 'matlab' or $ext eq 'm' or $ext eq 'octave') {
      use Syntax::Highlight::Engine::Kate::Matlab;
      $hl = new Syntax::Highlight::Engine::Kate::Matlab(substitutions => $substitutions, format_table => $format_table);
    }

    $source = $hl->highlightText($source) if $hl;
  };

  $source = HTML::Defang->new(fix_mismatched_tags => 1)->defang($source);

  my @test_types = ('sample');
  push @test_types, 'full' if User::get($c) and User::get($c)->administrator;
  my $tests = tests($submission->problem_id, @test_types);

  for my $test (@$tests) {
    $test->{received} = '';
    eval {
      $test->{received} = read_file(catfile($judgeroot, 'runs', $submission->id, $test->{type} . $test->{id} . '.out'));
    };

    $test->{input} = substr $test->{input}, 0, 2048;
    $test->{output} = substr $test->{output}, 0, 2048;
    $test->{received} = substr $test->{received}, 0, 2048;
  }

  $c->stash(
    template => 'submission.tx',
    title => 'Submission #' . int($submission_id),
    tab => 'Submissions',
    user => $user,

    submission => $submission,
    source => mark_raw($source),
    tests => $tests,
  );
}

__PACKAGE__->meta->make_immutable;

1;

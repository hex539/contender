package Judge::Controller::contest;
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

sub get_problem_list {
  my ($id) = @_;

  my $html = '<ol>';

  my $results = db->resultset('problems')->search({contest_id => $id}, {order_by => 'shortname'});
  while (my $problem = $results->next) {
    $html .= "<li>"
           . "<a href='/contest/$id/problem/" . encode_entities($problem->shortname || '?') . "'>"
           . encode_entities($problem->name || '?')
           . "</a></li>";
  }
  $html .= '</ol>';

  return $html;
}

sub waitpage
  :Path('waitpage') {
  my ($self, $c, $id) = @_;

  $c->stash(
    title => $c->stash->{contest}->name,
    template => 'waitpage.tx',
  );

  return;
}

sub startpage
  :Path('startpage') {
  my ($self, $c, $id) = @_;

  $c->stash(
    title => $c->stash->{contest}->name,
    template => 'startpage.tx',
  );

  return;
}

sub index
  :Chained('/')
  :PathPart('contest')
  :CaptureArgs(1) {
  my ($self, $c, $id) = @_;

  $id = int($id);

  my $contest = db->resultset('contests')->find({id => $id});
  $c->stash(user => User::get($c));
  return unless $contest;

  if (exists $c->request->body_parameters->{start_contest} and $contest->windowed) {
    my $user = User::force($c);

    my $dbh = db->storage->dbh;

    my $sth = $dbh->prepare('
      INSERT IGNORE INTO windows (contest_id, user_id, start_time, duration)
           VALUES (?, ?, NOW(), ?)');

    $sth->execute($contest->id, $user->id, $contest->windowed);
    $dbh->commit;

    $c->redirect('http://contest.incoherency.co.uk/contest/' . $contest->id . '/problems');
    $c->detach;
    return;
  }

  my $now = DateTime->now(time_zone => 'Europe/London');
  my $since_start = $now->epoch - $contest->start_time->epoch - 60 * 60;
  my $until_end   = $contest->duration - $since_start;
  my $time_elapsed = sprintf('%02d:%02d:%02d', (gmtime $since_start)[2,1,0]);
  my $nice_duration = sprintf('%02d:%02d:%02d', (gmtime $contest->duration)[2,1,0]);
  my $start_time = $contest->start_time;
  my $duration = $contest->duration;

  $c->stash(
    user => User::get($c),
    contest => $contest,
    since_start => $since_start,
    until_end => $until_end,
    duration => $duration,
    contest_status => (
      $until_end >= 0? 'Running': 'Finished',
    ),
    now => $now,
  );

  if ($since_start < 0) {
    $c->detach('/contest/waitpage');
    return;
  }

  if ($until_end < 0) {
    $time_elapsed = 'Finished';
  }

  if ($time_elapsed ne 'Finished' and $contest->windowed) {
    my $user = User::force($c);
    $c->stash(user => $user);

    my $window = db->resultset('windows')->find({user_id => $user->id, contest_id => $contest->id});
    $c->stash(window => $window);

    if (not $window) {
      $c->detach('/contest/startpage');
      return;
    }

    $since_start = $now->epoch - $window->start_time->epoch - 60 * 60;
    $until_end = $window->duration - $since_start;
    $nice_duration = sprintf('%02d:%02d:%02d', (gmtime ($window->duration))[2,1,0]);
    $start_time = $window->start_time;
    $duration = $window->duration;

    $c->stash(
      since_start => $since_start,
      until_end => $until_end,
      duration => $duration,
    );

    $time_elapsed = sprintf('%02d:%02d:%02d', (gmtime $since_start)[2,1,0]);

    # Window has expired
    if ($since_start < 0 or $until_end < 0) {
      $c->detach('/contest/startpage');
      return;
    }
  }

  use Text::Xslate qw(mark_raw);
  $c->stash(
    since_start => $since_start,
    until_end => $until_end,
    start_time => $start_time,

    tabs => [
      {
        name => "Problems",
        href => "/contest/$id/problems",
      },
      {
        name => "Standings",
        href => "/contest/$id/standings",
      },
      {
        name => "Submissions",
        href => "/contest/$id/submissions",
      },
      {
        name => "Submit",
        href => "/contest/$id/submit",
      },
      ($contest->windowed and User::get($c) and User::get($c)->administrator?
        ({
          name => "Windows",
          href => "/contest/$id/windows",
        }):()),
    ],

    widgets => [
      {
        id => 'small_contest_state',
        title => 'Contest state',
        text => mark_raw(<<HTML . ($since_start >= 0 and $until_end >= 0? <<HTML: '')),
<header>Time elapsed</header>
<span class="countdown" id="time_elapsed">$time_elapsed</span>
HTML
<header>Duration</header>
<span class="countdown">$nice_duration</span>
HTML
      },
      {
        id => 'small_problem_set',
        title => 'Problem set',
        text => mark_raw(get_problem_list $id),
      },
    ],
  );
}

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

sub standings
  :Chained("/contest/index")
  :PathPart("standings")
  :Args(0) {

  my ($self, $c) = @_;

  my $contest_id = $c->stash->{contest}->id;
  my $results = db->resultset('submissions')->search({contest_id => $contest_id}, {join => 'problem_id', order_by => 'time'});
  my %attempts = ();
  my %solved = ();

  if ($c->stash->{contest_status} ne 'Finished'
  and $c->stash->{contest}->windowed) {

    my $user = User::force($c);

    if (not $user->administrator) {
      $results = $results->search({user_id => $user->id});
    }

    my $participants = db->resultset('windows')->search({contest_id => $contest_id});
    while (my $participant = $participants->next) {
      $solved{$participant->user_id->id} //= {
        user => $participant->user_id,
        score => 0,
        penalty => 0,
      };
    }
  }

  while (my $sub = $results->next) {
    my $user = $sub->user_id->id;
    my $prob = $sub->problem_id->id;

    $solved{$user} //= {
      user => $sub->user_id,
      score => 0,
      penalty => 0,
    };
    $solved{$user}->{$prob} //= {when => undef, attempts => 0};
    $attempts{$prob} //= {solved => 0, attempts => 0};
    next if defined $solved{$user}->{$prob}->{when};

    ++$attempts{$prob}->{attempts};

    if ($sub->status eq 'OK') {
      $solved{$user}->{$prob}->{when} = $sub->time;
      $solved{$user}->{score}++;
      $solved{$user}->{penalty} += $solved{$user}->{$prob}->{attempts} * 20;
      $solved{$user}->{$prob}->{penalty} =
        int((($sub->time->epoch)
          -(($c->stash->{contest}->windowed?
              db->resultset('windows')->find({
                contest_id => $c->stash->{contest}->id,
                user_id => $user
              })
              :
              $c->stash->{contest})->start_time->epoch
            )) / 60);

      $solved{$user}->{penalty} += $solved{$user}->{$prob}->{penalty};

      ++$attempts{$prob}->{solved};
      $solved{$user}->{$prob}->{judging} = 0;
    }
    elsif ($sub->status ne 'JUDGING' and $sub->status ne 'WAITING') {
      $solved{$user}->{$prob}->{attempts}++;
    }
    else {
      $solved{$user}->{$prob}->{judging} = 1;
    }
  }

  my @problems = db->resultset('problems')->search({contest_id => $contest_id}, {order_by => 'shortname'})->all;
  my @rankings = map {$solved{$_}} sort {
      ($solved{$b}->{score}   <=> $solved{$a}->{score})
   || ($solved{$a}->{penalty} <=> $solved{$b}->{penalty})
   || (($a->realname || $a->username) cmp ($b->realname || $b->username))
  } keys %solved;

  $c->stash(
    template => 'standings.tx',
    title => 'Standings',
    tab => 'Standings',

    problems => \@problems,
    rankings => \@rankings,
    attempts => \%attempts,
  );
}

sub submissions
  :Chained("/contest/index")
  :PathPart("submissions")
  :Args() {

  my ($self, $c, %args) = @_;

  my $user = User::get($c);

  my $contest_id = $c->stash->{contest}->id;
  my $results = db->resultset('submissions')->search({contest_id => $contest_id}, {
    join => 'problem_id',
    order_by => {'-desc' => 'time'},
  });

  if ($c->stash->{contest}->windowed) {
    $user = User::force($c);

    if (not $user->administrator) {
      $results = $results->search({user_id => $user->id});
    }
  }

  my $ipp = 20;
  my $pagecount = int(($ipp - 1 + $results->count) / $ipp) || 1;
  $args{page} = int($args{page} || 1);
  $args{page} = 1          if $args{page} < 1;
  $args{page} = $pagecount if $args{page} > $pagecount;
  my @submissions = $results->search({}, {rows => $ipp})->page($args{page})->all;

  my @pages = ($args{page});
  $pages[0]-- while 1 < $pages[0] and ($args{page} - $pages[0] < 2 or $pages[0] + 4 > $pagecount);
  push @pages, $pages[$#pages] + 1 while @pages < 5 and $pages[$#pages] < $pagecount;

  $c->stash(
    template => 'submissions.tx',
    title => 'Submissions',
    tab => 'Submissions',
    user => $user,

    submissions => \@submissions,
    pagecount => $pagecount,
    page => $args{page},
    pages => \@pages,
  );
}

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

sub submit
  :Chained("/contest/index")
  :PathPart("submit")
  :Args() {

  my ($self, $c, $problem_sn) = @_;
  my $user = User::force($c);

  if ($c->stash->{contest_status} ne 'Running') {
    return;
  }

  $problem_sn //= $c->request->param('problem');

  if ((defined $problem_sn) and (my $upload = $c->request->upload('file'))) {
    return if $c->stash->{since_start} < 0;
    return if $c->stash->{until_end} < 0;

    my $problem = db->resultset('problems')->find({contest_id => $c->stash->{contest}->id, shortname => $problem_sn});
    return unless $problem;

    my $dbh = db->storage->dbh;

    my $sth = $dbh->prepare('
      INSERT INTO submissions (user_id, problem_id)
           VALUES (?, ?)');

    # Create new entry in submissions table
    $dbh->begin_work;
    unless ($sth->execute($user->id, $problem->id)) {
      $dbh->rollback;
      die;
    }
    my $id = int($sth->{mysql_insertid});

    # Normalise extension
    my $ext = (fileparse(lc($upload->filename), qr/\.[^.]*/))[2] || '.cc';
    $ext = '.cc'     if $ext eq '.cpp';
    $ext = '.cc'     if $ext eq '.cxx';
    $ext = '.cc'     if $ext eq '.c';
    $ext = '.py'     if $ext eq '.python';
    $ext = '.py'     if $ext eq '.pypy';
    $ext = '.matlab' if $ext eq '.octave';

    # Copy source to submissions directory
    my $fn = catfile($judgeroot, 'submissions', $id, "$id$ext");
    mkdir catdir($judgeroot, 'submissions', $id);

    if (not $upload->copy_to($fn)) {
      $dbh->rollback;
      die "Unable to save file for submission #$id to problem #" . $problem->id . " by user #" . $user->id;
    }
    $dbh->commit;

    $c->response->redirect('http://contest.incoherency.co.uk/contest/' . $c->stash->{contest}->id . '/standings');
    $c->detach;
    return;
  }

  my $problems = [db->resultset('problems')->search({
    contest_id => $c->stash->{contest}->id,
    (defined $problem_sn? (shortname => $problem_sn): ()),
  }, {
    order_by => 'shortname'
  })->all];

  $c->stash(
    template => 'submit.tx',
    problems => $problems,
    title => 'Submit',
    tab => 'Submit',
  );
}

sub windows
  :Chained("/contest/index")
  :PathPart("windows")
  :Args() {

  my ($self, $c, %args) = @_;
  my $contest = $c->stash->{contest};

  return if not User::force($c)->administrator;
  return if not $contest->windowed;

  my $results = db->resultset('windows')->search({contest_id => $contest->id}, {
    order_by => {'-desc' => 'start_time'},
  });

  my $ipp = 20;
  my $pagecount = int(($ipp - 1 + $results->count) / $ipp) || 1;
  $args{page} = int($args{page} || 1);
  $args{page} = 1          if $args{page} < 1;
  $args{page} = $pagecount if $args{page} > $pagecount;

  my @windows = $results->search({}, {rows => $ipp})->page($args{page})->all;

  my @pages = ($args{page});
  $pages[0]-- while 1 < $pages[0] and ($args{page} - $pages[0] < 2 or $pages[0] + 4 > $pagecount);
  push @pages, $pages[$#pages] + 1 while @pages < 5 and $pages[$#pages] < $pagecount;

  $c->stash(
    template => 'windows.tx',
    title => 'Windows',
    tab => 'Windows',
    user => User::force($c),

    windows => \@windows,
    pagecount => $pagecount,
    page => $args{page},
    pages => \@pages,
  );
}

__PACKAGE__->meta->make_immutable;

1;

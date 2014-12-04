package Judge::Controller::contest;
use Moose;
use namespace::autoclean;

use DateTime;
use Database;
use Settings;
use User;
use HTML::Entities;
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

  if (not defined $contest) {
    $c->detach('/default');
  }
  if (not $contest->visible) {
    $c->detach('/default') unless User::force($c)->administrator;
  }

  if (exists $c->request->body_parameters->{start_contest} and $contest->windowed) {
#     User::force($c)->start_window($contest);

    my $user = User::force($c);

    my $dbh = db->storage->dbh;

    my $sth = $dbh->prepare('
      INSERT IGNORE INTO windows (contest_id, user_id, start_time, duration)
           VALUES (?, ?, NOW(), ?)');

    my $duration = 3 * 60 * 60;
    $sth->execute($contest->id, $user->id, $duration);
    $dbh->commit;

    $c->redirect('http://contest.incoherency.co.uk/contest/' . $contest->id . '/problems');
    $c->detach;
  }

  my $now = DateTime->now(time_zone => 'Europe/London');
  my $since_start = $now->epoch - $contest->start_time->epoch;
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
    hashids => hashids,
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

    $since_start = $now->epoch - $window->start_time->epoch;
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

    tabs => [grep {$_}
      {
        name => "Problems",
        href => "/contest/$id/problems",
      },
#      ($time_elapsed eq 'Finished' or User::get($c) and User::get($c)->administrator) &&
#        {
#          name => "Writeups",
#          href => "/contest/$id/writeups",
#        },
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
      ($contest->windowed and User::get($c) and User::get($c)->administrator) &&
        {
          name => "Windows",
          href => "/contest/$id/windows",
        },
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

__PACKAGE__->meta->make_immutable;

1;

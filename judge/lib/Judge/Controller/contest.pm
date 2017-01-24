package Judge::Controller::contest;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

use DateTime;
use Database;
use Settings;
use Judge::Model::User;
use HTML::Entities;
use Time::Duration;
use Text::Xslate qw(mark_raw);

BEGIN { extends 'Catalyst::Controller'; }

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

  my $contest = $c->stash->{contest};

  my $now = DateTime->now(time_zone => 'Europe/London');
  my $window_finish = $now->clone->add_duration($contest->window_duration);

  $c->stash(
    title => $c->stash->{contest}->name,
    template => 'startpage.tx',
    nice_window_duration => duration($window_finish->epoch - $now->epoch),
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
  $c->stash(user => Judge::Model::User::get($c));

  if (not defined $contest) {
    $c->detach('/default');
  }
  if (not $contest->visible) {
    $c->detach('/default') unless Judge::Model::User::force($c)->administrator;
  }

  my $now = DateTime->now(time_zone => 'Europe/London');
  $c->stash(
    user => Judge::Model::User::get($c),
    contest => $contest,
    series => $contest->series_id,
    start_time => $contest->start_time,
    end_time => $contest->end_time,
    now => $now,
    hashids => hashids,
  );

  # Contest has not started yet
  if (defined($contest->start_time) && $now->epoch < $contest->start_time->epoch) {
    $c->detach('/contest/waitpage');
    return;
  }

  if ($contest->running($now) && $contest->windowed) {
    my $user = Judge::Model::User::force($c);
    $c->stash(user => $user);

    if (exists $c->request->body_parameters->{start_contest}) {
      my $user = Judge::Model::User::force($c) // die 'No user';
      Judge::Model::User::start_window(user => $user, contest => $contest);
      $c->redirect('https://hex539.me/contest/' . $contest->id . '/problems');
      $c->detach;
    }

    my $window = db->resultset('windows')->find({
        user_id => $user->id,
        contest_id => $contest->id
    });

    if (defined $window) {
      $c->stash(
        window => $window,
        start_time => $window->start_time,
        end_time => $window->end_time,
      );
    }

    # Window is not started yet, or has expired
    if ((not defined $window) || (not $window->running($now))) {
      $c->detach('/contest/startpage');
      return;
    }
  }

  my $since_start = (defined($c->stash->{start_time})
      ? $now->epoch - $c->stash->{start_time}->epoch
      : undef);
  my $until_end = (defined($c->stash->{end_time})
      ? $c->stash->{end_time}->epoch - $now->epoch
      : undef);
  my $time_elapsed = (defined($since_start)
      ? sprintf('%02d:%02d:%02d', (gmtime $since_start)[2,1,0])
      : undef);
  my $contest_status = (defined $until_end && $until_end < 0
      ? 'Finished'
      : 'Running');
  my $nice_duration = (defined($c->stash->{start_time}) && defined($c->stash->{end_time})
      ? sprintf('%02d:%02d:%02d', $c->stash->{end_time}
                                  ->subtract_datetime($c->stash->{start_time})
                                  ->in_units('hours', 'minutes', 'seconds'))
      : undef);

  $c->stash(
    since_start => $since_start,
    until_end => $until_end,
    time_elapsed => $time_elapsed,
    contest_status => $contest_status,

    tabs => [grep {$_}
      {
        name => "Problems",
        href => "/contest/$id/problems",
      },
#      ($time_elapsed eq 'Finished' or Judge::Model::User::get($c) and Judge::Model::User::get($c)->administrator) &&
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
      ($contest->windowed and Judge::Model::User::get($c) and Judge::Model::User::get($c)->administrator) && {
        name => "Windows",
        href => "/contest/$id/windows",
      } || (),
    ],

    widgets => [
      (defined $nice_duration) && {
        id => 'small_contest_state',
        title => 'Contest state',
        text => mark_raw(<<HTML . ($since_start >= 0 and $until_end >= 0? <<HTML: '')),
<header>Time elapsed</header>
<span class="countdown" id="time_elapsed">$time_elapsed</span>
HTML
<header>Duration</header>
<span class="countdown">$nice_duration</span>
HTML
      } || (),
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

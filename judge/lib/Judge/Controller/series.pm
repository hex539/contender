package Judge::Controller::series;
use Moose;
use namespace::autoclean;

use Database;
use User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub series
  :Chained("/")
  :PathPart("series")
  :Args(1){

  my ($self, $c, $series_ref) = @_;
  $c->stash(user => User::get($c));
  my $now = DateTime->now(time_zone => 'Europe/London');
  $c->stash(now => $now);

  my $series = db->resultset('series')->find({shortname => $series_ref});
  $c->detach('/default') unless $series;

  my $contests = {
      Upcoming => [],
      Running  => [],
      Finished => [],
  };
  for my $contest ($series->get_contests->search({}, {order_by => { -desc => [qw[start_time name]]}})->all) {
    unless ($contest->visible) {
      next unless ($c->stash->{user} && $c->stash->{user}->administrator);
    }
    if ($contest->start_time->epoch > $c->stash->{now}->epoch) {
      push $contests->{Upcoming}, $contest;
    }
    elsif ($contest->start_time->epoch + $contest->duration > $c->stash->{now}->epoch) {
      push $contests->{Running}, $contest;
    }
    else {
      push $contests->{Finished}, $contest;
    }
  }

  $c->stash(
    template => 'series.tx',
    title => 'Contest list',
    tab => 'Series',
    subtabs => [],

    series => $series,
    contests => $contests,
  );
}

__PACKAGE__->meta->make_immutable;

1;

package Judge::Controller::standings;
use Moose;
use namespace::autoclean;

use Database;
use User;
use Text::Markdown qw(markdown);
use File::Basename;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

my $judgeroot = '/home/judge/data';

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
      $solved{$user}->{$prob}->{id} = $sub->id;
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
   || (($solved{$a}->{user}->realname || $solved{$a}->{user}->username)
   cmp ($solved{$b}->{user}->realname || $solved{$b}->{user}->username))
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

__PACKAGE__->meta->make_immutable;

1;

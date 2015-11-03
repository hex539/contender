package Judge::Controller::standings;
use Moose;
use namespace::autoclean;

use Database;
use User;
use Text::Markdown qw(markdown);
use File::Basename;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub standings
  :Chained("/contest/index")
  :PathPart("standings")
  :Args(0) {

  my ($self, $c) = @_;

  my $contest_id = $c->stash->{contest}->id;
  my $results = db->resultset('submissions')->search(
    {contest_id => $contest_id},
    {join => 'problem_id', order_by => 'time'});
  my %first_solved = ();
  my %attempts = ();
  my %solved = ();

  my $user = User::get($c);
  my $contest = $c->stash->{contest};

  if ($contest->windowed) {
    $user //= User::force($c);
    if ($c->stash->{contest_status} ne 'Finished') {
      # Hide submissions from other users
      if (not $user->administrator) {
        $results = $results->search({user_id => $user->id});
      }
    }

    # Pre-populate for users who have started a window but not yet submitted anything
    if ($user->administrator || $c->stash->{contest_status} eq 'Finished') {
      my $participants = db->resultset('windows')->search({contest_id => $contest_id});
      while (my $participant = $participants->next) {
        $solved{$participant->user_id->id} //= {
          user => $participant->user_id,
          score => 0,
          penalty => 0,
        };
      }
    }
  }

  # Hide administrator users from normal users
  if ((not defined $user) || (not $user->administrator)) {
    $results = $results->search({'user_id.administrator' => '0'},{
      join => ['user_id']
    });
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
    $attempts{$prob} //= {solved => 0, attempts => 0, first => undef};
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

      $solved{$user}->{$prob}->{judging} = 0;
      ++$attempts{$prob}->{solved};

      if ((not $sub->user_id->administrator)
      and (not defined $attempts{$prob}->{first}
                         or $attempts{$prob}->{first} > $solved{$user}->{$prob}->{penalty})) {
        $attempts{$prob}->{first} = $solved{$user}->{$prob}->{penalty};
      }
    }
    elsif ($sub->status ne 'JUDGING' and $sub->status ne 'WAITING' and $sub->status ne 'COMPILE-ERROR') {
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
   || ($solved{$a}->{user}->administrator <=> $solved{$b}->{user}->administrator)
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

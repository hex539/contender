package Judge::Controller::submissions;
use Moose;
use namespace::autoclean;

use Database;
use User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

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

  my $filter_user = $args{user} // undef;
  if (defined $filter_user) {
    my $usr = db->resultset('users')->find({username => $filter_user});
    if (defined $usr) {
      $filter_user = $usr->id;
    }
  }
  if ($c->stash->{contest}->windowed) {
    $user = User::force($c);
    if (not $user->administrator) {
      $filter_user = $user->id;
    }
  }
  if (defined $filter_user) {
    $results = $results->search({user_id => $filter_user});
  }

  if (exists $args{problem}) {
    my $problem = db->resultset('problems')->find({contest_id => $contest_id, shortname => $args{problem}});
    if (defined $problem) {
      $results = $results->search({problem_id => $problem->id});
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

__PACKAGE__->meta->make_immutable;

1;

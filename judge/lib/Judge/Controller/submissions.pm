package Judge::Controller::submissions;
use Moose;
use namespace::autoclean;

use Judge::Model::Submission;
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

  my $target_user = undef;
  if (defined $args{user}) {
    $target_user = User::find($args{user});

    # TODO redirect this to a nice neat 404 page.
    defined $target_user or warn 'No such user';
  }

  my $results = Judge::Model::Submission::list(
    requester => $user,
    contest_id => $args{contest_id},
    problem => $args{problem},
    user => $target_user,
  );

  # Pagination of results (TODO move this to a View)
  my $ipp = 20;
  my $pagecount = int(($ipp - 1 + $results->count) / $ipp) || 1;
  $args{page} = int($args{page} // 1);
  $args{page} = 1          if $args{page} < 1;
  $args{page} = $pagecount if $args{page} > $pagecount;
  my @submissions = $results->search({}, {rows => $ipp})->page($args{page})->all;

  # Buttons for pagination (TODO move this to a View)
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

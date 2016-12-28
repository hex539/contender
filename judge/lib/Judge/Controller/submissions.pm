package Judge::Controller::submissions;
use Moose;
use namespace::autoclean;

use Judge::Model::Submission;
use Database;
use Judge::Model::User;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

use constant SUBMISSIONS_PER_PAGE => 20;

sub submissions
  :Chained("/contest/index")
  :PathPart("submissions")
  :Args() {

  my ($self, $c, %args) = @_;

  my $user = Judge::Model::User::force($c);

  my $target_user = undef;
  if (defined $args{user}) {
    $target_user = Judge::Model::User::find($args{user});

    # TODO redirect this to a nice neat 404 page.
    defined $target_user or warn 'No such user';
  }

  my $results = Judge::Model::Submission::list(
    requester => $user,
    contest_id => $args{contest_id},
    problem => $args{problem},
    user => $target_user,
  );

  my $pager = undef;
  if (exists $args{page} or not $user->administrator) {
    $results = $results->search({}, {
      rows => SUBMISSIONS_PER_PAGE,
      page => int($args{page} // 1),
    });
    $pager = $results->pager;
  }
  my @submissions = $results->all;

  $c->stash(
    template => 'submissions.tx',
    title => 'Submissions',
    tab => 'Submissions',
    user => $user,

    submissions => \@submissions,
    pager => $pager,
  );
}

__PACKAGE__->meta->make_immutable;

1;

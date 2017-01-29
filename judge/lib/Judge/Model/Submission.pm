package Judge::Model::Submission;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

use Database;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(list);

BEGIN {extends 'Catalyst::Model'; }

sub list {
  my %args = @_;

  my $requester = $args{requester};     # Required
  my $contest_id = $args{contest_id};   # Optional
  my $user = $args{user};               # Optional
  my $problem_letter = $args{problem};  # Optional

  defined $requester or die 'Need a requester to list submissions';
  my $contest = undef;

  my $results = db->resultset('submissions')->search(undef, {
    join => 'problem_id',
    order_by => {'-desc' => 'time'},
  });

  if (defined ($contest_id)) {
    $contest = db->resultset('contests')->find({id => $contest_id}) or die 'Contest does not exist';
    $results = $results->search({contest_id => $contest->id});
  }

  if (defined $user) {
    if ($user->id != $requester->id) {
      defined $requester && $requester->administrator
          or die 'Requester needs to be an administrator list other users\' submissions';
    }
    $results = $results->search({user_id => $user->id});
  } else {
    if ((defined $contest) && not $contest->windowed) {
      # Allow searching all submissions.
    } else {
      $requester->administrator or die 'Requester needs to be an administrator to list all submissions';
    }
  }

  if (defined $problem_letter) {
    defined $contest or die 'Problem letter given but not contest';

    my $problem = db->resultset('problems')->find({
      contest_id => $contest->id,
      shortname => $problem_letter,
    });
    if (defined $problem) {
      $results = $results->search({problem_id => $problem->id});
    }
  }

  return $results;
}

__PACKAGE__->meta->make_immutable;

1;

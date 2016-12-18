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

  my $requester = $args{requester};
  my $contest_id = $args{contest_id};
  my $user = $args{user};
  my $problem_letter = $args{problem};

  defined $requester or die 'Need a requester to list submissions';

  my $results = db->resultset('submissions')->search(undef, {
    join => 'problem_id',
    order_by => {'-desc' => 'time'},
  });;

  if (defined (my $contest_id = $args{contest_id})) {
    $results = $results->search({contest_id => $contest_id});
  }

  if (defined (my $user = $args{user})) {
    if ($user->id != $requester->id) {
      defined $requester && $requester->administrator
          or die 'Requester needs to be an administrator list other users\' submissions';
    }
    $results = $results->search({user_id => $user->id});
  } else {
    if (defined $contest_id && !$contest_id->windowed) {
      # Allow searching all submissions.
    } else {
      defined $requester && $requester->administrator
          or die 'Requester needs to be an administrator to list all submissions';
    }
  }

  if (defined (my $problem_letter = $args{problem})) {
    defined $contest_id
        or die 'Problem letter given but not contest ID';

    my $problem = db->resultset('problems')->find({
      contest_id => $contest_id,
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

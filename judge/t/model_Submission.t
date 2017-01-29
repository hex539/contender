use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok 'Database';
  use_ok 'Judge::Model::Submission';
}

my $user_one;
my $user_two;
my $contest;
my $problem;

sub setup {
  my $schema = db(inject_mock => 'dbi:SQLite:dbname=:memory:') or die 'Unable to inject mock';
  $schema->deploy;

  $user_one = db->resultset('users')->new_result({
    id => 5678,
    username => 'user_one',
    realname => 'User One',
    administrator => 0,
  });

  $user_two = db->resultset('users')->new_result({
    id => 4321,
    username => 'user_two',
    realname => 'User Two',
    administrator => 1,
  });

  $contest = db->resultset('contests')->new_result({
    id => 55,
    shortname => 'testcontest',
    visible => 1,
    openbook => 0,
    penalty => 0,
  });

  $problem = db->resultset('problems')->new_result({
    id => 123,
    contest_id => $contest->id,
    name => 'test problem',
    shortname => 'prob',
  });

  my $submission_one_a = db->resultset('submissions')->new_result({
    id => 101,
    user_id => $user_one->id,
    problem_id => $problem->id,
    status => 'OK',
  });

  my $submission_one_b = db->resultset('submissions')->new_result({
    id => 102,
    user_id => $user_one->id,
    problem_id => $problem->id,
    status => 'WRONG-ANSWER',
  });

  my $submission_two_a = db->resultset('submissions')->new_result({
    id => 103,
    user_id => $user_two->id,
    problem_id => $problem->id,
    status => 'OK',
  });

  $user_one->insert;
  $user_two->insert;
  $contest->insert;
  $problem->insert;
  $submission_one_a->insert;
  $submission_one_b->insert;
  $submission_two_a->insert;
}
setup;

subtest list_submissions => sub {
  #
  # When I request my own submissions, I should get exactly
  # the two of them back.
  #
  my @submissions_mine = Judge::Model::Submission::list(
    requester => $user_one,
    contest_id => $contest->id,
    user => $user_one,
  )->all;
  ok ((@submissions_mine == 2), 'list exactly 2 of my submissions');

  #
  # When you request your own submissions, you should get
  # exactly the one back.
  #
  my @submissions_yours = Judge::Model::Submission::list(
      requester => $user_two,
      contest_id => $contest->id,
      user => $user_two,
    )->all;
  ok ((@submissions_yours == 1), 'list exactly 1 of your submissions');

  #
  # When I request your submissions, I should trigger an error
  # because I'm not an administrator.
  #
  $@ = undef;
  my @submissions_yours_as_me;
  eval {
    @submissions_yours_as_me = Judge::Model::Submission::list(
      requester => $user_one,
      contest_id => $contest->id,
      user => $user_two,
    )->all;
  };
  ok($@ ne '' && @submissions_yours_as_me == 0, 'unable to list other users submissions as myself');

  #
  # When you request my submissions, you should get them both back
  # because you are an administrator and as such able to see them.
  #
  $@ = undef;
  my @submissions_mine_as_you;
  eval {
    @submissions_mine_as_you = Judge::Model::Submission::list(
      requester => $user_two,
      contest_id => $contest->id,
      user => $user_one,
    )->all;
  };
  ok($@ eq '' && @submissions_mine_as_you == 2, 'able to list other users submissions as an administrator');
};

done_testing();

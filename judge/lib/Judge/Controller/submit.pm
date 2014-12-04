package Judge::Controller::submit;
use Moose;
use namespace::autoclean;

use Database;
use User;
use File::Basename;
use File::Spec::Functions;
use Settings;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub submit
  :Chained("/contest/index")
  :PathPart("submit")
  :Args() {

  my ($self, $c, $problem_sn) = @_;
  my $user = User::force($c);

  $problem_sn //= $c->request->param('problem');

  if ((defined $problem_sn) and (my $upload = $c->request->upload('file'))) {
    return if $c->stash->{since_start} < 0;
    return if $c->stash->{until_end} < 0;

    my $problem = db->resultset('problems')->find({contest_id => $c->stash->{contest}->id, shortname => $problem_sn});
    return unless $problem;

    my $dbh = db->storage->dbh;

    my $sth = $dbh->prepare('
      INSERT INTO submissions (user_id, problem_id)
           VALUES (?, ?)');

    # Create new entry in submissions table
    $dbh->begin_work;
    unless ($sth->execute($user->id, $problem->id)) {
      $dbh->rollback;
      die;
    }
    my $id = int($sth->{mysql_insertid});

    # Normalise extension
    my $ext = (fileparse(lc($upload->filename), qr/\.[^.]*/))[2] || '.cc';
    $ext = '.cc'     if $ext eq '.cpp';
    $ext = '.cc'     if $ext eq '.cxx';
    $ext = '.cc'     if $ext eq '.c';
    $ext = '.py'     if $ext eq '.python';
    $ext = '.py'     if $ext eq '.pypy';
    $ext = '.matlab' if $ext eq '.octave';

    # Copy source to submissions directory
    my $fn = catfile(judgeroot, 'submissions', $id, "$id$ext");
    mkdir catdir(judgeroot, 'submissions', $id);

    if (not $upload->copy_to($fn)) {
      $dbh->rollback;
      die "Unable to save file for submission #$id to problem #" . $problem->id . " by user #" . $user->id;
    }
    $dbh->commit;

    $c->response->redirect('http://contest.incoherency.co.uk/contest/' . $c->stash->{contest}->id . '/standings');
    $c->detach;
    return;
  }

  my $problems = [];
  
  if ($c->stash->{contest_status} eq 'Running') {
    $problems = [db->resultset('problems')->search({
      contest_id => $c->stash->{contest}->id,
      (defined $problem_sn? (shortname => $problem_sn): ()),
    }, {
      order_by => 'shortname'
    })->all];
  }

  $c->stash(
    template => 'submit.tx',
    problems => $problems,
    title => 'Submit',
    tab => 'Submit',
  );
}

__PACKAGE__->meta->make_immutable;

1;

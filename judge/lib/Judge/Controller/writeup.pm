package Judge::Controller::writeup;
use Moose;
use namespace::autoclean;

use File::Slurp;
use Database;
use Judge::Model::User;
use Judge::Model::Problem;
use HTML::Defang;
use Text::Markdown qw(markdown);
use File::Spec::Functions;
use Settings;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

sub writeup
  :Chained("/problem/problem")
  :PathPart("writeup")
  :Args(0) {

  my ($self, $c, $id) = @_;

  my $problem = $c->stash->{problem};
  my $content = '';
  eval {
    $content = read_file(catfile(judgeroot, 'problems', $problem->id, 'writeup.markdown'));
  };
  eval {
    use Text::Xslate qw(mark_raw);
    $content = markdown $content;
    $content = HTML::Defang->new(fix_mismatched_tags => 1)->defang($content);
    $content = mark_raw($content);
  };

  $c->stash(
    template => 'writeup.tx',
    content => $content,
    models => [],
  );
}

__PACKAGE__->meta->make_immutable;

1;

package Judge::Controller::windows;
use Moose;
use namespace::autoclean;

use File::Slurp;
use Database;
use User;
use HTML::Defang;
use Text::Markdown qw(markdown);
use DateTime::Format::MySQL;
use HTML::Entities;
use File::Basename;
use File::Spec::Functions;
use feature 'state';

BEGIN { extends 'Catalyst::Controller'; }

my $judgeroot = '/home/judge/data';

sub windows
  :Chained("/contest/index")
  :PathPart("windows")
  :Args() {

  my ($self, $c, %args) = @_;
  my $contest = $c->stash->{contest};

  return if not User::force($c)->administrator;
  return if not $contest->windowed;

  my $results = db->resultset('windows')->search({contest_id => $contest->id}, {
    order_by => {'-desc' => 'start_time'},
  });

  my $ipp = 20;
  my $pagecount = int(($ipp - 1 + $results->count) / $ipp) || 1;
  $args{page} = int($args{page} || 1);
  $args{page} = 1          if $args{page} < 1;
  $args{page} = $pagecount if $args{page} > $pagecount;

  my @windows = $results->search({}, {rows => $ipp})->page($args{page})->all;

  my @pages = ($args{page});
  $pages[0]-- while 1 < $pages[0] and ($args{page} - $pages[0] < 2 or $pages[0] + 4 > $pagecount);
  push @pages, $pages[$#pages] + 1 while @pages < 5 and $pages[$#pages] < $pagecount;

  $c->stash(
    template => 'windows.tx',
    title => 'Windows',
    tab => 'Windows',
    user => User::force($c),

    windows => \@windows,
    pagecount => $pagecount,
    page => $args{page},
    pages => \@pages,
  );
}

__PACKAGE__->meta->make_immutable;

1;

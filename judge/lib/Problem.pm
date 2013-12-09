package Problem;

use Exporter;
our @EXPORT_OK = qw(tests);

use File::Slurp;
use HTML::Defang;
use Text::Markdown qw(markdown);
use DateTime::Format::MySQL;
use HTML::Entities;
use File::Basename;
use File::Spec::Functions;
use feature 'state';

my $judgeroot = '/home/judge/data';

sub tests {
  my $self = shift;
  my %types = map {$_ => 1} @_;

  use File::Spec::Functions;
  my $testdir = catdir($judgeroot, 'problems', $self->id, 'tests');
  my @results = ();

  opendir ((my $dir), $testdir);
  while (readdir $dir) {
    if ((my $name = $_) =~ /([a-zA-Z]+)(\d+)\.in/) {
      my $type = $1;
      my $num = $2;

      next if %types and not exists $types{$type};

      push @results, {
        type    => $type,
        id      => int($num),
        input   => scalar read_file("$testdir/$type$num.in"),
        output  => scalar read_file("$testdir/$type$num.out"),
      };
    }
  }
  closedir $dir;

  return [sort {($a->{type} cmp $b->{type}) || ($a->{id} <=> $b->{id})} @results];
}

1;

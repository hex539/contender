package Judge::Model::Problem;
use Moose;
use namespace::autoclean;

use strict;
use warnings;
use feature 'state';

use Exporter;
our @EXPORT_OK = qw(dir tests models);

use File::Slurp;
use File::Spec::Functions;
use HTML::Defang;
use Text::Markdown qw(markdown);

BEGIN {extends 'Catalyst::Model'; }

use Settings qw(judgeroot);

sub dir {
  my ($self, @subdirs) = @_;

  return catdir(judgeroot, 'problems', $self->id, @subdirs);
}

sub tests {
  my $self = shift;
  my %types = map {$_ => 1} @_;

  my @results = ();

  opendir ((my $dir), dir($self, 'data'));
  return @results unless $dir;

  while (readdir $dir) {
    if ((my $type = $_) =~ /^[a-zA-Z]+$/) {
      next if %types and not exists $types{$type};

      opendir ((my $typedir), dir($self, 'data', $type));
      next unless $typedir;

      while (readdir $typedir) {
        if ((my $full_name = $_) =~ /(\d+)([a-zA-Z]*)\.in/) {
          my $num = $1;
          my $description = $2;

          my $name = $full_name;
          $name =~ s/\..+//g;

          push @results, {
            type    => $type,
            id      => int($num),
            input   => scalar read_file(catfile(dir($self, 'data', $type), "$name.in")),
            output  => scalar read_file(catfile(dir($self, 'data', $type), "$name.ans")),
          };
        }
      }
    }
  }
  closedir $dir;

  return [sort {($a->{type} cmp $b->{type})
             || ($a->{id}   <=> $b->{id})} @results];
}

sub models {
  my $self = shift;
  my %filters = map {$_ => 1} @_;

  my @results = ();

  opendir ((my $dir), dir($self, 'models'));
  while (readdir $dir) {
    if ((my $name = $_) =~ /[-a-zA-Z_]+\.(?:cc|py)/) {
      push @results, {
        name    => $name,
        lang    => 'C++',
        source  => scalar read_file(catfile(dir($self, 'models'), $name)),
      };
    }
  }
  closedir $dir;

  return [sort {$a->{lang} cmp $b->{lang}
             || $a->{name} cmp $b->{name}} @results];
}

1;

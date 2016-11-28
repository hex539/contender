package Settings;

use strict;
use warnings;
use feature 'state';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(judgeroot judge_config hashids);

use Hashids;
use YAML;

sub judgeroot {
  '/home/judge/data'
}

sub judge_config {
  state $config = undef;

  unless ($config) {
    $config = YAML::LoadFile('/etc/contender/contender.yaml');
  }

  return $config;
}

sub hashids {
  state $hsh = Hashids->new(
    salt => 'default salt',
    minHashLength => 5,
  );
  return $hsh;
}

1;

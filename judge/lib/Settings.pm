package Settings;

use strict;
use warnings;
use feature 'state';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(judgeroot hashids);

use Hashids;

sub judgeroot {
  '/home/judge/data'
}

sub hashids {
  state $hsh = Hashids->new(
    salt => 'default salt',
    minHashLength => 5,
  );
  return $hsh;
}

1;

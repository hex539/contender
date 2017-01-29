#!/usr/bin/perl

package Database;

use strict;
use warnings;
use feature 'state';

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(db);

use Schema;
use Settings qw(judge_config);

sub db {
  state $schema = undef;

  my %args = @_;
  my $inject_mock = $args{inject_mock};
  delete $args{inject_mock};
  die 'Too many arguments' if %args;

  if (defined $inject_mock) {
    unless ($schema ) {
      $schema = Judge::ORM->connect($inject_mock);
    }
    else {
      die 'Schema has already been created. Too late!';
    }
  }

  unless ($schema) {
    my $database = judge_config->{database};
    my $hostname =  $database->{hostname} // 'localhost';
    my $dbname =    $database->{database} // 'contender';
    my $password =  $database->{password} // '';
    my $username =  $database->{username} // 'judge';

    $schema = Judge::ORM->connect('dbi:Pg:dbname=' . $dbname . ';host=' . $hostname,
        $username, $password);
  }

  return $schema;
}

1;

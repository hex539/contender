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

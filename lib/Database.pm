#!/usr/bin/perl

package Database;

use strict;
use warnings;
use feature 'state';
use File::Slurp;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(db);

use Schema;

sub db {
  state $schema = undef;

  unless ($schema) {
    my $password = read_file('/etc/tourniquet/passwords/database');

    $schema = Judge::ORM->connect('dbi:mysql:dbname=tourniquet', 'judge', $password);
  }

  return $schema;
}

1;

#!/usr/bin/perl

package Config;

use strict;
use warnings;
use feature 'state';
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(judgeroot);

use Schema;

sub judgeroot {'/home/judge/data'}

1;

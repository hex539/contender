package Judge::ORM::problems;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('problems');

__PACKAGE__->add_columns(
  'id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 1,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'id',
    'is_nullable'       => 0,
    'size'              => '11'
  },
  'contest_id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 1,
    'name'              => 'contest_id',
    'is_nullable'       => 0,
    'size'              => '11'
  },
  'shortname' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'shortname',
    'is_nullable'       => 0,
    'size'              => '255'
  },
  'name' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'name',
    'is_nullable'       => 0,
    'size'              => '255'
  },
  'scoring' => {
    'data_type'         => 'ENUM',
    'is_auto_increment' => 0,
    'default_value'     => 'binary',
    'is_foreign_key'    => 0,
    'name'              => 'scoring',
    'is_nullable'       => 0,
    'size'              => '7'
  },
);
__PACKAGE__->set_primary_key('id');

sub tests {
  my $self = shift;
  my %types = map {$_ => 1} @_;

  use File::Spec::Functions;
  use Config;

  my $testdir = catdir(judgeroot(), 'problems', $self->id, 'tests');
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

__PACKAGE__->belongs_to( 'contest_id', 'Judge::ORM::contests' );

__PACKAGE__->has_many( 'get_submissions', 'Judge::ORM::submissions',
  'problem_id' );

1;

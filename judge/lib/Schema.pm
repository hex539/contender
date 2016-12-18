package Judge::ORM::sessions;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('sessions');

__PACKAGE__->add_columns(
  'id' => {
    'data_type'         => 'CHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'id',
    'is_nullable'       => 0,
    'size'              => '32'
  },
  'a_session' => {
    'data_type'         => 'TEXT',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'a_session',
    'is_nullable'       => 0,
    'size'              => '65535'
  },
  'timestamp' => {
    'data_type'         => 'TIMESTAMP',
    'is_auto_increment' => 0,
    'default_value'     => \'CURRENT_TIMESTAMP',
    'timezone'          => 'UTC',
    'is_foreign_key'    => 0,
    'name'              => 'timestamp',
    'is_nullable'       => 1,
    'size'              => '0'
  },
);
__PACKAGE__->set_primary_key('id');

package Judge::ORM::series;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('series');

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
  'name' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'name',
    'is_nullable'       => 1,
    'size'              => '255'
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
);
__PACKAGE__->set_primary_key('id');

package Judge::ORM::contests;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('contests');

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
  'series_id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 1,
    'name'              => 'series_id',
    'is_nullable'       => 1,
    'size'              => '11',
  },
  'name' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'name',
    'is_nullable'       => 1,
    'size'              => '255'
  },
  'start_time' => {
    'data_type'         => 'TIMESTAMP',
    'is_auto_increment' => 0,
    'default_value'     => \'CURRENT_TIMESTAMP',
    'timezone'          => 'UTC',
    'is_foreign_key'    => 0,
    'name'              => 'start_time',
    'is_nullable'       => 1,
    'size'              => '0'
  },
  'duration' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'duration',
    'is_nullable'       => 1,
    'size'              => '11'
  },
  'visible' => {
    'data_type'         => 'TINYINT',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'visible',
    'is_nullable'       => 0,
    'size'              => '1'
  },
  'windowed' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => 0,
    'is_foreign_key'    => 0,
    'name'              => 'windowed',
    'is_nullable'       => 0,
    'size'              => '1'
  },
  'openbook' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => 0,
    'is_foreign_key'    => 0,
    'name'              => 'openbook',
    'is_nullable'       => 0,
    'size'              => '1'
  },
);
__PACKAGE__->set_primary_key('id');

package Judge::ORM::judgements;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('judgements');

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
  'submission_id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 1,
    'name'              => 'submission_id',
    'is_nullable'       => 0,
    'size'              => '11'
  },
  'status' => {
    'data_type'         => 'ENUM',
    'is_auto_increment' => 0,
    'default_value'     => 'WAITING',
    'is_foreign_key'    => 0,
    'name'              => 'status',
    'is_nullable'       => 0,
    'size'              => '13'
  },
  'testcase' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'testcase',
    'is_nullable'       => 0,
    'size'              => '255'
  },
);
__PACKAGE__->set_primary_key('id');

package Judge::ORM::submissions;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('submissions');

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
  'user_id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 1,
    'name'              => 'user_id',
    'is_nullable'       => 0,
    'size'              => '11'
  },
  'problem_id' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 1,
    'name'              => 'problem_id',
    'is_nullable'       => 0,
    'size'              => '11'
  },
  'time' => {
    'data_type'         => 'TIMESTAMP',
    'is_auto_increment' => 0,
    'default_value'     => \'CURRENT_TIMESTAMP',
    'timezone'          => 'UTC',
    'is_foreign_key'    => 0,
    'name'              => 'time',
    'is_nullable'       => 1,
    'size'              => '0'
  },
  'status' => {
    'data_type'         => 'ENUM',
    'is_auto_increment' => 0,
    'default_value'     => 'WAITING',
    'is_foreign_key'    => 0,
    'name'              => 'status',
    'is_nullable'       => 0,
    'size'              => '13'
  },
);
__PACKAGE__->set_primary_key('id');

package Judge::ORM::users;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('users');

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
  'username' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'username',
    'is_nullable'       => 0,
    'size'              => '255'
  },
  'realname' => {
    'data_type'         => 'VARCHAR',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'realname',
    'is_nullable'       => 0,
    'size'              => '255'
  },
  'administrator' => {
    'data_type'         => 'TINYINT',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'administrator',
    'is_nullable'       => 0,
    'size'              => '1'
  },
);
__PACKAGE__->set_primary_key('id');

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

package Judge::ORM::windows;
use base 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components(qw/ Core InflateColumn::DateTime/);
__PACKAGE__->table('windows');

__PACKAGE__->add_columns(
  'id' => {
    'data_type'         => 'integer',
    'is_auto_increment' => 1,
    'is_nullable'       => 0
  },
  'contest_id' => {
    'data_type'         => 'integer',
    'is_foreign_key'    => 1,
    'is_nullable'       => 0
  },
  'user_id' => {
    'data_type'         => 'integer',
    'is_foreign_key'    => 1,
    'is_nullable'       => 0
  },
  'start_time' => {
    'data_type'         => 'TIMESTAMP',
    'is_auto_increment' => 0,
    'default_value'     => \'CURRENT_TIMESTAMP',
    'timezone'          => 'UTC',
    'is_foreign_key'    => 0,
    'name'              => 'start_time',
    'is_nullable'       => 1,
    'size'              => '0'
  },
  'duration' => {
    'data_type'         => 'int',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'duration',
    'is_nullable'       => 1,
    'size'              => '11'
  },
);

package Judge::ORM::series;

__PACKAGE__->has_many( 'get_contests', 'Judge::ORM::contests', 'series_id' );

package Judge::ORM::contests;

__PACKAGE__->belongs_to( 'series_id', 'Judge::ORM::series' );

__PACKAGE__->has_many( 'get_problems',  'Judge::ORM::problems',  'contest_id' );
__PACKAGE__->has_many( 'get_windows',   'Judge::ORM::windows', 'contest_id' );

package Judge::ORM::judgements;

__PACKAGE__->belongs_to( 'submission_id', 'Judge::ORM::submissions' );

package Judge::ORM::submissions;

__PACKAGE__->belongs_to( 'user_id', 'Judge::ORM::users' );

__PACKAGE__->belongs_to( 'problem_id', 'Judge::ORM::problems' );

__PACKAGE__->has_many( 'get_judgements', 'Judge::ORM::judgements',
  'submission_id' );

package Judge::ORM::users;

__PACKAGE__->has_many( 'get_submissions', 'Judge::ORM::submissions', 'user_id');
__PACKAGE__->has_many( 'get_windows', 'Judge::ORM::windows', 'contest_id' );

package Judge::ORM::problems;

__PACKAGE__->belongs_to( 'contest_id', 'Judge::ORM::contests' );

__PACKAGE__->has_many( 'get_submissions', 'Judge::ORM::submissions',
  'problem_id' );

package Judge::ORM::windows;

__PACKAGE__->belongs_to( 'contest_id', 'Judge::ORM::contests' );
__PACKAGE__->belongs_to( 'user_id', 'Judge::ORM::users' );

package Judge::ORM;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

__PACKAGE__->register_class( 'sessions', 'Judge::ORM::sessions' );

__PACKAGE__->register_class( 'series', 'Judge::ORM::series' );

__PACKAGE__->register_class( 'contests', 'Judge::ORM::contests' );

__PACKAGE__->register_class( 'judgements', 'Judge::ORM::judgements' );

__PACKAGE__->register_class( 'submissions', 'Judge::ORM::submissions' );

__PACKAGE__->register_class( 'users', 'Judge::ORM::users' );

__PACKAGE__->register_class( 'problems', 'Judge::ORM::problems' );

__PACKAGE__->register_class( 'windows', 'Judge::ORM::windows' );

1;

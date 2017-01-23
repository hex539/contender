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

__PACKAGE__->has_many( 'get_submissions', 'Judge::ORM::submissions', 'user_id');
__PACKAGE__->has_many( 'get_windows', 'Judge::ORM::windows', 'contest_id' );

1;

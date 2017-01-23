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

1;

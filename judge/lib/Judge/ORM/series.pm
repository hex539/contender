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

__PACKAGE__->has_many( 'get_contests', 'Judge::ORM::contests', 'series_id' );

1;

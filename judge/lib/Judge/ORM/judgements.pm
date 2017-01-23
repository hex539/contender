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

__PACKAGE__->belongs_to( 'submission_id', 'Judge::ORM::submissions' );

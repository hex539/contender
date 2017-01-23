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

__PACKAGE__->belongs_to( 'user_id', 'Judge::ORM::users' );

__PACKAGE__->belongs_to( 'problem_id', 'Judge::ORM::problems' );

__PACKAGE__->has_many( 'get_judgements', 'Judge::ORM::judgements',
  'submission_id' );

1;

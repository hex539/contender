package Judge::ORM::contests;
use base 'DBIx::Class';
use strict;
use warnings;

use DateTime::Format::Pg;

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
  'window_duration' => {
    'data_type'         => 'interval',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'window_duration',
    'is_nullable'       => 0,
    'size'              => '11'
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

__PACKAGE__->inflate_column('window_duration', {
  inflate => sub {DateTime::Format::Pg->parse_interval(shift)},
  deflate => sub {DateTime::Format::Pg->format_interval(shift)},
});

__PACKAGE__->belongs_to( 'series_id', 'Judge::ORM::series' );

__PACKAGE__->has_many( 'get_problems',  'Judge::ORM::problems',  'contest_id' );
__PACKAGE__->has_many( 'get_windows',   'Judge::ORM::windows', 'contest_id' );

sub windowed {
  @_ == 1 or die 'Wrong number of arguments';
  my $self = shift // die;

  return defined $self->window_duration;
}

sub end_time {
  @_ == 1 or die 'Wrong number of arguments';
  my $self = shift // die;

  my $duration = $self->duration;
  return undef unless defined $duration;
  return $self->start_time->clone->add_duration($duration);
}

sub running {
  @_ == 2 or die 'Wrong number of arguments';
  my $self = shift // die;
  my $now = shift // die;

  my $start_time = $self->start_time;
  if (defined($start_time) && $now->epoch < $start_time->epoch) {
    return 0;
  }

  my $end_time = $self->end_time;
  if (defined($end_time) && $end_time->epoch <= $now->epoch) {
    return 0;
  }

  return 1;
}

1;

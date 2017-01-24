package Judge::ORM::windows;
use base 'DBIx::Class';
use strict;
use warnings;

use DateTime::Format::Pg;

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
    'data_type'         => 'interval',
    'is_auto_increment' => 0,
    'default_value'     => undef,
    'is_foreign_key'    => 0,
    'name'              => 'duration',
    'is_nullable'       => 1,
    'size'              => '11'
  },
);

__PACKAGE__->inflate_column('duration', {
  inflate => sub {DateTime::Format::Pg->parse_interval(shift)},
  deflate => sub {DateTime::Format::Pg->format_interval(shift)},
});

__PACKAGE__->belongs_to( 'contest_id', 'Judge::ORM::contests' );
__PACKAGE__->belongs_to( 'user_id', 'Judge::ORM::users' );

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

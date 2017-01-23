package Judge::ORM;
use base 'DBIx::Class::Schema';
use strict;
use warnings;

use Judge::ORM::sessions;
use Judge::ORM::series;
use Judge::ORM::contests;
use Judge::ORM::judgements;
use Judge::ORM::submissions;
use Judge::ORM::users;
use Judge::ORM::problems;
use Judge::ORM::windows;

__PACKAGE__->register_class( 'sessions', 'Judge::ORM::sessions' );
__PACKAGE__->register_class( 'series', 'Judge::ORM::series' );
__PACKAGE__->register_class( 'contests', 'Judge::ORM::contests' );
__PACKAGE__->register_class( 'judgements', 'Judge::ORM::judgements' );
__PACKAGE__->register_class( 'submissions', 'Judge::ORM::submissions' );
__PACKAGE__->register_class( 'users', 'Judge::ORM::users' );
__PACKAGE__->register_class( 'problems', 'Judge::ORM::problems' );
__PACKAGE__->register_class( 'windows', 'Judge::ORM::windows' );

1;

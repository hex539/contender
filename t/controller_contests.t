use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Judge';
use Judge::Controller::contests;

ok( request('/contests')->is_success, 'Request should succeed' );
done_testing();

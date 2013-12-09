use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Judge';
use Judge::Controller::problem;

ok( request('/problem')->is_success, 'Request should succeed' );
done_testing();

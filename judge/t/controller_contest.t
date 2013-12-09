use strict;
use warnings;
use Test::More;


use Catalyst::Test 'Judge';
use Judge::Controller::contest;

ok( request('/contest')->is_success, 'Request should succeed' );
done_testing();

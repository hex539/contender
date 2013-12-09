use strict;
use warnings;

use Judge;

my $app = Judge->apply_default_middlewares(Judge->psgi_app);
$app;


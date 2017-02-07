use 5.22.0;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use t::lib::TestContext;

my $t = t::lib::TestContext::set();


###  START TESTING  ###
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();


use 5.22.0;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Mojo::Base -strict;
use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use Test::More;
use Test::Mojo;

use t::lib::TestContext;
use t::lib::U;
my $t = t::lib::TestContext::set();


###  START TESTING  ###
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);
t::lib::U::debugResponse($t);

done_testing();


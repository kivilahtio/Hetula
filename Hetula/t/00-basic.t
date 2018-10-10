#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::More;
use Test::Mojo;

use t::lib::TestContext;
use t::lib::U;
my $t = t::lib::TestContext::set();


###  START TESTING  ###
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);
t::lib::U::debugResponse($t);

done_testing();


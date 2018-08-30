#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::More tests => 1;
use Test::Mojo;

use t::lib::TestContext;
use t::lib::U;
my $t = t::lib::TestContext::set();


subtest "Scenario: Handle a CORS pre-flight request", sub {
  plan tests => 10;
  my $origin = 'http://some.chinese.invader:8000';

  ok(1, "Given a CORS pre-flight request with Origin set");
  $t->options_ok('/api/v1/ssns' => {
    'Origin' => $origin,
  })
  ->status_is(200)
  ->json_has('/get',  'OPTIONS returns available endpoints, like GET')
  ->json_has('/post', 'OPTIONS returns available endpoints, like POST')
  ->header_is('Access-Control-Allow-Headers'  => 'Content-Type, X-Requested-With, X-CSRF-Token')
  ->header_is('Access-Control-Allow-Methods'  => 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
  ->header_is('Access-Control-Allow-Origin'   => $origin,                                         "User-agent's Origin is accepted")
  ->header_is('Access-Control-Expose-Headers' => 'X-CSRF-Token',                                  "CSRF-Token is exposed to the javascript frontend")
  ->header_like('Access-Control-Max-Age'      => qr/^\d+$/)
  ;
  t::lib::U::debugResponse($t);
};
done_testing();


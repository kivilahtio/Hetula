#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::More;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###



subtest "/api/v1/doc/index.html happy path", sub {
  $t->get_ok('/api/v1/doc/index.html')
    ->status_is(200)
    ->content_like(qr/Swagger UI/i, 'Swagger UI in reply');

  $t->get_ok('/api/v1/doc')
    ->status_is(301)
    ->header_is(Location => '/api/v1/doc/', 'Correct "Moved permanently" location');

  $t->get_ok('/api/v1/doc/css/style.css')
    ->status_is(200)
    ->content_like(qr/.swagger-section/, 'css looks legit');

#  print $t->tx->res->body;
};

done_testing();

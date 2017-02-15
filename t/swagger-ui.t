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

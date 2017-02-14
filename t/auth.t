use 5.22.0;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::U;
$ENV{MOJO_OPENAPI_DEBUG} = 1;
$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use PatronStore::Users;


subtest "Api V1 auth happy path", sub {
  my ($cookies, $sessionCookie, $csrfHeader, $login);

  #This is duplicated in t::lib::Auth::doPasswordLogin(), login using doPasswordLogin() in other test cases instead of manually duplicating this.
  ok(1, 'When authenticating with proper credentials');
  $login = {
    username => 'admin',
    password => '1234',
    organization => 'Vaara'
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(201);
  t::lib::U::debugResponse($t);
  $cookies = $t->tx->res->cookies;
  $sessionCookie = $cookies->[0];
  is($cookies->[0]->{name}, 'PaStor', 'Then the session cookie is set');
  $t->ua->cookie_jar->add($sessionCookie);
  $csrfHeader = $t->tx->res->headers->header('X-CSRF-Token');
  is(length($csrfHeader), 40, 'Cross-Site request forgery prevention header set and is a nice hash');


  ok(1, 'When checking if the authentication is still valid');
  $t->get_ok('/api/v1/auth')
    ->status_is(204, 'Then the authentication is still valid');
  t::lib::U::debugResponse($t);


  ok(1, 'When logging out');
  $t->delete_ok('/api/v1/auth')
    ->status_is(204);
  t::lib::U::debugResponse($t);
  $cookies = $t->tx->res->cookies;
  is($cookies->[0]->{expires}, 1, 'Then the session cookie is set to expire in the past');


  ok(1, 'When checking if the authentication is still valid');
  $t->get_ok('/api/v1/auth')
    ->status_is(404, 'Then the authentication is not valid')
    ->content_like(qr!PS::Exception::Auth::Authentication!, 'PS::Exception::Auth::Authentication received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 max_failed_login_count", sub {
  my ($login);
  $login = {
    username => 'admin',
    password => 'bad-pass-word-d',
    organization => 'Vaara'
  };
  $t->app->config->{max_failed_login_count} = 2;

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password 1')
    ->content_like(qr!PS::Exception::Auth::Password!, 'PS::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password 2')
    ->content_like(qr!PS::Exception::Auth::Password!, 'PS::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(403, 'Bad password 2+1')
    ->content_like(qr!PS::Exception::Auth::AccountBlocked!, 'PS::Exception::Auth::AccountBlocked received');
  t::lib::U::debugResponse($t);

  ok(PatronStore::Users::getUser({username => 'admin'})->unblockLogin(),
                        'When the user is unblocked');

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password can be given again')
    ->content_like(qr!PS::Exception::Auth::Password!, 'PS::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 unknown user", sub {
  my ($login);
  $login = {
    username => 'naku-admin',
    password => '1234',
    organization => 'Vaara'
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(404, 'User is unknown')
    ->content_like(qr!PS::Exception::User::NotFound!, 'PS::Exception::User::NotFound received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 unknown organization", sub {
  my ($login);
  $login = {
    username => 'admin',
    password => '1234',
    organization => 'Magic mushroom land'
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(404, 'Organization is unknown')
    ->content_like(qr!PS::Exception::Organization::NotFound!, 'PS::Exception::Organization::NotFound received');
  t::lib::U::debugResponse($t);
};

done_testing();


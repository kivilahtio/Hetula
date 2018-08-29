#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::More tests => 6;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::U;
use t::lib::Auth;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
#$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime;
use DateTime::Format::ISO8601;
use Hetula::Users;


subtest "Api V1 auth happy path", sub {
  plan tests => 16;
  my ($cookies, $sessionCookie, $csrfHeader, $login);

  #This is duplicated in t::lib::Auth::doPasswordLogin(), login using doPasswordLogin() in other test cases instead of manually duplicating this.
  ok(1, 'When authenticating with proper credentials');
  $login = {
    username => Hetula::Config::admin_name(),
    password => Hetula::Config::admin_pass(),
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
    ->content_like(qr!Hetula::Exception::Auth::Authentication!, 'Hetula::Exception::Auth::Authentication received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 max_failed_login_count", sub {
  plan tests => 13;
  my ($login);
  $login = {
    username => Hetula::Config::admin_name(),
    password => 'bad-pass-word-d',
    organization => 'Vaara'
  };
  Hetula::Config::max_failed_login_count(2);

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password 1')
    ->content_like(qr!Hetula::Exception::Auth::Password!, 'Hetula::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password 2')
    ->content_like(qr!Hetula::Exception::Auth::Password!, 'Hetula::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(403, 'Bad password 2+1')
    ->content_like(qr!Hetula::Exception::Auth::AccountBlocked!, 'Hetula::Exception::Auth::AccountBlocked received');
  t::lib::U::debugResponse($t);

  ok(Hetula::Users::getAdmin()->unblockLogin(),
                        'When the user is unblocked');

  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(401, 'Bad password can be given again')
    ->content_like(qr!Hetula::Exception::Auth::Password!, 'Hetula::Exception::Auth::Password received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 unknown user", sub {
  plan tests => 3;
  my ($login);
  $login = {
    username => 'naku-admin',
    password => '1234',
    organization => 'Vaara'
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(404, 'User is unknown')
    ->content_like(qr!Hetula::Exception::User::NotFound!, 'Hetula::Exception::User::NotFound received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 unknown organization", sub {
  plan tests => 3;
  my ($login);
  $login = {
    username => Hetula::Config::admin_name(),
    password => Hetula::Config::admin_pass(),
    organization => 'Magic mushroom land',
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(404, 'Organization is unknown')
    ->content_like(qr!Hetula::Exception::Organization::NotFound!, 'Hetula::Exception::Organization::NotFound received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 no permission", sub {
  plan tests => 20;
  my ($nakuadmin, $nakulogin);

  ok(1, 'Scenario: User with no permissions tries to do stuff');
  $nakuadmin = Hetula::Users::createUser({
    username => 'naku-admin-taas',
    password => '1234-4321',
    realname => 'Naku nakuttaja',
    organizations => [
      'Vaara',
    ],
  });
  $nakulogin = {
    username => 'naku-admin-taas',
    password => '1234-4321',
    organization => 'Vaara',
  };
  ok($nakuadmin, 'Given a user "Naku Nakuttaja" with no permissions');

  ok(t::lib::Auth::doPasswordLogin($t, $nakulogin),
     'And "Naku Nakuttaja" is logged in');

  ok(1, 'When he tries to add a new organization');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => 'Magic mushroom land'})
    ->status_is(403, 'Then he doesn\'t have permissions to do that')
    ->content_like(qr!Hetula::Exception::Auth::Authorization!, 'Hetula::Exception::Auth::Authorization received');
  t::lib::U::debugResponse($t);

  ok(1, 'When he tries to add a new user');
  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $nakuadmin->swaggerize)
    ->status_is(403, 'Then he doesn\'t have permissions to do that')
    ->content_like(qr!Hetula::Exception::Auth::Authorization!, 'Hetula::Exception::Auth::Authorization received');
  t::lib::U::debugResponse($t);



  ok(1, 'Scenario: Admin grants a priviledge and user can access something');
  ok($nakuadmin->grantPermission($t->app->getPermissionFromRouteString('POST', '/api/v1/organizations')),
        'Given the "organizations-post"-permission to "Naku Nakuttaja"');

  ok(1, 'When he tries to add a new organization');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => 'Magic mushroom land'})
    ->status_is(201, 'Then he miraculously succeeds!');
  t::lib::U::debugResponse($t);

  ok(1, 'When he tries to add a new user');
  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $nakuadmin->swaggerize)
    ->status_is(403, 'Then he doesn\'t have permissions to do that')
    ->content_like(qr!Hetula::Exception::Auth::Authorization!, 'Hetula::Exception::Auth::Authorization received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 check logs", sub {
  plan tests => 12;
  my ($logs, $url, $expectedLogs);
  my $vaara = Hetula::Organizations::getOrganization({name => 'Vaara'});
  my $lumme = Hetula::Organizations::getOrganization({name => 'Lumme'});
  sleep 1; #Make sure the current second changes so we dont accidentally mix previous log entries.
  #Since fetching logs is logged and the following login, we can test the time limits for following actions
  my $startOfSubtest = DateTime->now();
  t::lib::Auth::doPasswordLogin($t, {organization => 'Lumme'});

  $url = Mojo::URL->new('/api/v1/logs')->query({
    until => DateTime->now()->iso8601,
  });
  $t->get_ok($url)
    ->status_is(200, 'When all logs up until now are fetched');
  t::lib::U::debugResponse($t);
  $logs = $t->tx->res->json;
  $expectedLogs = [
    #   id   userid organizationid     request            description    ip    updatetime
    [qr/^\d+$/, 1,  $vaara->id,   '201 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  $vaara->id,   '204 GET /api/v1/auth',    undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  $vaara->id,   '204 DELETE /api/v1/auth', undef, '127.0.0.1', undef],
    [qr/^\d+$/, '', '',           '404 GET /api/v1/auth',    undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  $vaara->id,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  $vaara->id,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  '',           '403 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  $vaara->id,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [qr/^\d+$/, '', '',           '404 POST /api/v1/auth', qr/^Hetula::Exception::User::NotFound/, '127.0.0.1', undef],
    [qr/^\d+$/, 1,  '',           '404 POST /api/v1/auth', qr/^Hetula::Exception::Organization::NotFound/, '127.0.0.1', undef],
    [],[],[],[],[],
    [qr/^\d+$/, 1,  $lumme->id,   '201 POST /api/v1/auth',   undef, '127.0.0.1', undef],
  ];
  t::lib::U::testLogs($expectedLogs, $logs);


  $url = Mojo::URL->new('/api/v1/logs')->query({
    since => $startOfSubtest->iso8601,
  });
  $t->get_ok($url)
    ->status_is(200, 'When logs since the start of this subtest are fetched');
  t::lib::U::debugResponse($t);
  $logs = $t->tx->res->json;
  $expectedLogs = [
    #   id   userid organizationid      request                     description    ip    updatetime
    [qr/^\d+$/, 1, $lumme->id,   '201 POST /api/v1/auth',              undef, '127.0.0.1', undef],
    [qr/^\d+$/, 1, $lumme->id,   qr!^\Q200 GET /api/v1/logs?until=\E!, undef, '127.0.0.1', undef],
  ];
  t::lib::U::testLogs($expectedLogs, $logs);


  $url = Mojo::URL->new('/api/v1/logs')->query({
    organizationid => $lumme->id,
  });
  $t->get_ok($url)
    ->status_is(200, 'When all logs for organization "Lumme" are fetched');
  t::lib::U::debugResponse($t);
  $logs = $t->tx->res->json;
  $expectedLogs = [
    [],[],[],
  ];
  t::lib::U::testLogs($expectedLogs, $logs);
};


done_testing();


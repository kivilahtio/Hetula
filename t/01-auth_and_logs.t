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
use t::lib::U;
use t::lib::Auth;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
#$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime;
use DateTime::Format::ISO8601;
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
    organization => 'Magic mushroom land',
  };
  $t->post_ok('/api/v1/auth' => {Accept => '*/*'} => json => $login)
    ->status_is(404, 'Organization is unknown')
    ->content_like(qr!PS::Exception::Organization::NotFound!, 'PS::Exception::Organization::NotFound received');
  t::lib::U::debugResponse($t);
};


subtest "Api V1 no permission", sub {
  my ($nakuadmin, $nakulogin);
  eval {



  ok(1, 'Scenario: User with no permissions tries to do stuff');
  $nakuadmin = PatronStore::Users::createUser({
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
    ->content_like(qr!PS::Exception::Auth::Authorization!, 'PS::Exception::Auth::Authorization received');
  t::lib::U::debugResponse($t);

  ok(1, 'When he tries to add a new user');
  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $nakuadmin->swaggerize)
    ->status_is(403, 'Then he doesn\'t have permissions to do that')
    ->content_like(qr!PS::Exception::Auth::Authorization!, 'PS::Exception::Auth::Authorization received');
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
    ->content_like(qr!PS::Exception::Auth::Authorization!, 'PS::Exception::Auth::Authorization received');
  t::lib::U::debugResponse($t);

  };
  ok(0, $@) if $@;
};


subtest "Api V1 check logs", sub {
  my ($logs, $url, $expectedLogs);
  sleep 1; #Make sure the current second changes so we dont acidentally mix previous log entries.
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
    #id userid organizationid request       description ip      updatetime
    [1,  1, 1,   '201 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [2,  1, 1,   '204 GET /api/v1/auth',    undef, '127.0.0.1', undef],
    [3,  1, 1,   '204 DELETE /api/v1/auth', undef, '127.0.0.1', undef],
    [4,  '', '', '404 GET /api/v1/auth',    undef, '127.0.0.1', undef],
    [5,  1, 1,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [6,  1, 1,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [7,  1, '',  '403 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [8,  1, 1,   '401 POST /api/v1/auth',   undef, '127.0.0.1', undef],
    [9,  '', '', '404 POST /api/v1/auth', 'PS::Exception::User::NotFound :> No user found wit', '127.0.0.1', undef],
    [10, 1, '',   '404 POST /api/v1/auth', 'PS::Exception::Organization::NotFound :> No organi', '127.0.0.1', undef],
    [],[],[],[],[],
    [16, 1, 3,   '201 POST /api/v1/auth',   undef, '127.0.0.1', undef],
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
    #id userid organizationid request          description ip           updatetime
    [16,  1, 3,   '201 POST /api/v1/auth',          undef, '127.0.0.1', undef],
    [17,  1, 3,   qr!^\Q200 GET /api/v1/logs?until=\E!, undef, '127.0.0.1', undef],
  ];
  t::lib::U::testLogs($expectedLogs, $logs);


  $url = Mojo::URL->new('/api/v1/logs')->query({
    organizationid => 3,
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


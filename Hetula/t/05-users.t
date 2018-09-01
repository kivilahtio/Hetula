#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::Most tests => 7;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::Auth;
use t::lib::U;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
#$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime::Format::ISO8601;
use Hetula::Organizations;
use Hetula::Users;
use Hetula::Permissions;


subtest "Scenario: Api V1 CRUD users happy path", sub {
  plan tests => 27;
  my ($body, $pertti, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When POSTing a new User "Pertti Peräsmies"');
  $pertti = {
    username => 'pp',
    password => 'pp699',
    realname => 'Peräsmies, Pertti',
  };

  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $pertti)
    ->status_is(201, 'Then a new user is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{username}, 'pp', 'And has the correct username');
  is($body->{realname}, 'Peräsmies, Pertti', 'And has the correct realname');
  ok($body->{password}, 'And the password is returned');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  ok($body->{id} =~ /^\d+$/, 'And the id is set');
  $id = $body->{id};


  ok(1, 'When GETting Mr. Peräsmies');
  $t->get_ok("/api/v1/users/$id")
    ->status_is(200, 'Then the user is returned');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{username}, 'pp', 'And has the correct username');
  is($body->{realname}, 'Peräsmies, Pertti', 'And has the correct realname');
  ok($body->{password}, 'And the password is returned');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, $id,       'And the id is ok');


  ok(1, 'When DELETEing Mr. Peräsmies');
  $t->delete_ok("/api/v1/users/$id")
    ->status_is(204, 'Then the User is deleted');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd User');
  $t->get_ok("/api/v1/users/$id")
    ->status_is(404, 'Then the user is not found')
    ->content_like(qr!Hetula::Exception::User::NotFound!, 'And the content contains the correct Hetula::Exception::User::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};



subtest "Scenario: Api V1 Create the same user many times", sub {
  plan tests => 7;
  my ($aila);

  ok(1, 'When POSTing the User');
  $aila = {
    username => 'ak',
    password => 'ak96',
    realname => 'Kurkela, Aila',
  };
  my $ailaName = $aila->{realname};

  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $aila)
    ->status_is(201, 'Then a new user is created');

  ok(1, 'When POSTing the user again, even if it already exists');
  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $aila)
    ->status_is(409,        'Then the server responds with a conflict.')
    ->json_has('/realname', 'And the response has the duplicate users name');
  t::lib::U::debugResponse($t);
};



subtest "Scenario: Api V1 users - PUT bad permissions and rollback partial changes", sub {
  plan tests => 7;

  my ($body, $user, $newData, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);

  ok(1, 'When PUTing partially bad permissions and modifying user attributes');
  $newData = {
    username => 'rollback',
    realname => 'To be rolled back modification',
    permissions => [
      'non-existing-permission',
      'users-get',
    ],
  };
  $t->put_ok("/api/v1/users/1" => {Accept => '*/*'} => json => $newData)
    ->status_is(404, "Then setting user's permissions fails")
    ->content_like(qr!Hetula::Exception::Permission::NotFound!, 'And the content contains the correct Hetula::Exception::Permission::NotFound exception')
    ->content_like(qr!non-existing-permission!,                 'And the content contains the correct missing permission');
  t::lib::U::debugResponse($t);

  $user = Hetula::Users::getAdmin();
  is(Hetula::Config::admin_name(), $user->username, 'And changes to username are rolled back');
  is(scalar(@{Hetula::Permissions::listPermissions()}), $user->permissions()->count(), 'And the admin still has all the permissions');
};



subtest "Scenario: Api V1 CRUD users' permissions", sub {
  plan tests => 18;
  my ($body, $maija, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When POSTing a new User "Maija Meikäläinen"');
  $maija = {
    username => 'mm',
    password => 'majtsu',
    realname => 'Meikäläinen, Maija',
  };

  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $maija)
    ->status_is(201, 'Then a new user is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  $id = $body->{id};
  ok($body->{permissions}, 'And has permissions-attribute');
  is(scalar(@{$body->{permissions}}), 0, 'But no permissions');
  ok($id, 'And has an id');


  ok(1, 'When PUTing permissions as keys to "Maija Meikäläinen"');
  $maija = {
    username => 'mm',
    realname => 'Meikäläinen, Maija',
    permissions => [
      'users-id-delete',
      'users-get',
    ],
  };
  $t->put_ok("/api/v1/users/$id" => {Accept => '*/*'} => json => $maija)
    ->status_is(200, 'Then an existing user is modified');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{permissions}, 'And has permissions-attribute');
  is($body->{permissions}->[0], 'users-get',       'And the permission names are sorted alphabetically 2');
  is($body->{permissions}->[1], 'users-id-delete', 'And the permission names are sorted alphabetically 1');


  ok(1, 'When PUTing overlapping permissions as keys to "Maija Meikäläinen"');
  $maija = {
    username => 'mm',
    realname => 'Meikäläinen, Maija',
    permissions => [
      'users-get',
      'users-post',
    ],
  };
  $t->put_ok("/api/v1/users/$id" => {Accept => '*/*'} => json => $maija)
    ->status_is(200, 'Then an existing user is modified');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{permissions}, 'And has permissions-attribute');
  is($body->{permissions}->[0], 'users-get',    'And the permission names are sorted alphabetically 1');
  is($body->{permissions}->[1], 'users-post',   'And the permission names are sorted alphabetically 2');
};



subtest "Scenario: Api V1 users - Prevent Grant permissions the user is not allowed to grant", sub {
  plan tests => 14;
  my ($badUser, $escalatedPermissions, $id) = @_;
  my $badUserAttributes = {
    realname => 'Bad Tango',
    username => 'bt',
    password => 'alfa romeo caesar',
    organizations => [Hetula::Config::admin_organization()],
    permissions => [qw(users-post users-id-put ssns-post organizations-get)]
  };
  ok($badUser = Hetula::Users::createUser(Storable::dclone($badUserAttributes)), "Given a user with limited permissions is logged in");

  t::lib::Auth::doPasswordLogin($t, $badUserAttributes);

  ok(1, 'When PUTing excessive permissions to try privilege escalation');
  $escalatedPermissions = {
    permissions => [
      qw(permissions-post users-post ssns-get ssns-id-get)
    ],
  };
  $t->put_ok("/api/v1/users/".$badUser->id => {Accept => '*/*'} => json => Storable::dclone($escalatedPermissions))
    ->status_is(403, "Then setting user's excessive permissions fails")
    ->content_like(qr!Hetula::Exception::Auth::Authorization!, 'And the content contains the correct Hetula::Exception::Auth::Authorization exception')
    ->content_like(qr!permissions-post ssns-get ssns-id-get!,  'And the content contains the correct unauthorized permission');
  t::lib::U::debugResponse($t);


  my $badNewUserAttributes = {
    realname => 'Bad Tango',
    username => 'bt2',
    password => 'disordered',
    permissions => $escalatedPermissions->{permissions},
  };
  ok(1, 'When POSTing excessive permissions to try privilege escalation');
  $t->put_ok("/api/v1/users/1" => {Accept => '*/*'} => json => Storable::dclone($badNewUserAttributes))
    ->status_is(403, "Then setting user's excessive permissions fails")
    ->content_like(qr!Hetula::Exception::Auth::Authorization!, 'And the content contains the correct Hetula::Exception::Auth::Authorization exception')
    ->content_like(qr!permissions-post ssns-get ssns-id-get!,  'And the content contains the correct unauthorized permission');
  t::lib::U::debugResponse($t);

  throws_ok(sub { Hetula::Users::getUser({username => $badNewUserAttributes->{username}}) }, 'Hetula::Exception::User::NotFound',                                    "And the privilege escalation attempted new user is not created");
  throws_ok(sub { Hetula::Permissions::hasPermissions($badUser, Storable::dclone($escalatedPermissions->{permissions})) }, 'Hetula::Exception::Auth::Authorization', 'And the privilege escalation failed for the logged in user');
  throws_ok(sub { Hetula::Permissions::hasPermissions($badUser, Storable::dclone($escalatedPermissions->{permissions})) }, qr/permissions-post ssns-get ssns-id-get/,'and the missing permissions were correctly detected');
};



subtest "Scenario: Api V1 users - PUT bad organizations and rollback partial changes", sub {
  plan tests => 7;

  my ($body, $user, $newData, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);

  ok(1, 'When PUTing partially bad organizations and modifying user attributes');
  $newData = {
    username => 'rollback',
    realname => 'To be rolled back modification',
    organizations => [
      'non-existing-organization',
      'magic-mushroom-land',
    ],
  };
  $t->put_ok("/api/v1/users/1" => {Accept => '*/*'} => json => $newData)
    ->status_is(404, "Then setting user's organizations fails")
    ->content_like(qr!Hetula::Exception::Organization::NotFound!,      'And the content contains the correct Hetula::Exception::Organization::NotFound exception')
    ->content_like(qr!non-existing-organization magic-mushroom-land!,  'And the content contains the correct missing permission');
  t::lib::U::debugResponse($t);

  $user = Hetula::Users::getAdmin();
  is(Hetula::Config::admin_name(), $user->username, 'And changes to username are rolled back');
  is(scalar(@{Hetula::Permissions::listPermissions()}), $user->permissions()->count(), 'And the admin still has all the permissions');
};



subtest "Api V1 CRUD users' organizations", sub {
  plan tests => 21;
  my ($body, $äijä, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When POSTing a new User "Pää-Äijä"');
  $äijä = {
    username => 'pa',
    password => 'äijät',
    realname => 'Pää-Äijä',
    organizations => [
      'Vaara',
    ],
  };

  $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $äijä)
    ->status_is(201, 'Then a new user is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  $id = $body->{id};
  ok($body->{organizations}, 'And has organizations-attribute');
  is(scalar(@{$body->{organizations}}), 1, 'And one organization he is part of');
  is($body->{organizations}->[0], 'Vaara', 'And the name of the organization is Vaara');
  ok($id, 'And has an id');


  ok(1, 'When PUTing overlapping organizations to "Pää-Äijä"');
  $äijä = {
    username => 'pa',
    realname => 'Pää-Äijä',
    organizations => [
      'Lappi',
      'Lumme',
    ],
  };
  $t->put_ok("/api/v1/users/$id" => {Accept => '*/*'} => json => $äijä)
    ->status_is(200, 'Then an existing user is modified');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lappi', 'And the organization names are sorted alphabetically 1');
  is($body->{organizations}->[1], 'Lumme', 'And the organization names are sorted alphabetically 2');
  is(scalar(@{$body->{organizations}}), 2, 'And the old organization is no longer on the list');


  ok(1, 'When GETing "Pää-Äijä"');
  $t->get_ok("/api/v1/users/$id")
    ->status_is(200, 'Then a "Pää-Äijä" is retrieved');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lappi', 'And the organization names are sorted alphabetically 1');
  is($body->{organizations}->[1], 'Lumme', 'And the organization names are sorted alphabetically 2');
  is(scalar(@{$body->{organizations}}), 2, 'And the old organization is no longer on the list');
};


done_testing();


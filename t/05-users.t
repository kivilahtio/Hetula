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
use t::lib::Auth;
use t::lib::U;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
#$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime::Format::ISO8601;
use Encode qw(encode_utf8);
use Hetula::Organizations;


subtest "Api V1 CRUD users happy path", sub {
  my ($body, $pertti) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, encode_utf8('When POSTing a new User "Pertti Peräsmies"'));
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
  is($body->{id}, 2,         'And the id is 2');


  ok(1, encode_utf8('When GETting Mr. Peräsmies'));
  $t->get_ok('/api/v1/users/2')
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
  is($body->{id}, 2,         'And the id is 2');


  ok(1, encode_utf8('When DELETEing Mr. Peräsmies'));
  $t->delete_ok('/api/v1/users/2')
    ->status_is(204, 'Then the User is deleted');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd User');
  $t->get_ok('/api/v1/users/2')
    ->status_is(404, 'Then the user is not found')
    ->content_like(qr!PS::Exception::User::NotFound!, 'And the content contains the correct PS::Exception::User::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};



subtest "Api V1 CRUD users' permissions", sub {
  my ($body, $maija, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, encode_utf8('When POSTing a new User "Maija Meikäläinen"'));
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


  ok(1, encode_utf8('When PUTing permissions as keys to "Maija Meikäläinen"'));
  $maija = {
    username => 'mm',
    realname => 'Meikäläinen, Maija',
    permissions => [
      'users-delete',
      'users-get',
    ],
  };
  $t->put_ok("/api/v1/users/$id" => {Accept => '*/*'} => json => $maija)
    ->status_is(200, 'Then an existing user is modified');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{permissions}, 'And has permissions-attribute');
  is($body->{permissions}->[0], 'users-delete', 'And the permission names are sorted alphabetically 1');
  is($body->{permissions}->[1], 'users-get',    'And the permission names are sorted alphabetically 2');


  ok(1, encode_utf8('When PUTing overlapping permissions as keys to "Maija Meikäläinen"'));
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



subtest "Api V1 CRUD users' organizations", sub {
  my ($body, $äijä, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, encode_utf8('When POSTing a new User "Pää-Äijä"'));
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


  ok(1, encode_utf8('When PUTing overlapping organizations to "Pää-Äijä"'));
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


  ok(1, encode_utf8('When GETing "Pää-Äijä"'));
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


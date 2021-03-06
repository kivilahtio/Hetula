#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::More tests => 2;
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


subtest "Api V1 CRUD organizations happy path", sub {
  plan tests => 34;
  my ($body, $id);
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When GETting all organizations');
  $t->get_ok("/api/v1/organizations")
    ->status_is(200, 'Then all the organizations are returned');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is(scalar(@{$body}), 5, 'And got all organizations');
  my @nonAdminOrganizations = grep {$_->{name} ne Hetula::Config::admin_organization()} @$body; #Remove the admin_organization which is automatically created, because it is impossible to predict what it will be and how it relates to the sort order.
  is($nonAdminOrganizations[0]->{name}, 'Lappi', 'And the organizations are alphabetically sorted 1');
  is($nonAdminOrganizations[1]->{name}, 'Lumme', 'And the organizations are alphabetically sorted 2');
  is($nonAdminOrganizations[2]->{name}, 'Outi',  'And the organizations are alphabetically sorted 3');
  is($nonAdminOrganizations[3]->{name}, 'Vaara', 'And the organizations are alphabetically sorted 4');
  ok($nonAdminOrganizations[3]->{id},            'And a organization has an id');
  ok(DateTime::Format::ISO8601->parse_datetime($body->[3]->{createtime}),
                                                   'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->[3]->{updatetime}),
                                                   'And the updatetime is in ISO8601');


  ok(1, 'When POSTing a new organization "Magic mushroom land"');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => 'Magic mushroom land'})
    ->status_is(201, 'Then the organization is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{name}, 'Magic mushroom land', 'And the name is "Magic mushroom land"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  ok($body->{id},            'And the id exists');
  $id = $body->{id};


  ok(1, 'When GETting the Magic mushroom land-organization');
  $t->get_ok("/api/v1/organizations/$id")
    ->status_is(200, 'Then the organization is returned');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{name}, 'Magic mushroom land', 'And the name is "Magic mushroom land"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, $id,       'And the id is the same');


  ok(1, 'When DELETEing the Magic mushroom land-organization');
  $t->delete_ok("/api/v1/organizations/$id")
    ->status_is(204, 'Then the organization is deleted');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd Magic mushroom land-organization');
  $t->get_ok("/api/v1/organizations/$id")
    ->status_is(404, 'Then the organization is not found')
    ->content_like(qr!Hetula::Exception::Organization::NotFound!, 'And the content contains the correct Hetula::Exception::Organization::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};



subtest "Scenario: Api V1 Create the same organization many times", sub {
  plan tests => 6;
  my ($organizationName) = ('Shroomery');
  t::lib::Auth::doPasswordLogin($t);

  ok(1, 'Given the organization is created.');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => $organizationName});

  ok(1, 'When POSTing the organization again, even if it already exists');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => $organizationName})
    ->status_is(409,    'Then the server responds with a conflict.')
    ->json_has('/name', 'And the response is the duplicate organization');
  t::lib::U::debugResponse($t);
};


done_testing();


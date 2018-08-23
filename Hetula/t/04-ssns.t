#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";

use Mojo::Base -strict;
use Hetula::Pragmas;

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
use Hetula::Ssns;



subtest "Api V1 creating invalid ssns", sub {
  my ($body) = @_;
  eval {

  t::lib::Auth::doPasswordLogin($t, {organization => 'Vaara'});


  ok(1, 'When POSTing an invalid ssn "23091992A7866"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '23091992A7866'})
    ->status_is(400, 'Then the ssn is deemed invalid');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok($body =~ /Hetula::Exception::Ssn::Invalid/, 'And the returned error is generic');

  ok(1, 'When POSTing an invalid ssn "930992-7866"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '930992A7866'})
    ->status_is(400, 'Then the ssn is deemed invalid');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok($body =~ /Hetula::Exception::Ssn::Invalid/, 'And the returned error describes the validation error in detail');
  ok($body =~ /Bad day '93'/,                'And the detail is specifically about a bad day');

  ok(1, 'When POSTing an invalid ssn "230992%7866"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '230992%7866'})
    ->status_is(400, 'Then the ssn is deemed invalid');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok($body =~ /Hetula::Exception::Ssn::Invalid/, 'And the returned error describes the validation error in detail');
  ok($body =~ /Unknown century separator/,     'And the detail is specifically about a bad century separator');

  ok(1, 'When POSTing an invalid ssn "230992-786A"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '230992-786A'})
    ->status_is(400, 'Then the ssn is deemed invalid');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok($body =~ /Hetula::Exception::Ssn::Invalid/, 'And the returned error describes the validation error in detail');
  ok($body =~ /Given check character 'A'/,   'And the detail is specifically about a bad checksum');

  };
  ok(0, $@) if $@;
};



subtest "Api V1 CRUD ssns happy path", sub {
  my ($body) = @_;
  eval {

  t::lib::Auth::doPasswordLogin($t, {organization => 'Vaara'});


  ok(1, 'When POSTing a new ssn "050928+4784"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '050928+4784', notes => 'Ällikällä lyöty'})
    ->status_is(201, 'Then the ssn is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{ssn}, '050928+4784', 'And the ssn is "050928+4784"');
  is($body->{notes}, 'Ällikällä lyöty', encode_utf8('And the notes is "Ällikällä lyöty"'));
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, 1,         'And the id is 1');


  ok(1, 'When POSTing the ssn "050928+4784" again');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '050928+4784'})
    ->status_is(409, 'Then an error is returned about an existing ssn');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{ssn}, '050928+4784', 'And the ssn is "050928+4784"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, 1,         'And the id is 1');


  ok(1, 'When GETting the ssn "050928+4784"');
  $t->get_ok('/api/v1/ssns/1')
    ->status_is(200, 'Then the ssn is returned');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{ssn}, '050928+4784', 'And the ssn is "050928+4784"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, 1,         'And the id is 1');


  ok(1, 'When DELETEing the "050928+4784"-ssn');
  $t->delete_ok('/api/v1/ssns/1')
    ->status_is(204, 'Then the ssn is deleted');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd ssn');
  $t->get_ok('/api/v1/ssns/1')
    ->status_is(404, 'Then the ssn is not found')
    ->content_like(qr!Hetula::Exception::Ssn::NotFound!, 'And the content contains the correct Hetula::Exception::Ssn::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');

  };
  ok(0, $@) if $@;
};


subtest "Api V1 multiple organizations access the same ssn", sub {
  my ($body, $ssn, $id) = @_;

  eval {
  ok(t::lib::Auth::doPasswordLogin($t, {organization => 'Vaara'}),
     'Given a login session from organization Vaara');

  ok(1, 'When POSTing a new ssn "050928+4784"');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '050928+4784'})
    ->status_is(201, 'Then the ssn is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  $id = $body->{id};
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Vaara', 'And the organization names are sorted alphabetically');
  is(scalar(@{$body->{organizations}}), 1, 'And there are no extra organizations on the list');
  ok($id, 'And has an id');


  ok(t::lib::Auth::doPasswordLogin($t, {organization => 'Lumme'}),
     'Given a login session from organization Lumme');

  ok(1, 'When POSTing the same ssn "050928+4784" from another organization');
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => {ssn => '050928+4784'})
    ->status_is(200, 'Then a new organization has been added to a existing ssn');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lumme', 'And the organization names are sorted alphabetically 1');
  is($body->{organizations}->[1], 'Vaara', 'And the organization names are sorted alphabetically 2');
  is(scalar(@{$body->{organizations}}), 2, 'And there are no extra organizations on the list');


  ok(t::lib::Auth::doPasswordLogin($t, {organization => 'Lappi'}),
     'Given a login session from organization Lappi');

  ok(1, 'When POSTing the "050928+4784"-ssn with a given set of organizations');
  $ssn = {
    ssn => '050928+4784',
    organizations => [
      'Outi',
      'Lappi',
    ],
  };
  $t->post_ok('/api/v1/ssns' => {Accept => '*/*'} => json => $ssn)
    ->status_is(200, 'Then a new organization has been added to a existing ssn, but the attached organizations have been ignored');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lappi', 'And the organization names are sorted alphabetically 1');
  is($body->{organizations}->[1], 'Lumme', 'And the organization names are sorted alphabetically 2');
  is($body->{organizations}->[2], 'Vaara', 'And the organization names are sorted alphabetically 3');
  is(scalar(@{$body->{organizations}}), 3, 'And there are no extra organizations on the list');


  ok(1, encode_utf8('When DELETEing the ssn'));
  $t->delete_ok("/api/v1/ssns/$id")
    ->status_is(204, "Then the Lappi-organization's ownership of the ssn is deleted");
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, encode_utf8('When GETing the deleted ssn'));
  $t->get_ok("/api/v1/ssns/$id")
    ->status_is(404, "Then the Lappi-organization no longer can get the ssn")
    ->content_like(qr!Hetula::Exception::Ssn::NotFound!, 'And the content contains the correct Hetula::Exception::Ssn::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');


  ok(t::lib::Auth::doPasswordLogin($t, {organization => 'Vaara'}),
     'Given a login session from organization Vaara');

  ok(1, encode_utf8('When GETing the ssn'));
  $t->get_ok("/api/v1/ssns/$id")
    ->status_is(200, "Then the ssn is returned");
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lumme', 'And the organization names are sorted alphabetically 1');
  is($body->{organizations}->[1], 'Vaara', 'And the organization names are sorted alphabetically 2');
  is(scalar(@{$body->{organizations}}), 2, 'And there are no extra organizations on the list');


  ok(1, encode_utf8('When DELETEing the ssn'));
  $t->delete_ok("/api/v1/ssns/$id")
    ->status_is(204, "Then the Vaara-organization's ownership of the ssn is deleted");
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, encode_utf8('When GETing the deleted ssn'));
  $t->get_ok("/api/v1/ssns/$id")
    ->status_is(404, "Then the Vaara-organization no longer can get the ssn")
    ->content_like(qr!Hetula::Exception::Ssn::NotFound!, 'And the content contains the correct Hetula::Exception::Ssn::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');


  ok(t::lib::Auth::doPasswordLogin($t, {organization => 'Lumme'}),
     'Given a login session from organization Lumme');

  ok(1, encode_utf8('When GETing the ssn'));
  $t->get_ok("/api/v1/ssns/$id")
    ->status_is(200, "Then the ssn is returned");
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok($body->{organizations}, 'And has organizations-attribute');
  is($body->{organizations}->[0], 'Lumme', 'And the organization names are sorted alphabetically');
  is(scalar(@{$body->{organizations}}), 1, 'And there are no extra organizations on the list');


  ok(1, encode_utf8('When DELETEing the ssn'));
  $t->delete_ok("/api/v1/ssns/$id")
    ->status_is(204, "Then the Lumme-organization's ownership of the ssn is deleted");
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, encode_utf8('When GETing the deleted ssn'));
  $t->get_ok("/api/v1/ssns/$id")
    ->status_is(404, "Then the Lumme-organization no longer can get the ssn")
    ->content_like(qr!Hetula::Exception::Ssn::NotFound!, 'And the content contains the correct Hetula::Exception::Ssn::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');


  ok(1, 'Finally. All organizations have deleted their reference to the ssn, so it is removed from the database');
  $ssn = undef;
  try {
    $ssn = Hetula::Ssns::getSsn({id => $id});
  } catch {
    is(ref($_), 'Hetula::Exception::Ssn::NotFound', 'Then no ssn is found in the db');
  }
  };
  ok(0, ref($@)." :> $@") if $@;
};


done_testing();


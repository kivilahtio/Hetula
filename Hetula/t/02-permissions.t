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


subtest "Api V1 verify default route permissions", sub {
  my ($body, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When GETting all the permissions');
  $t->get_ok("/api/v1/permissions")
    ->status_is(200, 'Then a ton of permissions is retrieved');
  t::lib::U::debugResponse($t);
  my $permissions = $t->tx->res->json;
  my $expected = [
    #id        name           createtime updatetime
    [qr/^\d+$/, 'auth-delete',  undef, undef],
    [qr/^\d+$/, 'auth-get',     undef, undef],
    [qr/^\d+$/, 'auth-post',    undef, undef],
    [qr/^\d+$/, 'logs-get',     undef, undef],
    [],[],[],[],[],[],[],[],[],[],[],[],[],[],
    [qr/^\d+$/, 'users-put',    undef, undef],
  ];
  t::lib::U::testPermissions($expected, $permissions);
};


subtest "Api V1 CRUD permissions happy path", sub {
  my ($body, $id) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When POSTing a new permission "test-put"');
  $t->post_ok('/api/v1/permissions' => {Accept => '*/*'} => json => {name => 'test-put'})
    ->status_is(201, 'Then the permission is created');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{name}, 'test-put', 'And the name is "test-put"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  ok($body->{id},            'And the id exists');
  $id = $body->{id};


  ok(1, 'When GETting the test-put -permission');
  $t->get_ok("/api/v1/permissions/$id")
    ->status_is(200, 'Then the permission is returned');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is($body->{name}, 'test-put', 'And the name is "test-put"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, $id,       'And the id is the same');


  ok(1, 'When DELETEing the test-put -permission');
  $t->delete_ok("/api/v1/permissions/$id")
    ->status_is(204, 'Then the permission is deleted');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd test-put -permission');
  $t->get_ok("/api/v1/permissions/$id")
    ->status_is(404, 'Then the permission is not found')
    ->content_like(qr!Hetula::Exception::Permission::NotFound!, 'And the content contains the correct Hetula::Exception::Permission::NotFound exception');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};


done_testing();


use 5.22.0;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::Auth;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime::Format::ISO8601;


subtest "Api V1 CRUD organizations happy path", sub {
  my ($body) = @_;
  t::lib::Auth::doPasswordLogin($t);


  ok(1, 'When POSTing a new organization "Vaara"');
  $t->post_ok('/api/v1/organizations' => {Accept => '*/*'} => json => {name => 'Vaara'}, 'descr--------')
    ->status_is(201, 'Then the organization is created');
  print $t->tx->res->text;
  $body = $t->tx->res->json;
  is($body->{name}, 'Vaara', 'And the name is "Vaara"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, 1,         'And the id is 1');


  ok(1, 'When GETting the Vaara-organization');
  $t->get_ok('/api/v1/organizations/Vaara')
    ->status_is(200, 'Then the organization is returned');
  print $t->tx->res->text;
  $body = $t->tx->res->json;
  is($body->{name}, 'Vaara', 'And the name is "Vaara"');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{createtime}),
                             'And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($body->{updatetime}),
                             'And the updatetime is in ISO8601');
  is($body->{id}, 1,         'And the id is 1');


  ok(1, 'When DELETEing the Vaara-organization');
  $t->delete_ok('/api/v1/organizations/Vaara')
    ->status_is(204, 'Then the organization is deleted');
  #print $t->tx->res->text;
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd Vaara-organization');
  $t->get_ok('/api/v1/organizations/Vaara')
    ->status_is(404, 'Then the organization is not found')
    ->content_like(qr!PS::Exception::Auth::Authentication!, 'And the content contains the correct PS::Exception::Organization::NotFound exception');
  #print $t->tx->res->text;
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};


done_testing();


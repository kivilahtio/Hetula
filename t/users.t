use 5.22.0;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

use Mojo::Base -strict;
use Mojo::ByteStream 'b';

use Test::More;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::Auth;
#$ENV{MOJO_OPENAPI_DEBUG} = 1;
$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
#$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime::Format::ISO8601;
use Encode qw(encode_utf8);


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
  #print $t->tx->res->text;
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
  #print $t->tx->res->text;
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
  #print $t->tx->res->text;
  $body = $t->tx->res->text;
  ok(not($body), 'And there is no content');


  ok(1, 'When GETting the DELETEd User');
  $t->get_ok('/api/v1/users/2')
    ->status_is(404, 'Then the user is not found')
    ->content_like(qr!PS::Exception::User::NotFound!, 'And the content contains the correct PS::Exception::User::NotFound exception');
  #print $t->tx->res->text;
  $body = $t->tx->res->json;
  ok(not($body), 'And there is no json body');
};


done_testing();


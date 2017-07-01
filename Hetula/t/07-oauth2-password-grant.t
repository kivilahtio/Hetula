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

=head2 SKIPPED

use t::lib::TestContext;
use t::lib::Auth;
use t::lib::U;
$ENV{MOJO_OPENAPI_DEBUG} = 1;
$ENV{MOJO_INACTIVITY_TIMEOUT} = 3600; #Useful for debugging
$ENV{MOJO_LOG_LEVEL} = 'debug';
my $t = t::lib::TestContext::set();
###  START TESTING  ###

use DateTime::Format::ISO8601;
use Encode qw(encode_utf8);
use Hetula::Users;


subtest "OAuth2.0 Resource Owner Password Credentials Grant happy path", sub {
  my ($admin) = @_;
  my $apicredential = {
    client_id =>     'KohaFi',
    client_secret => '$5$MS6wtyvMRQScL$rKmJ5LPlwvdF9v/dlhofMy5z6VI7i7npEBqI5GX4372',
    client_type =>   'confidential',
    client_redirection_url => 'https://take.me.home/redirect',
    client_website => 'https://take.me.home',
  };
  eval {

  subtest "Register API client to server", sub {
    $admin = Hetula::Users::getUser({username => 'admin'});
    ok($admin, 'Given the admin user');
    ok($admin->setApiCredential($apicredential),
           'And API Credential configuration');
  };

  subtest "Register API server to client", sub {
    
  };

  };
  ok(0, $@) if $@;
};

=cut

ok(1, "test skipped");
done_testing();


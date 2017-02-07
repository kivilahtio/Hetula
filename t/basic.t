use 5.22.0;

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use Test::MockModule;

use t::lib::TestContext;
use t::lib::Mock::Users;

t::lib::TestContext::set();

my $module = Test::MockModule->new('PatronStore::Users');
$module->mock('getUser', \&t::lib::Mock::Users::getUser);

my $t = Test::Mojo->new('PatronStore');
$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();


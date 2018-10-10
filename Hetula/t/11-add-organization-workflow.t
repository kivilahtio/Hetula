#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../";

use Mojo::Base -strict;
use Hetula::Pragmas;

use Test::Most tests => 1;
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


subtest "Feature: A new organization is added to Hetula, and the organization superuser adds other users", sub {
  plan tests => 2;

  my ($organization, $orgName, $orgSuperUser, $orgSuperUserName, $orgSuperUserPass) = (undef, 'HAMK', undef, 'hTester', 'testis');

  subtest "Scenario: Add an Organization using the addOrganization command", sub {
    plan tests => 3;

    my $commands = $t->app->commands;
    ok($commands->run('addOrganization', '-o', $orgName, '-u', $orgSuperUserName, '-p', $orgSuperUserPass), "Invoked the addOrganization-command");

    lives_ok(sub { $orgSuperUser = Hetula::Users::getUser({username => $orgSuperUserName}) }, 'Organization superuser added');

    lives_ok(sub { $organization = Hetula::Organizations::getOrganization({name => $orgName}) }, 'Organization added');
  };


  subtest "Scenario: Login as the organization superuser and add other users", sub {
    plan tests => 9;

    my ($body);

    ok(1, 'Given the organization super user has logged in');
    t::lib::Auth::doPasswordLogin($t, {username => $orgSuperUserName, password => $orgSuperUserPass, organization => $orgName});

    ok(1, 'When POSTing a new basic User "BUser123"');
    my $buser123 = {
      username => 'BUser123',
      password => 'pp699',
      realname => 'Matti Meikäläinen',
      permissions => [
        'ssns-post',
        'auth-get',
      ],
    };

    $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $buser123)
      ->status_is(201, 'Then a new user is created');
    t::lib::U::debugResponse($t);
    $body = $t->tx->res->json;
    is($body->{username}, $buser123->{username}, 'And has the correct username');


    ok(1, 'When POSTing a new read-access User "RUser323"');
    my $ruser323 = {
      username => 'RUser323',
      password => 'pp699',
      realname => 'Maija Meikäläinen',
      permissions => [
        'ssns-post',
        'ssns-id-get',
        'auth-get',
      ],
    };

    $t->post_ok('/api/v1/users' => {Accept => '*/*'} => json => $ruser323)
      ->status_is(201, 'Then a new user is created');
    t::lib::U::debugResponse($t);
    $body = $t->tx->res->json;
    is($body->{username}, $ruser323->{username}, 'And has the correct username');

  };
};

done_testing();

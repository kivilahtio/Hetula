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

use Time::HiRes;
use DateTime::Format::ISO8601;
use Encode qw(encode_utf8);
use Hetula::Ssns;


subtest "Api V1 Batch import a small batch of ssns", sub {
  my ($ssnBatch, $body, $r) = @_;
  eval {

  t::lib::Auth::doPasswordLogin($t);

  $ssnBatch = randomSsnBatch(4);
  ok(1, 'Given a small batch of ssns');
  ok(Hetula::Ssns::createSsn({ssn => $ssnBatch->[1]}, 'Vaara'),
        '    Of which the 2nd one already exists');
  ok($ssnBatch->[2] = 'asdfasd',
        '    Of which the 3rd one is malformed');

  $t->post_ok('/api/v1/ssns/batch' => {Accept => '*/*'} => json => $ssnBatch)
    ->status_is(200, 'When the ssn batch is imported');
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is(ref($body), 'ARRAY', 'Then the result is an array');
  is(scalar(@$body), 4,  'And the result has 4 reports');

  $r = $body->[0];
  is(ref($r->{ssn}), 'HASH', 'And the result 1 contains the new ssn');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{createtime}),
                             '  And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{updatetime}),
                             '  And the updatetime is in ISO8601');
  is($r->{ssn}->{id}, 2,     '  And the id is ok');
  is($r->{ssn}->{ssn}, $ssnBatch->[0],  '  And the ssn is the same');
  is($r->{status}, '201',    '  And the status means, that a new ssn was added');
  is($r->{error}, undef,     '  And there is no error');

  $r = $body->[1];
  is(ref($r->{ssn}), 'HASH', 'And the result 2 contains the old ssn');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{createtime}),
                             '  And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{updatetime}),
                             '  And the updatetime is in ISO8601');
  is($r->{ssn}->{id}, 1,     '  And the id is ok');
  is($r->{ssn}->{ssn}, $ssnBatch->[1],  '  And the ssn is the same');
  is($r->{status}, '409',    '  And the status means, that this ssn already existed for this organization');
  ok($r->{error} =~ /^Hetula::Exception::Ssn::AlreadyExists/, '  And the error was about ssn already existing');

  $r = $body->[2];
  is(ref($r->{ssn}), 'HASH',            'And the result 3 contains the bad ssn');
  is($r->{ssn}->{ssn}, $ssnBatch->[2],  '  And the ssn is the same');
  is(scalar(keys(%{$r->{ssn}})), 1,     '  And no other ssn information');
  is($r->{status}, '400',               '  And the status means, that the user did something wrong');
  ok($r->{error} =~ /^Hetula::Exception::Ssn::Invalid/, '  And the ssn was invalid');

  $r = $body->[3];
  is(ref($r->{ssn}), 'HASH',            'And the result 4 contains the new ssn');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{createtime}),
                                        '  And the createtime is in ISO8601');
  ok(DateTime::Format::ISO8601->parse_datetime($r->{ssn}->{updatetime}),
                                        '  And the updatetime is in ISO8601');
  is($r->{ssn}->{id}, 3,                '  And the id is ok');
  is($r->{ssn}->{ssn}, $ssnBatch->[3],  '  And the ssn is the same');
  is($r->{status}, '201',               '  And the status means, that a new ssn was added');
  is($r->{error}, undef,                '  And there is no error');
  };
  ok(0, $@) if $@;
};


subtest "Api V1 Batch import a big batch of ssns", sub {
  my ($ssnBatch, $body, $r, @runtime) = @_;
  eval {

  $ssnBatch = randomSsnBatch(1000);
  ok($ssnBatch, 'Given a big batch of ssns');

  $runtime[0] = Time::HiRes::time();
  $t->post_ok('/api/v1/ssns/batch' => {Accept => '*/*'} => json => $ssnBatch)
    ->status_is(200, 'When the ssn batch is imported, without inactivity timeout');
  $runtime[1] = Time::HiRes::time();
  t::lib::U::debugResponse($t);
  $body = $t->tx->res->json;
  is(ref($body), 'ARRAY', 'Then the result is an array');
  is(scalar(@$body), 1000,   'And the result has 1000 reports');
  $runtime[2] = $runtime[1]-$runtime[0];
  ok($runtime[2] < 30, 'And the runtime was reasonable'); #Adjusted for clover tests

  };
  ok(0, $@) if $@;
};


done_testing();


###########################################################################################
#### UTILITY SUBROUTINES ###################################################################
###########################################################################################
sub randomSsnBatch {
  my ($count) = @_;
  my @ssns;
  foreach my $i (0..($count-1)) {
    push(@ssns, Hetula::Ssns::createRandomSsn());
  }
  return \@ssns;
}

package t::lib::U;

use Hetula::Pragmas;

use Test::More;

=head2 debugResponse

prints debug information to STDOUT of a completed Test::Mojo-response, or the given Response-object

=cut

sub debugResponse {
  return unless $ENV{MOJO_OPENAPI_DEBUG};
  my ($r) = @_;
  if (ref($r) eq 'Test::Mojo') {
    $r = $r->tx->res;
  }
  elsif (ref($r) eq 'Mojo::Transaction') {
    $r = $r->res;
  }
  else {
    die "debugResponse():> I don't know what \$r '$r' is?";
  }
  print "\n".$r->text."\n\n";
}

=head testLogs

Tests if all the logs are what is expected.
If a expected log column is undef, testing that column is skipped

@PARAM1 ARRAYRef of ARRAYRefs of expected logs
@PARAM2 ARRAYRef of HASHRefs of logs received from the REST API

=cut

sub testLogs {
  my ($expectedLogs, $realLogs) = @_;

  my %keyToIndex = (
    id             => 0,
    userid         => 1,
    organizationid => 2,
    request        => 3,
    description    => 4,
    ip             => 5,
    updatetime     => 6,
  );
  testArrayToHash($expectedLogs, $realLogs, \%keyToIndex, 'request');
}

=head testPermissions

Tests if all the permissions are what is expected.
If a expected log column is undef, testing that column is skipped

@PARAM1 ARRAYRef of ARRAYRefs of expected permissions
@PARAM2 ARRAYRef of HASHRefs of permissions received from the REST API

=cut

sub testPermissions {
  my ($expectedPermissions, $realPermissions) = @_;

  my %keyToIndex = (
    id             => 0,
    name           => 1,
    createtime     => 2,
    updatetime     => 3,
  );
  testArrayToHash($expectedPermissions, $realPermissions, \%keyToIndex, 'name');
}

sub testArrayToHash {
  $DB::single=1;
  my ($expectedArrays, $realHashes, $keyToIndex, $identifyingKey) = @_;
  my $ymd = DateTime->now()->ymd('-');

  is(scalar(@$expectedArrays), scalar(@$realHashes), 'Given expected and received objects, in equal amounts');

  my $fault;
  for (my $i=0 ; $i<scalar(@$expectedArrays) ; $i++) {
    my $expected = $expectedArrays->[$i];
    my $real = $realHashes->[$i];
    foreach my $k (keys(%$keyToIndex)) {
      my $index = $keyToIndex->{$k};
      my ($rVal, $eVal) = ($real->{$k}, $expected->[$keyToIndex->{$k}]);
      next if not(defined($eVal));

      if ($k eq 'updatetime') {
        $fault = 1 unless $rVal =~ /^$ymd/;
      }
      else {
        if (ref($eVal) eq 'Regexp') {
          $fault = 1 unless ($rVal =~ $eVal);
        } else {
          unless (($rVal // '') eq ($eVal // '')) {
            $fault = 1;
          }
        }
      }

      if ($fault) {
        $fault = "Object in index '$i' id '".$real->{id}."' for '".$real->{$identifyingKey}."', key '$k'. Expected '$eVal', got '$rVal'";
        last;
      }
    }
    last if $fault;
  }
  is($fault || 'No problems', 'No problems', 'Then all objects are what is expected');
}

1;

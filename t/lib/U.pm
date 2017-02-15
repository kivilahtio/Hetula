use 5.22.0;

package t::lib::U;

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
  print $r->text."\n";
}

=head testLogs

Tests if all the logs are what is expected.
If a expected log column is undef, testing that column is skipped

@PARAM1 ARRAYRef of ARRAYRefs of expected logs
@PARAM2 ARRAYRef of HASHRefs of logs received from the REST API

=cut

sub testLogs {
  my ($expectedLogs, $realLogs) = @_;
  my $ymd = DateTime->now()->ymd('-');

  my %keyToIndex = (
    id             => 0,
    userid         => 1,
    organizationid => 2,
    request        => 3,
    description    => 4,
    ip             => 5,
    updatetime     => 6,
  );

  is(scalar(@$expectedLogs), scalar(@$realLogs), 'Given expected and received logs, in equal amounts');

  my $fault;
  for (my $i=0 ; $i<scalar(@$expectedLogs) ; $i++) {
    my $expected = $expectedLogs->[$i];
    my $real = $realLogs->[$i];
    foreach my $k (keys(%keyToIndex)) {
      my $index = $keyToIndex{$k};
      my ($rVal, $eVal) = ($real->{$k}, $expected->[$keyToIndex{$k}]);
      next if not(defined($eVal));

      if ($k eq 'updatetime') {
        $fault = 1 unless $rVal =~ /^$ymd/;
      }
      else {
        $fault = 1 unless ("$rVal" eq "$eVal");
      }

      if ($fault) {
        $fault = "Log id '".$real->{id}."' for url '".$real->{request}."', key '$k'. Expected '$eVal', got '$rVal'";
        last;
      }
    }
    last if $fault;
  }
  is($fault || 'No problems', 'No problems', 'Then all logs are what is expected');
}

1;

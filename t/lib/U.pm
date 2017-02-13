use 5.22.0;

package t::lib::U;

=head2 debugResponse

prints debug information to STDOUT of a completed Test::Mojo-response, or the given Response-object

=cut

sub debugResponse {
  return unless $ENV{MOJO_OPENAPI_DEBUG};
  my ($r) = @_;
  if (ref($r) eq 'Test::Mojo') {
    $r = $r->tx->res;
  }
  print $r->text."\n";
}

1;

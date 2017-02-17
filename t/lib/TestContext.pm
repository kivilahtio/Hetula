use 5.22.0;

package t::lib::TestContext;

use PatronStore::Users;

=head2 set

Instantiates a test context.

@RETURNS Test::Mojo with PatronStore loaded

=cut

sub set {
  $ENV{MOJO_MODE} = "testing";
  my $t = Test::Mojo->new('PatronStore');
  return $t;
}

1;

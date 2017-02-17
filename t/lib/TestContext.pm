use 5.22.0;

package t::lib::TestContext;

use Hetula::Users;

=head2 set

Instantiates a test context.

@RETURNS Test::Mojo with Hetula loaded

=cut

sub set {
  $ENV{MOJO_MODE} = "testing";
  my $t = Test::Mojo->new('Hetula');
  return $t;
}

1;

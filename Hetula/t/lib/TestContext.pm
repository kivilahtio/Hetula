package t::lib::TestContext;

use Hetula::Pragmas;

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

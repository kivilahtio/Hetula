use 5.22.0;

package t::lib::TestContext;

use t::lib::TestDB;

=head2 set

Instantiates a test context.
Call this before any Mojo-stuff

=cut

sub set {
    $ENV{MOJO_MODE} = "testing";
    die "Something wrong creating the test database" unless t::lib::TestDB::prepareTestDB();
}

1;

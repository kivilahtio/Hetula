use 5.22.0;

package t::lib::TestContext;

use t::lib::TestDB;

=head2 set

Instantiates a test context.

@RETURNS Test::Mojo with PatronStore loaded

=cut

sub set {
    $ENV{MOJO_MODE} = "testing";
    my $t = Test::Mojo->new('PatronStore');
    die "Something wrong creating the test database" unless t::lib::TestDB::prepareTestDB();
    return $t;
}

1;

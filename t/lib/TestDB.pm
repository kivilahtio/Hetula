use 5.22.0;

package t::lib::TestDB;

use PatronStore::Schema;

=head2 prepareTestDB

Instantiates a sqlite3 db to run tests on

=cut

sub prepareTestDB {
  my $schema = PatronStore::Schema->new_schema(0,0); #Hide errors
  my $user;
  eval {
    $user = $schema->resultset('User')->search({}, {limit => 1})->single;
  };
  return 1 if $user; #The DB exists
  $schema = PatronStore::Schema->new_schema(1,1); #Show errors!
  $schema->deploy();
  return 1;
}

1;

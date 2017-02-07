use 5.22.0;

package t::lib::TestDB;

use PatronStore::Schema;

=head2 prepareTestDB

Instantiates a sqlite3 db to run tests on

=cut

sub prepareTestDB {
  #Remove the previous sqlite database if it exists
#  my $rv = `rm t/var/test.db 2>&1`;
#  die $rv if $rv && not($rv =~ /No such file or directory/);
#  $rv = `sqlite3 t/var/test.db 2>&1`;
#  die $rv if $rv;

  my $schema = PatronStore::Schema->schema();
  $schema->deploy();

  return 1;
}

1;

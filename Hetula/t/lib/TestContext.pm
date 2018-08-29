package t::lib::TestContext;

use Hetula::Pragmas;

use DBIx::Class::Migration;

use Hetula::Organizations;

=head1 END

Forcibly flushes the database on test exit.

=cut

END {
  
}

=head2 set

Instantiates a test context.

@RETURNS Test::Mojo with Hetula loaded

=cut

sub set {
  $ENV{MOJO_MODE} = 'testing';
  Hetula::Config::loadConfigs();
  my $migration = DBIx::Class::Migration->new(schema => Hetula::Schema::schema());
  $migration->delete_table_rows(); #Flush the database so we can start testing cleanly
  populateTestDB();

  my $t = Test::Mojo->new('Hetula');
  return $t;
}

sub populateTestDB() {
  #reverse alphabetical order is important to test sorting of results
  Hetula::Organizations::createOrganization({name => 'Vaara'});
  Hetula::Organizations::createOrganization({name => 'Outi'});
  Hetula::Organizations::createOrganization({name => 'Lumme'});
  Hetula::Organizations::createOrganization({name => 'Lappi'});
}

1;

use 5.22.0;

package Hetula::Schema::DefaultDB;

=head1 NAME

Hetula::Schema::DefaultDB

=head2 SYNOPSIS

Create the default db contents

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;

use Hetula::Schema;
use Hetula::Users;
use Hetula::Organizations;


=head2 createDB

Creates the DB structure if it is not present

=cut

sub createDB {
  my () = @_;
  my $schema = Hetula::Schema->schema();

  #$schema->storage->debug(1);
  unless (_checkIfDBExists($schema)) {
    $schema->deploy();
    _populateCoreData($schema);
  }
  #$schema->storage->debug(0);
}

sub _checkIfDBExists {
  my ($schema) = @_;
  my $user;
  eval {
    $user = $schema->resultset('User')->search({}, {limit => 1})->single;
  };
  return 1 if $user; #The DB exists
  return undef;
}

sub _populateCoreData {
  my ($schema) = @_;

  Hetula::Users::createUser({id => 1, username => 'admin', realname => 'Super administrator account', password => '1234'});
  #reverse alphabetical order is important to test sorting of results
  Hetula::Organizations::createOrganization({name => 'Vaara'});
  Hetula::Organizations::createOrganization({name => 'Outi'});
  Hetula::Organizations::createOrganization({name => 'Lumme'});
  Hetula::Organizations::createOrganization({name => 'Lappi'});
}

1;

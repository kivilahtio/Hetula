use 5.22.0;

package PatronStore::Schema::DefaultDB;

=head1 NAME

PatronStore::Schema::DefaultDB

=head2 SYNOPSIS

Create the default db contents

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;

use PatronStore::Schema;
use PatronStore::Users;


=head2 createDB

Creates the DB structure if it is not present

=cut

sub createDB {
  my () = @_;
  my $schema = PatronStore::Schema->schema();

  unless (_checkIfDBExists($schema)) {
    $schema->deploy();
    _populateCoreData($schema);
  }
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

  PatronStore::Users::createUser({id => 1, username => 'admin', realname => 'Super administrator account', password => '1234'});
}

1;

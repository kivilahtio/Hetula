use 5.22.0;

package PatronStore::Users;

=head1 NAME

PatronStore::Users

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;
use Digest::SHA;

use PatronStore::Schema;

use PS::Exception::User::NotFound;

=head2 getUser

@RETURNS PatronStore::Schema::Result::User
@THROWS PS::Exception::User::NotFound

=cut

sub getUser {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('User');
  my $user = $rs->find($args);
  PS::Exception::User::NotFound->throw(error => 'No user found with params "'.Data::Dumper::Dumper($args).'"') unless $user;
  return $user;
}


=head2 createUser

Creates and returns a User

=cut

sub createUser {
  my ($user, $permissions, $organizations) = @_;

  $user->{password} = Digest::SHA::sha256($user->{password});
  my $new_user = _createUser($user);

  return $new_user;
}

=head2 _createUser

Creates a User-entry to the DB

=cut

sub _createUser {
  my ($user) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('User');
  return $rs->create($user);
}

1;

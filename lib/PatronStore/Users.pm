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

=head2 listUsers

@RETURNS ARRAYRef of PatronStore::Schema::Result::User-objects
@THROWS PS::Exception::User::NotFound

=cut

sub listUsers {
  my $rs = PatronStore::Schema::schema()->resultset('User');
  my @users = $rs->search()->all();
  PS::Exception::User::NotFound->throw(error => 'No users found') unless @users;
  return \@users;
}

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

=head2 getFullUser

@RETURNS PatronStore::Schema::Result::User, with Organizations and Permissions prefetched
@THROWS PS::Exception::User::NotFound

=cut

sub getFullUser {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('User');
  my $user = $rs->find({id => $args->{id}}, {prefetch => {user_permission => 'permission',
                                                          user_organization => 'organization'}});
  return $user;
}

=head2 createUser

Creates and returns a User

=cut

sub createUser {
  my ($user) = @_;
  my ($permissions, $organizations) = ($user->{permissions}, $user->{organizations});
  delete $user->{permissions};
  delete $user->{organizations};

  _hashPassword($user);
  my $newUser = _createUser($user);

  if ($permissions) {
    $newUser->setPermissions($permissions);
  }
  if ($organizations) {
    $newUser->setOrganizations($organizations);
  }

  return $newUser;
}

=head2 _createUser

Creates a User-entry to the DB

=cut

sub _createUser {
  my ($user) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('User');
  return $rs->create($user);
}

=head2 modUser

Updates and returns a User

=cut

sub modUser {
  my ($user) = @_;
  my ($permissions, $organizations) = ($user->{permissions}, $user->{organizations});
  delete $user->{permissions};
  delete $user->{organizations};

  _hashPassword($user);
  my $oldUser = _modUser($user);

  if ($permissions) {
    $oldUser->setPermissions($permissions);
  }
  if ($organizations) {
    $oldUser->setOrganizations($organizations);
  }

  return $oldUser;
}

=head2 _modUser

Updates a User-entry to the DB

=cut

sub _modUser {
  my ($user) = @_;
  my $oldUser = getUser({id => $user->{id}});
  return $oldUser->update($user);
}

=head2 deleteUser

Deletes an user

=cut

sub deleteUser {
  my ($args) = @_;
  getUser({id => $args->{id}})->delete();
}

=head2 _hashPassword

@PARAM1 HASHRef of user attributes.

=cut

sub _hashPassword {
  my ($user) = @_;
  $user->{password} = Digest::SHA::sha256($user->{password});
}

1;

package Hetula::Users;

=head1 NAME

Hetula::Users

=head2 SYNOPSIS

Manage this class of objects

=cut

use Hetula::Pragmas;

use Digest::SHA;

use Hetula::Exception::User::NotFound;
use Hetula::Exception::User::Duplicate;
use Hetula::Exception::BadParameter;
use Hetula::Exception::Auth::Password;

=head2 listUsers

@RETURNS ARRAYRef of Hetula::Schema::Result::User-objects
@THROWS Hetula::Exception::User::NotFound

=cut

sub listUsers {
  my $rs = Hetula::Schema::schema()->resultset('User');
  my @users = $rs->search()->all();
  Hetula::Exception::User::NotFound->throw(error => 'No users found') unless @users;
  return \@users;
}

=head2 getUser

@RETURNS Hetula::Schema::Result::User
@THROWS Hetula::Exception::User::NotFound

=cut

sub getUser {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('User');
  my $user = $rs->find($args);
  Hetula::Exception::User::NotFound->throw(error => 'No user found with params "'.Data::Dumper::Dumper($args).'"') unless $user;
  return $user;
}

=head2 getAdmin

@RETURNS Hetula::Schema::Result::User
@THROWS Hetula::Exception::User::NotFound

=cut

sub getAdmin() {
  my $rs = Hetula::Schema::schema()->resultset('User');
  my $user = $rs->find({id => 1});
  Hetula::Exception::User::NotFound->throw(error => 'No admin found!?') unless $user;
  return $user;
}

=head2 getFullUser

@RETURNS Hetula::Schema::Result::User, with Organizations and Permissions prefetched
@THROWS Hetula::Exception::User::NotFound

=cut

sub getFullUser {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('User');
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

  Hetula::Exception::BadParameter->throw(error => "Username is only digits. It must contain atleast one non-digit character.") if ($user->{username} =~ /^\d+$/); #Username cannot be only digits so it doesn't get mixed up with the id.

  $user->{password} = _createPassword($user->{password});
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
  my $rs = Hetula::Schema::schema()->resultset('User');

  try {
    return $rs->create($user);
  } catch {
    Hetula::Exception::User::Duplicate->throw(
      error => "User '".($user->{realname} || $user->{username})."' already exists.",
      user => getUser({username => $user->{username}})->swaggerize()
    ) if (blessed($_) && $_->isa('DBIx::Class::Exception') && $_->{msg} =~ /Duplicate entry '.+?' for key 'user_username'/);

    Hetula::Exception::rethrowDefaults($_);
  };
}

=head2 modUser

Updates and returns a User

=cut

sub modUser {
  my ($user) = @_;
  my ($permissions, $organizations) = ($user->{permissions}, $user->{organizations});
  delete $user->{permissions};
  delete $user->{organizations};

  my $guard = Hetula::Schema::schema()->txn_scope_guard; #Be ready to rollback if errors arise

  $user->{password} = _createPassword($user->{password}) if $user->{password};
  my $oldUser = _modUser($user);

  if ($permissions) {
    $oldUser->setPermissions($permissions);
  }
  if ($organizations) {
    $oldUser->setOrganizations($organizations);
  }

  $guard->commit();
  return $oldUser;
}

=head2 _modUser

Updates a User-entry to the DB

=cut

sub _modUser {
  my ($user) = @_;
  my $oldUser = getUser($user);
  return $oldUser->update($user);
}

=head2 deleteUser

Deletes an user

=cut

sub deleteUser {
  my ($args) = @_;
  getUser($args)->delete();
}

=head2 _createPassword

 @param1 {String} password

=cut

sub _createPassword {
  my ($password) = @_;
  Hetula::Exception::Auth::Password->throw(error => "No password given!") unless ($password);
  return $password if $password eq '!';
  Hetula::Exception::Auth::Password->throw(error => "Given password is shorter than the configured minimum password length '".Hetula::Config::minimum_password_length()."'")
    unless length($password) >= Hetula::Config::minimum_password_length();
  return _hashPassword($password);
}

=head2 _hashPassword

@PARAM1 String, password

=cut

sub _hashPassword {
  my ($password) = @_;
  Hetula::Exception::Auth::Password->throw(error => "Trying to hash a disabled password!") if ($password eq '!');
  return Digest::SHA::sha256_base64($password);
}

1;

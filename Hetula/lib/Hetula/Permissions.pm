package Hetula::Permissions;

=head1 NAME

Hetula::Permissions

=head2 SYNOPSIS

Manage this class of objects

=cut

use Hetula::Pragmas;

use Hetula::Exception::Permission::NotFound;
use Hetula::Exception::Permission::Duplicate;
use Hetula::Exception::Auth::Authorization;

=head2 getPermission

@RETURNS Hetula::Schema::Result::Permission
@THROWS Hetula::Exception::Permission::NotFound

=cut

sub getPermission {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Permission');
  my $o = $rs->find($args);
  Hetula::Exception::Permission::NotFound->throw(error => 'No permission found with params "'.Data::Dumper::Dumper($args).'"') unless $o;
  return $o;
}

=head2 listPermissions

@RETURNS ARRAYRef of Hetula::Schema::Result::Permission-objects
@THROWS Hetula::Exception::Permission::NotFound

=cut

sub listPermissions {
  my $rs = Hetula::Schema::schema()->resultset('Permission');
  my @perms = $rs->search()->all();
  Hetula::Exception::Permission::NotFound->throw(error => 'No permissions found') unless @perms;
  return \@perms;
}

=head2 createPermission

Creates and returns a Permission

=cut

sub createPermission {
  my ($p) = @_;

  my $rs = Hetula::Schema::schema()->resultset('Permission');
  try {
    return $rs->create($p);
  } catch {
    Hetula::Exception::Permission::Duplicate->throw(
      error => "Permission '".$p->{name}."' already exists.",
      permission => getPermission({name => $p->{name}})->swaggerize()
    ) if (blessed($_) && $_->isa('DBIx::Class::Exception') && $_->{msg} =~ /Duplicate entry '.+?' for key 'permission_name'/);

    Hetula::Exception::rethrowDefaults($_);
  };
}

=head2 deletePermission

Deletes a perm
@THROWS Hetula::Exception::Permission::NotFound

=cut

sub deletePermission {
  my ($args) = @_;
  my $p = getPermission($args);
  $p->delete;
}

=head2 hasPermissions

Check if the given User has all of the given permissions

@PARAM1 Hetula::Schema::Result::User or the user.id
@PARAM2 ARRAYRef of Hetula::Schema::Result::Permission or permission names
@RETURNS 1 if has all permissions
@THROWS Hetula::Exception::Auth::Authorization with permission names that the given user doesn't have a permission for

=cut

sub hasPermissions {
  my ($user, $permissions) = @_;
  return undef unless (@$permissions);

  $user = Hetula::Users::getUser({id => $user}) unless (blessed($user));

  my @userPermissions = $user->permissions();

  my @noPermissions;
  for my $p (@$permissions) {
    $p = Hetula::Permissions::getPermission({name => $p}) unless (blessed($p));
    push(@noPermissions, $p) unless (List::Util::any {defined($_) && $p->name eq $_->name} @userPermissions);
  }
  Hetula::Exception::Auth::Authorization->throw(error => "User '".$user->username."' is missing permissions '".join(" ", sort map {$_->name} @noPermissions)."'") if (@noPermissions);
  return 1;
}

1;

package Hetula::Permissions;

=head1 NAME

Hetula::Permissions

=head2 SYNOPSIS

Manage this class of objects

=cut

use Hetula::Pragmas;

use Hetula::Exception::Permission::NotFound;
use Hetula::Exception::Permission::Duplicate;

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

1;

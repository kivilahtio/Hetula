use 5.22.0;

package PatronStore::Permissions;

=head1 NAME

PatronStore::Permissions

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;

use PatronStore::Schema;

use PS::Exception::Permission::NotFound;

=head2 getPermission

@RETURNS PatronStore::Schema::Result::Permission
@THROWS PS::Exception::Permission::NotFound

=cut

sub getPermission {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('Permission');
  my $o = $rs->find($args);
  PS::Exception::Permission::NotFound->throw(error => 'No permission found with params "'.Data::Dumper::Dumper($args).'"') unless $o;
  return $o;
}

=head2 listPermissions

Returns all Permissions

=cut

sub listPermissions {
    return PatronStore::Schema::schema()->resultset('Permission')->search();
}

=head2 createPermission

Creates and returns a Permission

=cut

sub createPermission {
  my ($p) = @_;

  my $rs = PatronStore::Schema::schema()->resultset('Permission');
  return $rs->create($p);
}

=head2 deletePermission

Deletes a perm
@THROWS PS::Exception::Permission::NotFound

=cut

sub deletePermission {
  my ($args) = @_;
  my $p = getPermission($args);
  $p->delete;
}

1;

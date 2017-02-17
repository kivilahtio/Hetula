use 5.22.0;

package Hetula::Permissions;

=head1 NAME

Hetula::Permissions

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;

use Hetula::Schema;

use Hetula::Exception::Permission::NotFound;

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
  return $rs->create($p);
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

use 5.22.0;

package Hetula::Schema::Result::User;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  username => { data_type => 'varchar', size => 30},
  password => { data_type => 'varchar', size => 64},
  realname => { data_type => 'varchar', size => 50},
  failed_login_count => { data_type => 'integer', default_value => 0 },
  createtime => { data_type => 'datetime', set_on_create => 1 },
  updatetime => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['username']);
__PACKAGE__->has_many(user_permissions => 'Hetula::Schema::Result::UserPermission', 'userid');
__PACKAGE__->many_to_many(permissions => 'user_permissions', 'permission');
__PACKAGE__->has_many(user_organizations => 'Hetula::Schema::Result::UserOrganization', 'userid');
__PACKAGE__->many_to_many(organizations => 'user_organizations', 'organization');
__PACKAGE__->might_have(apiclient => 'Hetula::Schema::Result::ApiCredential', 'userid');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

#####################################
## ## ##   OBJECT METHODS    ## ## ##

=head2 swaggerize

Cast this into something the OpenAPI-plugin can validate as a proper Swagger2-response object

=cut

sub swaggerize {
  my ($self, $op_spec) = @_;

  my $swag = $self->{_column_data};
  $swag->{id} += 0;
  $swag->{createtime} =~ s/ /T/;
  $swag->{updatetime} =~ s/ /T/;

  my @organizations = map {$_->toString} sort {$a->name cmp $b->name} $self->organizations;
  $swag->{organizations} = \@organizations;
  my @permissions = map {$_->toString} sort {$a->name cmp $b->name} $self->permissions;
  $swag->{permissions} = \@permissions;

  return $swag;
}

=head2 unblockLogin

Resets the failed_login_count, thus allowing logins for this user again.

@RETURNS $self

=cut

sub unblockLogin {
  my ($self) = @_;

  $self->failed_login_count(0);
  $self->update();
  return $self;
}

=head2 incrementFailedLoginCount

Adds one unsuccessful login attempt on the user's shoulders

@RETURNS $self

=cut

sub incrementFailedLoginCount {
  my ($self) = @_;

  $self->failed_login_count( $self->failed_login_count+1 );
  $self->update();
  return $self;
}

=head2 listPermissions

=cut

sub listPermissions {
  my ($self) = @_;

  my $rs = Hetula::Schema->schema->resultset('Permission');
  return $rs->search({'user_permissions.userid' => $self->id},
                     {join => 'user_permissions'})->all;
}

=head2 hasPermission

@PARAM1 String, the permission name, preferably generated using Hetula::getPermissionFromRoute()
@RETURNS Permission if allowed

=cut

sub hasPermission {
  my ($self, $permissionName) = @_;

  my $rs = Hetula::Schema->schema->resultset('Permission');
  return $rs->search({
      'user_permissions.userid' => $self->id,
      'name' => $permissionName
    },
    {
      join => 'user_permissions'
    })->single;
}

=head2 grantPermission

@PARAM1 $self
@PARAM2 permission.name or Hetula::Schema::Result::Permission

=cut

sub grantPermission {
  my ($self, $permission) = @_;
  unless (blessed($permission) && $permission->isa('Hetula::Schema::Result::Permission')) {
    $permission = Hetula::Permissions::getPermission({name => $permission});
  }

  my $rs = Hetula::Schema->schema->resultset('UserPermission');
  $rs->update_or_create({userid => $self->id, permissionid => $permission->id});
  return $self;
}

=head2 revokePermission

=cut

sub revokePermission {
  my ($self, $permission) = @_;

  my $rs = Hetula::Schema->schema->resultset('UserPermission');
  my $up = $rs->find({userid => $self->id, permissionid => $permission->id});
  $up->delete;
  return $self;
}

=head2 revokeAllPermissions

=cut

sub revokeAllPermissions {
  my ($self) = @_;

  my $rs = Hetula::Schema->schema->resultset('UserPermission');
  $rs->search({userid => $self->id})->delete;
  return $self;
}

=head2 setPermissions

@PARAM1 ARRAYRef of permission.name

=cut

sub setPermissions {
  my ($self, $permissions) = @_;

  my @new = Hetula::Schema->schema->resultset('Permission')->search({name => {'-in' => $permissions}});
  $self->set_permissions(\@new);
  return $self;
}

=head2 setOrganizations

@PARAM1 $self
@PARAM2 ARRAYRef of organization.name

=cut

sub setOrganizations {
  my ($self, $organizations) = @_;

  my @new = Hetula::Schema->schema->resultset('Organization')->search({name => {'-in' => $organizations}});
  $self->set_organizations(\@new);
  return $self;
}

=head2 setApiCredential

@PARAM1 $self
@PARAM2 HASHRef of ApiCredential-attributes
@RETURNS $self

=cut

sub setApiCredential {
  my ($self, $apiCredential) = @_;

  $self->set_apicredential($apiCredential);
  return $self;
}

## ## ##   DONE WITH OBJECT METHODS    ## ## ##
###############################################

1;

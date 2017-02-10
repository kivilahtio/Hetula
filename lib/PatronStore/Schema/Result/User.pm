use 5.22.0;

package PatronStore::Schema::Result::User;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  username => { data_type => 'varchar', size => 30},
  password => { data_type => 'varchar', size => 30},
  realname => { data_type => 'varchar', size => 50},
  failed_login_count => { data_type => 'integer', default_value => 0 },
  createtime => { data_type => 'datetime', set_on_create => 1 },
  updatetime => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(user_permissions => 'PatronStore::Schema::Result::UserPermission', 'userid');
#__PACKAGE__->has_many(organizations => 'PatronStore::Schema::Result::UserOrganization', 'id');
## ## ##   DONE WITH DBIx::Schema   ## ## ##
############################################

#####################################
## ## ##   OBJECT METHODS    ## ## ##

=head2 swaggerize

Cast this into something the OpenAPI-plugin can validate as a proper Swagger2-response object

=cut

sub swaggerize {
  my ($self, $op_spec) = @_;

  $self->{_column_data}->{createtime} =~ s/ /T/;
  $self->{_column_data}->{updatetime} =~ s/ /T/;
#  require Encode;
#  while(my ($k, $v) = each(%{$self->{_column_data}})) {
#    $v = Encode::encode_utf8($v);
#    $self->{_column_data}->{$k} = $v;
#  }

  return $self->{_column_data};
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

  my $rs = PatronStore::Schema->schema->resultset('Permission');
  return $rs->search({'user_permissions.userid' => $self->id},
                     {join => 'user_permissions'})->all;
}

=head2 hasPermission

@PARAM1 String, the permission name, preferably generated using PatronStore::getPermissionFromRoute()
@RETURNS Permission if allowed

=cut

sub hasPermission {
  my ($self, $permissionName) = @_;

  my $rs = PatronStore::Schema->schema->resultset('Permission');
  return $rs->find({'user_permissions.userid' => $self->id,
                    'name' => $permissionName},
                     {join => 'user_permissions'});
}

=head2 grantPermission

=cut

sub grantPermission {
  my ($self, $permission) = @_;

  my $rs = PatronStore::Schema->schema->resultset('UserPermission');
  $rs->update_or_create({userid => $self->id, permissionid => $permission->id});
  return $self;
}

=head2 revokePermission

=cut

sub revokePermission {
  my ($self, $permission) = @_;

  my $rs = PatronStore::Schema->schema->resultset('UserPermission');
  my $up = $rs->find({userid => $self->id, permissionid => $permission->id});
  $up->delete;
  return $self;
}

## ## ##   DONE WITH OBJECT METHODS    ## ## ##
###############################################

1;

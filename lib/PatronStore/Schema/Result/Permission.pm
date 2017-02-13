use 5.22.0;

package PatronStore::Schema::Result::Permission;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('permission');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 40},
  createtime => { data_type => 'datetime', set_on_create => 1 },
  updatetime => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(user_permissions => 'PatronStore::Schema::Result::UserPermission', 'permissionid');
__PACKAGE__->many_to_many(users => 'user_permissions', 'user');
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
  return $self->{_column_data};
}

=head2 toString

=cut

sub toString {
  return shift->name;
}

1;
use 5.22.0;

package Hetula::Schema::Result::Ssn;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('ssn');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  ssn => { data_type => 'varchar', size => 30},
  createtime => { data_type => 'datetime', set_on_create => 1 },
  updatetime => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['ssn']);
__PACKAGE__->has_many(ssn_organizations => 'Hetula::Schema::Result::SsnOrganization', 'ssnid');
__PACKAGE__->many_to_many(organizations => 'ssn_organizations', 'organization');
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
  $swag->{createtime} =~ s/ /T/;
  $swag->{updatetime} =~ s/ /T/;

  my @organizations = map {$_->toString} sort {$a->name cmp $b->name} $self->organizations;
  $swag->{organizations} = \@organizations;

  return $swag;
}

=head2 removeOrganization

=cut

sub removeOrganization {
  my ($self, $organization) = @_;

  my $rs = Hetula::Schema->schema->resultset('SsnOrganization');
  $rs->search({ssnid => $self->id, organizationid => $organization->id})->delete;
}

=head2 countOrganizations

=cut

sub countOrganizations {
  my ($self) = @_;

  my $rs = Hetula::Schema->schema->resultset('SsnOrganization');
  return $rs->count({ssnid => $self->id});
}

## ## ##   DONE WITH OBJECT METHODS    ## ## ##
###############################################

1;

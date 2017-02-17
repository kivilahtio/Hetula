use 5.22.0;

package Hetula::Schema::Result::Log;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp Core ));
__PACKAGE__->table('log');
__PACKAGE__->add_columns(
  id             => { data_type => 'integer',  is_auto_increment => 1 },
  userid         => { data_type => 'integer',  is_foreign_key => 1,   is_nullable => 1 },
  organizationid => { data_type => 'integer',  is_foreign_key => 1,   is_nullable => 1 },
  request        => { data_type => 'varchar',  size => 50},
  description    => { data_type => 'varchar',  size => 50},
  ip             => { data_type => 'varchar',  size => 50}, #can be ipv6?
  updatetime     => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(user => 'Hetula::Schema::Result::User', 'userid');
__PACKAGE__->belongs_to(organization => 'Hetula::Schema::Result::Organization', 'organizationid');

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
  $swag->{updatetime} =~ s/ /T/;
  delete $swag->{userid} unless $swag->{userid};
  delete $swag->{organizationid} unless $swag->{organizationid};

  return $swag;
}

## ## ##   DONE WITH OBJECT METHODS    ## ## ##
###############################################

1;

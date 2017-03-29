use 5.22.0;

package Hetula::Schema::Result::ApiCredential;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

##################################
## ## ##   DBIx::Schema   ## ## ##
__PACKAGE__->load_components(qw( TimeStamp InflateColumn::Object::Enum Core ));
__PACKAGE__->table('apicredential');
__PACKAGE__->add_columns(
  id =>            { data_type => 'integer',  is_auto_increment => 1 },
  userid =>        { data_type => 'integer',  is_foreign_key => 1 },
  client_id =>     { data_type => 'varchar',  size => 32},
  client_secret => { data_type => 'varchar',  size => 32}, #SHA-256
  client_type =>   { data_type => 'enum',     is_enum => 1, extra => { list => [qw/public confidential/] }},
  client_redirection_url =>
                   { data_type => 'varchar',  size => 50},
  client_website =>
                   { data_type => 'varchar',  size => 50},
  createtime =>    { data_type => 'datetime', set_on_create => 1 },
  updatetime =>    { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['userid']);
__PACKAGE__->belongs_to(user => 'Hetula::Schema::Result::User', 'userid');
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

  return $swag;
}

## ## ##   DONE WITH OBJECT METHODS    ## ## ##
###############################################

1;

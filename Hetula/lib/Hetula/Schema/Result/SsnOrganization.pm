package Hetula::Schema::Result::SsnOrganization;
use base qw/DBIx::Class::Core/;

use Hetula::Pragmas 'no-schema';

__PACKAGE__->table('ssn_organization');
__PACKAGE__->add_columns(
  id =>             { data_type => 'integer', is_auto_increment => 1 },
  ssnid =>          { data_type => 'integer', is_foreign_key => 1 },
  organizationid => { data_type => 'integer', is_foreign_key => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['ssnid', 'organizationid']);
__PACKAGE__->belongs_to(ssn => 'Hetula::Schema::Result::Ssn', 'ssnid');
__PACKAGE__->belongs_to(organization => 'Hetula::Schema::Result::Organization', 'organizationid');

1;
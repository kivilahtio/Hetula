use 5.22.0;

package PatronStore::Schema::Result::SsnOrganization;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('ssn_organization');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  ssnid => { data_type => 'integer' },
  organizationid => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to(ssn => 'PatronStore::Schema::Result::Ssn', 'ssnid');
__PACKAGE__->belongs_to(organization => 'PatronStore::Schema::Result::Organization', 'organizationid');

1;
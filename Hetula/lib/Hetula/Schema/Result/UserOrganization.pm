package Hetula::Schema::Result::UserOrganization;
use base qw/DBIx::Class::Core/;

use Hetula::Pragmas 'no-schema';

__PACKAGE__->table('user_organization');
__PACKAGE__->add_columns(
  id =>             { data_type => 'integer', is_auto_increment => 1 },
  userid =>         { data_type => 'integer', is_foreign_key => 1 },
  organizationid => { data_type => 'integer', is_foreign_key => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['userid', 'organizationid']);
__PACKAGE__->belongs_to(user => 'Hetula::Schema::Result::User', 'userid');
__PACKAGE__->belongs_to(organization => 'Hetula::Schema::Result::Organization', 'organizationid');

1;
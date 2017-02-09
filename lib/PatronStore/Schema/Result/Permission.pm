use 5.22.0;

package PatronStore::Schema::Result::Permission;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('permission');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 40},
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(user_permissions => 'PatronStore::Schema::Result::UserPermission', 'permissionid');

1;
use 5.22.0;

package PatronStore::Schema::Result::UserPermission;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('user_permission');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  userid => { data_type => 'integer' },
  permissionid => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['userid', 'permissionid']);
__PACKAGE__->belongs_to('user' => 'PatronStore::Schema::Result::User', 'userid');
__PACKAGE__->belongs_to('permission' => 'PatronStore::Schema::Result::Permission', 'permissionid');


1;
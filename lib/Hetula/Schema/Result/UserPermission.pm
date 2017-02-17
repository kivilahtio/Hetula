use 5.22.0;

package Hetula::Schema::Result::UserPermission;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('user_permission');
__PACKAGE__->add_columns(
  id =>           { data_type => 'integer', is_auto_increment => 1 },
  userid =>       { data_type => 'integer', is_foreign_key => 1 },
  permissionid => { data_type => 'integer', is_foreign_key => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['userid', 'permissionid']);
__PACKAGE__->belongs_to('user' => 'Hetula::Schema::Result::User', 'userid');
__PACKAGE__->belongs_to('permission' => 'Hetula::Schema::Result::Permission', 'permissionid');


1;
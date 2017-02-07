use 5.22.0;

package PatronStore::Schema::Result::User;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('user');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  username => { data_type => 'varchar', size => 30},
  password => { data_type => 'varchar', size => 30},
  realname => { data_type => 'varchar', size => 50},
  failed_login_count => { data_type => 'integer' },
  last_client_ip => { data_type => 'varchar', size => 25},
);
__PACKAGE__->set_primary_key('id');
#__PACKAGE__->has_many(permissions => 'PatronStore::Schema::Result::UserPermission', 'id');
#__PACKAGE__->has_many(organizations => 'PatronStore::Schema::Result::UserOrganization', 'id');

1;
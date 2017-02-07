use 5.22.0;

package PatronStore::Schema::Result::Organization;
use base qw/DBIx::Class::Core/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->table('organization');
__PACKAGE__->add_columns(
  id => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 30},
);
__PACKAGE__->set_primary_key('id');

1;
use 5.22.0;

package PS::Exception::Organization::NotFound;

use Exception::Class (
    'PS::Exception::Organization::NotFound' => {
        isa => 'PS::Exception::Organization',
        description => "No such organization in db",
    },
);

1;
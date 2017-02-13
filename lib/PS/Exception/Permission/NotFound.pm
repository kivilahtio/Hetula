use 5.22.0;

package PS::Exception::Permission::NotFound;

use Exception::Class (
    'PS::Exception::Permission::NotFound' => {
        isa => 'PS::Exception::Permission',
        description => "No such permission in db",
    },
);

1;
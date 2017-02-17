use 5.22.0;

package Hetula::Exception::Permission::NotFound;

use Exception::Class (
    'Hetula::Exception::Permission::NotFound' => {
        isa => 'Hetula::Exception::Permission',
        description => "No such permission in db",
    },
);

1;
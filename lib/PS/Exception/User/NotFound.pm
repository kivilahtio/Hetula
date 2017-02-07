use 5.22.0;

package PS::Exception::User::NotFound;

use Exception::Class (
    'PS::Exception::User::NotFound' => {
        isa => 'PS::Exception::User',
        description => "No such user in db",
    },
);

1;
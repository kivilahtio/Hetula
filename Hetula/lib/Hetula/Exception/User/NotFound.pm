use 5.22.0;

package Hetula::Exception::User::NotFound;

use Exception::Class (
    'Hetula::Exception::User::NotFound' => {
        isa => 'Hetula::Exception::User',
        description => "No such user in db",
    },
);

1;
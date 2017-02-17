use 5.22.0;

package Hetula::Exception::User;

use Exception::Class (
    'Hetula::Exception::User' => {
        isa => 'Hetula::Exception',
        description => "User base exception class",
    },
);

1;
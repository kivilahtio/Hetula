use 5.22.0;

package Hetula::Exception::Auth;

use Exception::Class (
    'Hetula::Exception::Auth' => {
        isa => 'Hetula::Exception',
        description => "Auth base exception class",
    },
);

1;
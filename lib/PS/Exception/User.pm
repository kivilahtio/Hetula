use 5.22.0;

package PS::Exception::User;

use Exception::Class (
    'PS::Exception::User' => {
        isa => 'PS::Exception',
        description => "User base exception class",
    },
);

1;
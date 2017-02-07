use 5.22.0;

package PS::Exception::Auth;

use Exception::Class (
    'PS::Exception::Auth' => {
        isa => 'PS::Exception',
        description => "Auth base exception class",
    },
);

1;
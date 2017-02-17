use 5.22.0;

package Hetula::Exception::Auth::Authentication;

use Exception::Class (
    'Hetula::Exception::Auth::Authentication' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authentication failed",
    },
);

1;
use 5.22.0;

package PS::Exception::Auth::Authentication;

use Exception::Class (
    'PS::Exception::Auth::Authentication' => {
        isa => 'PS::Exception::Auth',
        description => "Authentication failed",
    },
);

1;
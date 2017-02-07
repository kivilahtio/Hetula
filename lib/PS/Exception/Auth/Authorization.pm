use 5.22.0;

package PS::Exception::Auth::Authorization;

use Exception::Class (
    'PS::Exception::Auth::Authorization' => {
        isa => 'PS::Exception::Auth',
        description => "Authorization failed",
    },
);

1;
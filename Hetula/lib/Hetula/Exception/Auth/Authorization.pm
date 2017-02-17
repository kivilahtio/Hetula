use 5.22.0;

package Hetula::Exception::Auth::Authorization;

use Exception::Class (
    'Hetula::Exception::Auth::Authorization' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authorization failed",
    },
);

1;
use 5.22.0;

package PS::Exception::Auth::Password;

use Exception::Class (
    'PS::Exception::Auth::Password' => {
        isa => 'PS::Exception::Auth',
        description => "Password is wrong",
    },
);

1;
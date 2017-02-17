use 5.22.0;

package Hetula::Exception::Auth::Password;

use Exception::Class (
    'Hetula::Exception::Auth::Password' => {
        isa => 'Hetula::Exception::Auth',
        description => "Password is wrong",
    },
);

1;
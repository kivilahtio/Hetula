use 5.22.0;

package Hetula::Exception::Auth::AccountBlocked;

use Exception::Class (
    'Hetula::Exception::Auth::AccountBlocked' => {
        isa => 'Hetula::Exception::Auth',
        description => "Account has been blocked/frozen due to too many failed login attemps",
    },
);

1;
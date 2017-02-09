use 5.22.0;

package PS::Exception::Auth::AccountBlocked;

use Exception::Class (
    'PS::Exception::Auth::AccountBlocked' => {
        isa => 'PS::Exception::Auth',
        description => "Account has been blocked/frozen due to too many failed login attemps",
    },
);

1;
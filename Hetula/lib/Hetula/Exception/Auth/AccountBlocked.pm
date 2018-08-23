package Hetula::Exception::Auth::AccountBlocked;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::AccountBlocked' => {
        isa => 'Hetula::Exception::Auth',
        description => "Account has been blocked/frozen due to too many failed login attemps",
    },
);

1;
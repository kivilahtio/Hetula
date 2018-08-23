package Hetula::Exception::Auth::Authentication;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::Authentication' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authentication failed",
    },
);

1;
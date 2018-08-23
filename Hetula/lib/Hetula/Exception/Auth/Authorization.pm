package Hetula::Exception::Auth::Authorization;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::Authorization' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authorization failed",
    },
);

1;
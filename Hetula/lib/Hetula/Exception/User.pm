package Hetula::Exception::User;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::User' => {
        isa => 'Hetula::Exception',
        description => "User base exception class",
    },
);

1;
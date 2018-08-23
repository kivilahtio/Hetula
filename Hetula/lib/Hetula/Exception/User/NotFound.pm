package Hetula::Exception::User::NotFound;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::User::NotFound' => {
        isa => 'Hetula::Exception::User',
        description => "No such user in db",
    },
);

1;
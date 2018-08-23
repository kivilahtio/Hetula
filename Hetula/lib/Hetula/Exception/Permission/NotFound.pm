package Hetula::Exception::Permission::NotFound;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Permission::NotFound' => {
        isa => 'Hetula::Exception::Permission',
        description => "No such permission in db",
    },
);

1;
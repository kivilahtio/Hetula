package Hetula::Exception::Database;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Database' => {
        isa => 'Hetula::Exception',
        description => "Daatbase exceptions base class",
    },
);

1;
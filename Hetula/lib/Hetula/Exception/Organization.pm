package Hetula::Exception::Organization;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Organization' => {
        isa => 'Hetula::Exception',
        description => "Organization base exception class",
    },
);

1;
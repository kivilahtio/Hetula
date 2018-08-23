package Hetula::Exception::Environment;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Environment' => {
        isa => 'Hetula::Exception',
        description => "Environment is not properly configured",
    },
);

1;
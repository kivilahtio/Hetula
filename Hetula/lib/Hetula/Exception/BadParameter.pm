package Hetula::Exception::BadParameter;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::BadParameter' => {
        isa => 'Hetula::Exception',
        description => "User supplied a BadParameter",
    },
);

1;
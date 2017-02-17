use 5.22.0;

package Hetula::Exception::BadParameter;

use Exception::Class (
    'Hetula::Exception::BadParameter' => {
        isa => 'Hetula::Exception',
        description => "User supplied a BadParameter",
    },
);

1;
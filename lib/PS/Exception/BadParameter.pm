use 5.22.0;

package PS::Exception::BadParameter;

use Exception::Class (
    'PS::Exception::BadParameter' => {
        isa => 'PS::Exception',
        description => "User supplied a BadParameter",
    },
);

1;
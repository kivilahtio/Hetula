use 5.22.0;

package PS::Exception::Permission;

use Exception::Class (
    'PS::Exception::Permission' => {
        isa => 'PS::Exception',
        description => "Permission base exception class",
    },
);

1;
use 5.22.0;

package Hetula::Exception::Permission;

use Exception::Class (
    'Hetula::Exception::Permission' => {
        isa => 'Hetula::Exception',
        description => "Permission base exception class",
    },
);

1;
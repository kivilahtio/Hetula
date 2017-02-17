use 5.22.0;

package Hetula::Exception::Organization;

use Exception::Class (
    'Hetula::Exception::Organization' => {
        isa => 'Hetula::Exception',
        description => "Organization base exception class",
    },
);

1;
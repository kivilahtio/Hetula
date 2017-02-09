use 5.22.0;

package PS::Exception::Organization;

use Exception::Class (
    'PS::Exception::Organization' => {
        isa => 'PS::Exception',
        description => "Organization base exception class",
    },
);

1;
use 5.22.0;

package Hetula::Exception::Environment;

use Exception::Class (
    'Hetula::Exception::Environment' => {
        isa => 'Hetula::Exception',
        description => "Environment is not properly configured",
    },
);

1;
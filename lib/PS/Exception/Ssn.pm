use 5.22.0;

package PS::Exception::Ssn;

use Exception::Class (
    'PS::Exception::Ssn' => {
        isa => 'PS::Exception',
        description => "Ssn base exception class",
    },
);

1;
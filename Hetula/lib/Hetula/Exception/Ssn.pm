use 5.22.0;

package Hetula::Exception::Ssn;

use Exception::Class (
    'Hetula::Exception::Ssn' => {
        isa => 'Hetula::Exception',
        description => "Ssn base exception class",
    },
);

1;
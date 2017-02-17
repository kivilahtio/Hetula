use 5.22.0;

package Hetula::Exception::Ssn::NotFound;

use Exception::Class (
    'Hetula::Exception::Ssn::NotFound' => {
        isa => 'Hetula::Exception::Ssn',
        description => "No such ssn in db",
    },
);

1;
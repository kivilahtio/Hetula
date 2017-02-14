use 5.22.0;

package PS::Exception::Ssn::NotFound;

use Exception::Class (
    'PS::Exception::Ssn::NotFound' => {
        isa => 'PS::Exception::Ssn',
        description => "No such ssn in db",
    },
);

1;
use 5.22.0;

package PS::Exception::Ssn::AlreadyExists;

use Exception::Class (
    'PS::Exception::Ssn::AlreadyExists' => {
        isa => 'PS::Exception::Ssn',
        description => "Ssn already exists for this given organization",
        fields => ['ssn'],
    },
);

1;
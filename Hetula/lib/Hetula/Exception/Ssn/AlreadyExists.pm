use 5.22.0;

package Hetula::Exception::Ssn::AlreadyExists;

use Exception::Class (
    'Hetula::Exception::Ssn::AlreadyExists' => {
        isa => 'Hetula::Exception::Ssn',
        description => "Ssn already exists for this given organization",
        fields => ['ssn'],
    },
);

1;
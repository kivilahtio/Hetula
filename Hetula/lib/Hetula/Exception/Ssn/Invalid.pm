use 5.22.0;

package Hetula::Exception::Ssn::Invalid;

use Exception::Class (
    'Hetula::Exception::Ssn::Invalid' => {
        isa => 'Hetula::Exception::Ssn',
        description => "Ssn is poorly formed",
        fields => ['ssn'],
    },
);

1;
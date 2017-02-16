use 5.22.0;

package PS::Exception::Ssn::Invalid;

use Exception::Class (
    'PS::Exception::Ssn::Invalid' => {
        isa => 'PS::Exception::Ssn',
        description => "Ssn is poorly formed",
        fields => ['ssn'],
    },
);

1;
package Hetula::Exception::Organization::Duplicate;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Organization::Duplicate' => {
        isa => 'Hetula::Exception::Organization',
        description => "The given organization already exists",
        fields => ['organization'],
    },
);

1;
package Hetula::Exception::Permission::Duplicate;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Permission::Duplicate' => {
        isa => 'Hetula::Exception::Permission',
        description => "The given permission already exists",
        fields => ['permission'],
    },
);

1;
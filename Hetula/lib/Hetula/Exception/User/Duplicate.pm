package Hetula::Exception::User::Duplicate;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::User::Duplicate' => {
        isa => 'Hetula::Exception::User',
        description => "The given user already exists",
        fields => ['user'],
    },
);

1;
package Hetula::Exception::Permission::Duplicate;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Permission::Duplicate' => {
        isa => 'Hetula::Exception::Permission',
        description => "The given permission already exists",
        fields => ['permission'],
    },
);

my $httpStatus = '409';
eval Hetula::Exception::generateNew();

1;
package Hetula::Exception::Ssn::AlreadyExists;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Ssn::AlreadyExists' => {
        isa => 'Hetula::Exception::Ssn',
        description => "Ssn already exists for this given organization",
        fields => ['ssn'],
    },
);

my $httpStatus = '409';
eval Hetula::Exception::generateNew();

1;
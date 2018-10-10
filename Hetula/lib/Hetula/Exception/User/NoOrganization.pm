package Hetula::Exception::User::NoOrganization;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::User::NoOrganization' => {
        isa => 'Hetula::Exception::User',
        description => "User doesn't have any organizations it is part of?",
    },
);

my $httpStatus = '400';
eval Hetula::Exception::generateNew();

1;

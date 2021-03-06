package Hetula::Exception::Ssn::NotFound;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Ssn::NotFound' => {
        isa => 'Hetula::Exception::Ssn',
        description => "No such ssn in db",
    },
);

my $httpStatus = '404';
eval Hetula::Exception::generateNew();

1;
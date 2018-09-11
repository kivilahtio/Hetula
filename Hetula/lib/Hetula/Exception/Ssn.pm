package Hetula::Exception::Ssn;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Ssn' => {
        isa => 'Hetula::Exception',
        description => "Ssn base exception class",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
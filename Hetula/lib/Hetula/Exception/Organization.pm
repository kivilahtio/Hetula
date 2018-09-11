package Hetula::Exception::Organization;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Organization' => {
        isa => 'Hetula::Exception',
        description => "Organization base exception class",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
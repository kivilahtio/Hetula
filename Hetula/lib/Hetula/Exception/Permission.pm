package Hetula::Exception::Permission;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Permission' => {
        isa => 'Hetula::Exception',
        description => "Permission base exception class",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
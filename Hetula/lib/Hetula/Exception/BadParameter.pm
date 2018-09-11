package Hetula::Exception::BadParameter;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::BadParameter' => {
        isa => 'Hetula::Exception',
        description => "User supplied a BadParameter",
    },
);

my $httpStatus = '400';
eval Hetula::Exception::generateNew();

1;
package Hetula::Exception::Auth;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth' => {
        isa => 'Hetula::Exception',
        description => "Auth base exception class",
    },
);

my $httpStatus = '401';
eval Hetula::Exception::generateNew();

1;
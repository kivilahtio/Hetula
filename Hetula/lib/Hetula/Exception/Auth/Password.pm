package Hetula::Exception::Auth::Password;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::Password' => {
        isa => 'Hetula::Exception::Auth',
        description => "Password is wrong",
    },
);

my $httpStatus = '401';
eval Hetula::Exception::generateNew();

1;
package Hetula::Exception::Auth::Authentication;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::Authentication' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authentication failed",
    },
);

my $httpStatus = '401';
eval Hetula::Exception::generateNew();

1;
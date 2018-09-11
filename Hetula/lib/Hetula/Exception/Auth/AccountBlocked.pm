package Hetula::Exception::Auth::AccountBlocked;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::AccountBlocked' => {
        isa => 'Hetula::Exception::Auth',
        description => "Account has been blocked/frozen due to too many failed login attemps",
    },
);

my $httpStatus = '403';
eval Hetula::Exception::generateNew();

1;
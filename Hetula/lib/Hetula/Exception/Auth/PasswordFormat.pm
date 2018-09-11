package Hetula::Exception::Auth::PasswordFormat;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::PasswordFormat' => {
        isa => 'Hetula::Exception::Auth',
        description => "Password doesn't meet the expected password format",
    },
);

my $httpStatus = '400';
eval Hetula::Exception::generateNew();

1;
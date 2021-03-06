package Hetula::Exception::Auth::CSRF;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::CSRF' => {
        isa => 'Hetula::Exception::Auth',
        description => "Cross-Site Request Forgery attempt suspected. Authentication failed",
    },
);

my $httpStatus = '401';
eval Hetula::Exception::generateNew();

1;
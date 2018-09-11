package Hetula::Exception::Auth::Authorization;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Auth::Authorization' => {
        isa => 'Hetula::Exception::Auth',
        description => "Authorization failed",
    },
);

my $httpStatus = '403';
eval Hetula::Exception::generateNew();

1;
package Hetula::Exception::Organization::NotFound;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Organization::NotFound' => {
        isa => 'Hetula::Exception::Organization',
        description => "No such organization in db",
    },
);

my $httpStatus = '404';
eval Hetula::Exception::generateNew();

1;
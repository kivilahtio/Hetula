package Hetula::Exception::Log::NotFound;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Log::NotFound' => {
        isa => 'Hetula::Exception::Log',
        description => "No such log in db",
    },
);

my $httpStatus = '404';
eval Hetula::Exception::generateNew();

1;
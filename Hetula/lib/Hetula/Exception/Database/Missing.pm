package Hetula::Exception::Database::Missing;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Database::Missing' => {
        isa => 'Hetula::Exception::Database',
        description => "Database has not been installed yet",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
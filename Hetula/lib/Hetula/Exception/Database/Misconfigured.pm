package Hetula::Exception::Database::Misconfigured;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Database::Misconfigured' => {
        isa => 'Hetula::Exception::Database',
        description => "Database is somehow broken?",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
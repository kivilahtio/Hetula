package Hetula::Exception::Database::Upgrade;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Database::Upgrade' => {
        isa => 'Hetula::Exception::Database',
        description => "Database upgrade failed",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;

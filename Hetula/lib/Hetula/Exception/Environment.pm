package Hetula::Exception::Environment;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Environment' => {
        isa => 'Hetula::Exception',
        description => "Environment is not properly configured",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
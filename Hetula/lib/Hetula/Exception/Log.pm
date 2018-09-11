package Hetula::Exception::Log;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Log' => {
        isa => 'Hetula::Exception',
        description => "Log base exception class",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
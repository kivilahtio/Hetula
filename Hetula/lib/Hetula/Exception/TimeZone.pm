package Hetula::Exception::TimeZone;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::TimeZone' => {
        isa => 'Hetula::Exception',
        description => "TimeZone funny business",
    },
);

my $httpStatus = '500';
eval Hetula::Exception::generateNew();

1;
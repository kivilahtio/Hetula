use 5.22.0;

package Hetula::Exception::TimeZone;

use Exception::Class (
    'Hetula::Exception::TimeZone' => {
        isa => 'Hetula::Exception',
        description => "TimeZone funny business",
    },
);

1;
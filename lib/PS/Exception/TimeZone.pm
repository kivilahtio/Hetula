use 5.22.0;

package PS::Exception::TimeZone;

use Exception::Class (
    'PS::Exception::TimeZone' => {
        isa => 'PS::Exception',
        description => "TimeZone funny business",
    },
);

1;
use 5.22.0;

package PS::Exception::Log;

use Exception::Class (
    'PS::Exception::Log' => {
        isa => 'PS::Exception',
        description => "Log base exception class",
    },
);

1;
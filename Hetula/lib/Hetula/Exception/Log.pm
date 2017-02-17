use 5.22.0;

package Hetula::Exception::Log;

use Exception::Class (
    'Hetula::Exception::Log' => {
        isa => 'Hetula::Exception',
        description => "Log base exception class",
    },
);

1;
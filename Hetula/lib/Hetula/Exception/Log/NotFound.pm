use 5.22.0;

package Hetula::Exception::Log::NotFound;

use Exception::Class (
    'Hetula::Exception::Log::NotFound' => {
        isa => 'Hetula::Exception::Log',
        description => "No such log in db",
    },
);

1;
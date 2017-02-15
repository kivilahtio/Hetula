use 5.22.0;

package PS::Exception::Log::NotFound;

use Exception::Class (
    'PS::Exception::Log::NotFound' => {
        isa => 'PS::Exception::Log',
        description => "No such log in db",
    },
);

1;
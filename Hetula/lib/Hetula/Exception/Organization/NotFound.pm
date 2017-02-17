use 5.22.0;

package Hetula::Exception::Organization::NotFound;

use Exception::Class (
    'Hetula::Exception::Organization::NotFound' => {
        isa => 'Hetula::Exception::Organization',
        description => "No such organization in db",
    },
);

1;
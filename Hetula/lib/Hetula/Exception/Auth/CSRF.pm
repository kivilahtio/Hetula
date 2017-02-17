use 5.22.0;

package Hetula::Exception::Auth::CSRF;

use Exception::Class (
    'Hetula::Exception::Auth::CSRF' => {
        isa => 'Hetula::Exception::Auth',
        description => "Cross-Site Request Forgery attempt suspected. Authentication failed",
    },
);

1;
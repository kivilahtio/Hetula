use 5.22.0;

package PS::Exception::Auth::CSRF;

use Exception::Class (
    'PS::Exception::Auth::CSRF' => {
        isa => 'PS::Exception::Auth',
        description => "Cross-Site Request Forgery attempt suspected. Authentication failed",
    },
);

1;
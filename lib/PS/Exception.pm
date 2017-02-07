use 5.22.0;

package PS::Exception;

use Exception::Class (
    'PS::Exception' => {
        description => 'PatronStore exceptions base class',
    },
);

sub newFromDie {
    my ($class, $die) = @_;
    return PS::Exception->new(error => "$die");
}

return 1;

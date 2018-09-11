package Hetula::Exception::Ssn::Invalid;

use Hetula::Pragmas;

use Exception::Class (
    'Hetula::Exception::Ssn::Invalid' => {
        isa => 'Hetula::Exception::Ssn',
        description => "Ssn is poorly formed",
        fields => ['ssn'],
    },
);

my $httpStatus = '400';
eval Hetula::Exception::generateNew();

1;
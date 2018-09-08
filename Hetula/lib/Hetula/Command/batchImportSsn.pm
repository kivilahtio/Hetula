package Hetula::Command::batchImportSsn;

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util 'getopt';

use Hetula::Pragmas;

use Hetula::Organizations;
use Hetula::Ssns;

use Hetula::Exception;

has 'description' => 'Add a bunch of ssns for the given organization.';
has 'usage' => <<"USAGE";
$0 batchImportSsn [OPTIONS]
OPTIONS:
  -o --organization     String, name of the new Organization
  -f --file             String, path to the file with id,ssn -pairs

Writes borrowernumber,ssnId -rows to a file next to the given --file.
Here the given ssns are translated into Hetula ssn.ids or a result description.

This --file.out -file can be sent to the target system as an anonymized version
of the sensitive values.

USAGE

sub run {
  my ($self, @args) = @_;

  getopt(  
    \@args,  
    'o|organization=s' => \my $organization,
    'f|file=s'         => \my $file,
  );  

  my $app = $self->app;

  my $org = Hetula::Organizations::getOrganization({name => $organization});

  open (my $FH_IN,  "<:encoding(UTF-8)", $file)        or die("Failed to open ssn batch file '$file' for reading: $!");
  open (my $FH_OUT, ">:encoding(UTF-8)", $file.'.out') or die("Failed to open ssn-keys batch file '$file.out' for writing: $!");

  while (my $kv = <$FH_IN>) {
    chomp($kv);
    my ($ownerId, $ssnVal) = split(',', $kv);
    try {
      my $ssn = Hetula::Ssns::createSsn({ssn => $ssnVal}, $org);
      print $FH_OUT "$ownerId,".$ssn->id."\n";
    } catch {
      if (blessed($_) && $_->isa('Hetula::Exception::Ssn::Invalid')) {
        print $FH_OUT "$ownerId,INVALID:$ssnVal\n";
      }
      if (blessed($_) && $_->isa('Hetula::Exception::Ssn::AlreadyExists')) {
        my $ssn = Hetula::Ssns::getSsn({ssn => $ssnVal});
        print $FH_OUT "$ownerId,".$ssn->id."\n";
      }
      print ref($_).': '.$_."\n";
    };
  }
}

1;

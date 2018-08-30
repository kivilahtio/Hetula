package Hetula::Command::addOrganization;

use Mojo::Base 'Mojolicious::Command';
use Mojo::Util 'getopt';

use Hetula::Pragmas;

use Hetula::Organizations;
use Hetula::Users;

use Hetula::Exception;

has 'description' => 'Add a new Organization to use Hetula. Configures the necessary credentials and permissions.';
has 'usage' => <<"USAGE";
$0 addOrganization [OPTIONS]
OPTIONS:
  -o --organization     String, name of the new Organization
  -u --username         String, username of the Organization admin
  -p --password         String, password of the Organization admin

USAGE

sub run {
  my ($self, @args) = @_;

  getopt(
    \@args,
    'o|organization=s' => \my $organization,
    'u|username=s'     => \my $username,
    'p|password=s'     => \my $password,
  );

  my $app = $self->app;

  try {
    Hetula::Organizations::createOrganization({
      name => $organization,
    });
    print("New organization '$organization' succesfully added\n");
  } catch {
    if (blessed($_) && $_->isa('Hetula::Exception::Organization::Duplicate')) {
      print("$_\n");
    }
    else {
      Hetula::Exception::rethrowDefaults($_);
    }
  };


  my $user = {
    username => $username,
    password => $password,
    organizations => [$organization],
    permissions => [
      'users-get',
      'users-post',
      'users-id-get',
      'users-id-delete',
      'users-id-put',
      'ssns-post',
      'ssns-batch-post',
    ],
  };

  try {
    Hetula::Users::createUser($user);
    print("New user '$username' succesfully added\n");
  } catch {
    if (blessed($_) && $_->isa('Hetula::Exception::User::Duplicate')) {
      print("$_\nModifying user instead\n");
      my $existingUser = Hetula::Users::getUser({username => $username});
      $user->{id} = $existingUser->id;
      Hetula::Users::modUser($user);
    }
    else {
      Hetula::Exception::rethrowDefaults($_);
    }
  };
}

1;
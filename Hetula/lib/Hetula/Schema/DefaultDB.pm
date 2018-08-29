package Hetula::Schema::DefaultDB;

=head1 NAME

Hetula::Schema::DefaultDB

=head2 SYNOPSIS

Create the default db contents

=cut

use Hetula::Pragmas;

use Hetula::Users;
use Hetula::Organizations;

use Hetula::Exception::Auth::AccountBlocked;

=head2 populateDB

Is called every time the application starts.
Makes sure the application has the minimum state it needs to operate.

 @throws Hetula::Exception::Auth::AccountBlocked, if the admin account (id=1) is not properly configured

=cut

sub populateDB($app) {
  my ($schema) = Hetula::Schema::schema();

  #Upsert the admin organization
  unless (Hetula::Config::admin_organization()) {
    Hetula::Exception::Auth::AccountBlocked->throw(error => "Hetula app configuration admin_organization is undefined. Cannot create a default super administrator account.");
  }
  my $org;
  try {
    $org = Hetula::Organizations::getOrganization({name => Hetula::Config::admin_organization()});
  } catch {
    $_->rethrow unless (blessed($_) && $_->isa('Hetula::Exception::Organization::NotFound'));
  };
  Hetula::Organizations::createOrganization({name => Hetula::Config::admin_organization()}) unless ($org);

  #Upsert the admin user which has all the permissions
  unless (Hetula::Config::admin_name() && Hetula::Config::admin_pass()) {
    Hetula::Exception::Auth::AccountBlocked->throw(error => "Hetula app configurations admin_name and admin_pass are undefined. Cannot create a default super administrator account.");
  }
  my $admin;
  try {
    $admin = Hetula::Users::getAdmin()
  } catch {
    $_->rethrow unless (blessed($_) && $_->isa('Hetula::Exception::User::NotFound'));
  };

  my $userData = {
    id => 1,
    username => Hetula::Config::admin_name(),
    realname => 'Super administrator account',
    password => Hetula::Config::admin_pass(),
    organizations => [
      Hetula::Config::admin_organization(),
    ]
  };
  unless ($admin) {
    Hetula::Users::createUser($userData);
  }
  else {
    Hetula::Users::modUser($userData);
  }
}

1;

package Hetula::Schema::DefaultDB;

=head1 NAME

Hetula::Schema::DefaultDB

=head2 SYNOPSIS

Create the default db contents

=cut

use Hetula::Pragmas;

use Hetula::Users;

use Hetula::Exception::Auth::AccountBlocked;

=head2 populateDB

Is called every time the application starts.
Makes sure the application has the minimum state it needs to operate.

 @throws Hetula::Exception::Auth::AccountBlocked, if the admin account (id=1) is not properly configured

=cut

sub populateDB($app) {
  my ($schema) = Hetula::Schema::schema();

  #Upsert the admin user which has all the permissions
  unless ($app->config->{admin_name} && $app->config->{admin_pass}) {
    Hetula::Exception::Auth::AccountBlocked->throw(error => "Hetula app configurations admin_name and admin_pass are undefined. Cannot create a default super administrator account.");
  }
  my $admin;
  try {
    $admin = Hetula::Users::getUser({id => 1})
  } catch {
    $_->rethrow unless (blessed($_) && $_->isa('Hetula::Exception::User::NotFound'));
  };

  unless ($admin) {
    Hetula::Users::createUser({id => 1, username => $app->config->{admin_name}, realname => 'Super administrator account', password => $app->config->{admin_pass}});
  }
  else {
    Hetula::Users::modUser({id => 1, username => $app->config->{admin_name}, password => $app->config->{admin_pass}});
  }
}

1;

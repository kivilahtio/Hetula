package Hetula::Controller::Api::V1::Authenticate;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Api::V1::Authenticate

=cut

use Hetula::Pragmas;

use Digest::SHA;

use Hetula;
use Hetula::Users;
use Hetula::Organizations;
use Hetula::Logs;

use Hetula::Exception;
use Hetula::Exception::Auth::Authentication;
use Hetula::Exception::Auth::Authorization;
use Hetula::Exception::Auth::CSRF;
use Hetula::Exception::Auth::AccountBlocked;
use Hetula::Exception::Auth::Password;

=head2 under

under route to authenticate all /api/v1 requests

=cut

sub under {
  my $c = shift;

  #OPTIONS-requests can always pass. CORS needs this.
  if ($c->req->method eq 'OPTIONS') {
    return 1;
  }

  #If we are authenticating, don't demand an existing authentication
  my $path = $c->req->url->path;
  if ($path =~ m!^/api/v1(/auth)?$!i) {
    return 1;
  }

  my $authStatus;
  try {
    $authStatus = $c->_authorizeApiResource();
  } catch {
    $authStatus = 0;
    $c->render(Hetula::Exception::handleDefaults($_));
  };

  $c->app->log->debug("Authentication='$authStatus'. Session '".Hetula::Logger->flatten($c->session)."'. Stash '".Hetula::Logger->flatten($c->stash)."'") if $c->app->log->is_debug;
  return $authStatus;
}

=head2 post

Handles HTTP POST for /api/v1/auth via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $passwordCredentials = $c->validation->param("passwordCredentials");

  try {
    $c->_passwordAuthentication($passwordCredentials->{username}, $passwordCredentials->{password}, $passwordCredentials->{organization});
    _updateCsrfToken($c);
    return $c->render(status => 201, text => 'Session created');

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;

  try {
    my $userid = $c->session->{userid};
    Hetula::Exception::Auth::Authentication->throw(error => 'Session not found')
      unless $userid;

    Hetula::Users::getUser({id => $userid}); #Exception if no user
    return $c->render(status => 204, openapi => undef);

  } catch {
    my @render = Hetula::Exception::handleDefaults($_); #The around_dispatch is triggered instantly when the $c->render() is called, and not when this subroutine returns. Thus we cannot later overload the render-values
    @render = (status => 404, text => $_->toText) if $_->isa('Hetula::Exception::Auth');
    $c->render(@render);
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;

  try {
    my $userid = $c->session->{userid};
    Hetula::Exception::Auth::Authentication->throw(error => 'Session not found')
      unless $userid;

    #Delete the session by expiring it
    $c->session(expires => 1);
    return $c->render(status => 204, openapi => undef);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

=head2 _passwordAuthentication

Does password authentication and other authentication checks.
Puts the candidate user to $c->stash->{logginginuser} as an alternate
means of getting the logging in user without a session.

=cut

sub _passwordAuthentication {
  my ($c, $uname, $pass, $organizationName) = @_;

  my $user = Hetula::Users::getUser({username => $uname});
  $c->stash->{logginginuser} = $user;
  try {
    _checkFailedLoginCount($c, $user);
    my $org = _checkOrganization($c, $organizationName);
    _checkPassword($user, $pass);
    _createSession($c, $user, $org);
    $user->unblockLogin(); #Make sure any previous failures are forgiven, otherwise they accumulate...
  } catch {
    $user->incrementFailedLoginCount;
    Hetula::Exception::rethrowDefaults($_);
  };
}

=head2 _checkFailedLoginCount

=cut

sub _checkFailedLoginCount {
  my ($c, $user) = @_;
  unless ($user && $user->failed_login_count < Hetula::Config::max_failed_login_count() ) {
    Hetula::Exception::Auth::AccountBlocked->throw(error => "Account has been frozen due to too many failed login attemps");
  }
}

=head2 _checkPassword

=cut

sub _checkPassword {
  my ($user, $pass) = @_;
  Hetula::Exception::Auth::Password->throw(error => 'Account disabled') if $user->password eq '!';
  unless ($user && Hetula::Users::_hashPassword($pass) eq $user->password ) {
    Hetula::Exception::Auth::Password->throw(error => 'Wrong password');
  }
}

=head2 _checkOrganization

Checks if the given organization exists and sets it to stash

@RETURNS Hetula::Schema::Result::Organization

=cut

sub _checkOrganization {
  my ($c, $organizationIdOrName) = @_;
  my ($query);
  if ($organizationIdOrName =~ /^\d+$/) {
    $query = {id => $organizationIdOrName};
  }
  else {
    $query = {name => $organizationIdOrName};
  }

  my $org = Hetula::Organizations::getOrganization($query);
  $c->stash->{organization} = $org;
  return $org;
}

=head2 _authorizeApiResource

=cut

sub _authorizeApiResource {
  my ($c) = @_;

  #Check if a session exists
  my $userid = $c->session->{userid};
  Hetula::Exception::Auth::Authentication->throw(error => 'You must authenticate first')
    unless $userid;

  my $org = $c->_checkOrganization($c->session->{organizationid});

  #Check if the user exists
  my $user = Hetula::Users::getUser({id => $userid});

  # Check CSRF token X-CSRF-Token
  my $validation = $c->validation;
  Hetula::Exception::Auth::CSRF->throw(error => 'Cross-Site Request Forgery attempt suspected. Authentication failed.')
          if $validation->csrf_protect->has_error('csrf_token');

  ##Check for the proper permission
  my $path = $c->req->url->path;
  if ($path =~ m!^/api/v1/users/(.+?)(?:/\w+)?$! &&
      ($userid eq $1 || $user->username eq $1)) {
    #User can access his own data if he is otherwise logged in
    my $dummy = 1; #Without this, program hangs here?
  }
  else {
    my $permissionNeeded = $c->app->getPermissionFromRoute($c->match->endpoint);
    unless ($user->hasPermission($permissionNeeded)) {
      Hetula::Exception::Auth::Authorization->throw(error => "User '".$user->username."' is missing permission '$permissionNeeded'");
    }
  }
}

=head2 _createSession

Establishes a Mojolicious::Session

@PARAM1 Mojo::Controller
@PARAM2 Hetula::Schema::Result::User
@PARAM3 Hetula::Schema::Result::Organization

=cut

sub _createSession {
  my ($c, $user, $organization) = @_;
  #Create the session cookie
  $c->session(userid => $user->id);
  $c->session(organizationid => $organization->id);
  $c->session('HttpOnly');
  return $c;
}

=head2 _updateCsrfToken

Adds the X-CSRF-Token -header if it is missing.
Updates existing one.

=cut

sub _updateCsrfToken {
  my ($c) = @_;
  $c->res->headers->header('X-CSRF-Token' => $c->csrf_token);
  return $c;
}

1;

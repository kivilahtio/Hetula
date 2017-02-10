use 5.22.0;

package PatronStore::Controller::Api::V1::Authenticate;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Authenticate

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);
use Digest::SHA;

use PatronStore;
use PatronStore::Users;

use PS::Exception;
use PS::Exception::Auth::Authentication;
use PS::Exception::Auth::Authorization;
use PS::Exception::Auth::CSRF;
use PS::Exception::Auth::AccountBlocked;

=head2 under

under route to authenticate all /api/v1 requests

Puts authenticated user to $c->stash()->{loggedinuser}

=cut

sub under {
  my $c = shift;

  #If we are authenticating, don't demand an existing authentication
  my $path = $c->req->url->path;
  if ($path =~ m!^/api/v1/auth!i) {
    _updateCsrfToken($c);
    return 1;
  }

  my $authStatus;
  try {
    my $userid = $c->session->{userid};
    PS::Exception::Auth::Authentication->throw(error => 'You must authenticate first')
      unless $userid;

    my $user = PatronStore::Users::getUser({id => $userid});

    # Check CSRF token X-CSRF-Token
    my $validation = $c->validation;
    PS::Exception::Auth::CSRF->throw(error => 'Cross-Site Request Forgery attempt suspected. Authentication failed.')
            if $validation->csrf_protect->has_error('csrf_token');

    $c->_authorizeApiResource($user);

    $authStatus = 1; #Return true to tell Mojo to continue processing this request.

  } catch {
    $authStatus = 0;
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 403, text => $_->toText) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 403, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
  };

  return $authStatus;
}

=head2 post

Handles HTTP POST for /api/v1/auth via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $passwordCredentials = $c->validation->param("passwordCredentials");

  try {
    $c->_passwordAuthentication($passwordCredentials->{username}, $passwordCredentials->{password});
    return $c->render(status => 201, text => 'Session created');

  } catch {
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 401, text => $_->toText) if $_->isa('PS::Exception::Auth::Authentication');
    return $c->render(status => 403, text => $_->toText) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->toText) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => PS::Exception::toTextUnknown($_));
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;

  try {
    my $userid = $c->session->{userid};
    PS::Exception::Auth::Authentication->throw(error => 'Session not found')
      unless $userid;

    PatronStore::Users::getUser({id => $userid}); #Exception if no user
    return $c->render(status => 204, openapi => undef);

  } catch {
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->toText) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => PS::Exception::toTextUnknown($_));
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;

  try {
    my $userid = $c->session->{userid};
    PS::Exception::Auth::Authentication->throw(error => 'Session not found')
      unless $userid;

    #Delete the session by expiring it
    $c->session(expires => 1);
    return $c->render(status => 204, openapi => undef);

  } catch {
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 404, text => $_) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 500, text => $_) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => $_);
  };
}

=head2 _passwordAuthentication

=cut

sub _passwordAuthentication {
  my ($c, $uname, $pass) = @_;

  my $user = PatronStore::Users::getUser({username => $uname});
  if ($user && $user->failed_login_count >= $c->config->{max_failed_login_count} ) {
    PS::Exception::Auth::AccountBlocked->throw(error => "Account has been frozen due to too many failed login attemps");
  }
  elsif ($user && Digest::SHA::sha256($pass) eq $user->password ) {
    _createSession($c, $user);
    return $user;
  }
  $user->incrementFailedLoginCount;
  PS::Exception::Auth::Authentication->throw(error => "Username or password is not correct");
}

=head2 _authorizeApiResource

=cut

sub _authorizeApiResource {
  my ($c, $user) = @_;

  my $permissionNeeded = PatronStore::getPermissionFromRoute($c->match->endpoint);
  my $perm = $user->hasPermission($permissionNeeded);
  if ($perm) {
    return 1;
  }
  PS::Exception::Auth::Authorization->throw(error => "User '".$user->username."' is missing permission '$permissionNeeded'");
}

=head2 _createSession

Establishes a Mojolicious::Session

=cut

sub _createSession {
  my ($c, $user) = @_;
  #Create the session cookie
  $c->session(userid => $user->id);
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

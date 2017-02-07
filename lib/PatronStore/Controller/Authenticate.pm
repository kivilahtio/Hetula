use 5.22.0;

package PatronStore::Controller::Authenticate;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Authenticate

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore;
use PatronStore::Users;

use PS::Exception::Auth::Authentication;
use PS::Exception::Auth::Authorization;

=head2 under

under route to authenticate all /api/v1 requests

Puts authenticated user to $c->stash()->{loggedinuser}

=cut

sub under {
  my $c = shift;
  my $path = $c->req->url->path;
  warn "Path ".$path;
  return 1 if $path =~ m!^/api/v1/auth!i;

  try {
    my $userid = $c->session->{userid};
    PS::Exception::Auth::Authentication->throw(error => 'You must authenticate first')
      unless $userid;

    my $user = PatronStore::Users::getUser({userid => $userid});

    $c->_authorizeApiResource($c->req->url->path, $user);

  } catch {
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 403, text => $_->error) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 403, text => 'Authentication failed: '.$_->error) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->error) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => $_);
  };
  return 1; #Return true to tell Mojo to continue processing this request.
}

=head2 post

Handles HTTP POST for /api/v1/auth via Swagger

=cut

sub post {
  my ($c) = @_;

  my $user;
  try {
    $user = $c->_passwordAuthentication($c->req->param('username'), $c->req->param('password'));
  } catch {
    return $c->render(status => 500, text => $_) unless blessed($_); #Hopefully with a good stack trace
    return $c->render(status => 403, text => $_->error) if $_->isa('PS::Exception::Auth');
    return $c->render(status => 403, text => 'Authentication failed: '.$_->error) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 500, text => $_->error) if $_->isa('PS::Exception');
    return $c->render(status => 500, text => $_);
  };
  return $c->render(status => 204);
}

sub get {
  my ($c) = @_;

  return $c->render(status => 204);
}

=head2 _passwordAuthentication

=cut

sub _passwordAuthentication {
  my ($c, $uname, $pass) = @_;

  #Stash the loggedinuser
  $c->stash()->{loggedinuser} = PatronStore::Users::getUser({username => $uname});
  return $c->stash()->{loggedinuser};
  PS::Exception::Auth::Authentication->throw(error => "Username or password is not correct");
}

=head2 _authorizeApiResource

=cut

sub _authorizeApiResource {
  my ($c, $path, $user);

  my $permissionNeeded = $path;
  my @permissions = $user->permissions;
  if (grep {$permissionNeeded} @permissions) {
    return 1;
  }
  PS::Exception::Auth::Authorization->throw(error => "User '".$user->username."' is missing permission '$permissionNeeded'");
}

1;

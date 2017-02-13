use 5.22.0;

package PatronStore::Controller::Api::V1::Users;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Users

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Users;

use PS::Exception::User::NotFound;
use PS::Exception::BadParameter;

sub list {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $users = PatronStore::Users::listUsers();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$users = map {$_->swaggerize($spec)} @$users;
    return $c->render(status => 200, openapi => $users);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
  };
}

sub post {
  my $c = shift->openapi->valid_input or return;
  my $user = $c->validation->param("user");

  try {
    my $u = PatronStore::Users::createUser($user)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $u);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
  };
}

sub put {
  my $c = shift->openapi->valid_input or return;
  my $user = $c->validation->param("user");
  my $id = $c->validation->param("id");

  try {
    $user->{id} = $id;
    if ($user->{id} && $user->{id} != $id) {
        PS::Exception::BadParameter->throw(error => "id in url '$id' and id in User '".$user->{id}."' are different");
    }

    my $u = PatronStore::Users::modUser($user)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $u);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
    return $c->render(status => 400, text => $_->toText) if $_->isa('PS::Exception::BadParameter');
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $user = PatronStore::Users::getUser({id => $id})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $user);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    PatronStore::Users::deleteUser({id => $id});
    return $c->render(status => 204, openapi => undef);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::User::NotFound');
  };
}

1;

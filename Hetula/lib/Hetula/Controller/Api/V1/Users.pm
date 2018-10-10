package Hetula::Controller::Api::V1::Users;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Api::V1::Users

=cut

use Hetula::Pragmas;

use Hetula::Users;

use Hetula::Exception::User::NotFound;
use Hetula::Exception::BadParameter;

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $users = Hetula::Users::listUsers();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$users = map {$_->swaggerize($spec)} @$users;
    return $c->render(status => 200, openapi => $users);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub post {
  my $c = shift->openapi->valid_input or return;
  my $user = $c->validation->param("user");

  try {
    if ($user->{permissions}) {
      Hetula::Permissions::hasPermissions($c->session->{userid}, $user->{permissions});
    }
    $user->{organizations} = [$c->getLoggedInOrganization($c)] unless ($user->{organizations});
    my $u = Hetula::Users::createUser($user)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $u);

  } catch {
    my @render = Hetula::Exception::handleDefaults($_);
    @render = (status => $_->httpStatus, openapi => $_->{user}) if $_->isa('Hetula::Exception::User::Duplicate');
    $c->render(@render);
  };
}

sub put {
  my $c = shift->openapi->valid_input or return;
  my $user = $c->validation->param("user");
  my $id = $c->validation->param("id");
  my $username;

  try {
    #id in the path component can be either an id or an username, depending on it's contents
    if ($id !~ /^\d+$/) {
      $username = $id;
      $id = undef;
      if ($user->{username} && $user->{username} != $username) {
        Hetula::Exception::BadParameter->throw(error => "username in url '$username' and username in User '".$user->{username}."' are different");
      }
    }
    else {
      $user->{id} = $id unless ($user->{id});
      if ($user->{id} && $user->{id} != $id) {
        Hetula::Exception::BadParameter->throw(error => "id in url '$id' and id in User '".$user->{id}."' are different");
      }
    }

    if ($user->{permissions}) {
      Hetula::Permissions::hasPermissions($c->session->{userid}, $user->{permissions});
    }
    my $u = Hetula::Users::modUser($user)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $u);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub putPassword {
  my $c = shift->openapi->valid_input or return;
  my $password = $c->validation->param("password");
  my $id = $c->validation->param("id");
  my $username;

  try {
    my $args = {password => (ref($password) eq 'HASH' ? $password->{password} : $password)};
    #id in the path component can be either an id or an username, depending on it's contents
    if ($id =~ /^\d+$/) {
      $args->{id} = $id;
    }
    else {
      $args->{username} = $id;
    }

    Hetula::Users::modUser($args);
    return $c->render(status => 204, openapi => undef);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $args = {};
    #id in the path component can be either an id or an username, depending on it's contents
    if ($id =~ /^\d+$/) {
      $args->{id} = $id;
    }
    else {
      $args->{username} = $id;
    }

    my $user = Hetula::Users::getUser($args)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $user);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    if ($id !~ /^\d+$/) { #Id is actually a username
      Hetula::Users::deleteUser({username => $id});
    }
    else {
      Hetula::Users::deleteUser({id => $id});
    }
    return $c->render(status => 204, openapi => undef);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

sub deletePassword {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $args = {password => '!'};
    #id in the path component can be either an id or an username, depending on it's contents
    if ($id =~ /^\d+$/) {
      $args->{id} = $id;
    }
    else {
      $args->{username} = $id;
    }

    Hetula::Users::modUser($args);
    return $c->render(status => 204, openapi => undef);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

1;

use 5.22.0;

package PatronStore::Controller::Api::V1::Permissions;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Permissions

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Permissions;

=head2 post

Handles HTTP POST for /api/v1/permissions via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $permission = $c->validation->param("permission");

  try {
    my $perm = PatronStore::Permissions::createPermission($permission)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $perm);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $perm = PatronStore::Permissions::getPermission({id => $id})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $perm);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Permission::NotFound');
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    PatronStore::Permissions::deletePermission({id => $id});
    return $c->render(status => 204, openapi => undef);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Permission::NotFound');
  };
}


1;

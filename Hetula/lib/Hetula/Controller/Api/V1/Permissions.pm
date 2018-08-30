package Hetula::Controller::Api::V1::Permissions;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Api::V1::Permissions

=cut

use Hetula::Pragmas;

use Hetula::Permissions;

=head2 post

Handles HTTP POST for /api/v1/permissions via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $permission = $c->validation->param("permission");

  try {
    my $perm = Hetula::Permissions::createPermission($permission)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $perm);

  } catch {
    return $c->render(status => 409, openapi => $_->{permission}) if $_->isa('Hetula::Exception::Permission::Duplicate');
    return $c->render(status => 500, text => Hetula::Exception::handleDefaults($_));
  };
}

=head2 list

=cut

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $perms = Hetula::Permissions::listPermissions();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$perms = map {$_->swaggerize($spec)} sort {$a->name cmp $b->name} @$perms;
    return $c->render(status => 200, openapi => $perms);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('Hetula::Exception::Permission::NotFound');
    return $c->render(status => 500, text => Hetula::Exception::handleDefaults($_));
  };
}

=head2 get

=cut

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $perm = Hetula::Permissions::getPermission({id => $id})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $perm);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('Hetula::Exception::Permission::NotFound');
    return $c->render(status => 500, text => Hetula::Exception::handleDefaults($_));
  };
}

=head2 delete

=cut

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    Hetula::Permissions::deletePermission({id => $id});
    return $c->render(status => 204, openapi => undef);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('Hetula::Exception::Permission::NotFound');
    return $c->render(status => 500, text => Hetula::Exception::handleDefaults($_));
  };
}


1;

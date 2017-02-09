use 5.22.0;

package PatronStore::Controller::Api::V1::Organizations;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Organizations

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Organizations;

=head2 post

Handles HTTP POST for /api/v1/organizations via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $organization = $c->validation->param("organization");

  try {
    my $org = PatronStore::Organizations::createOrganization($organization)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $org);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;
  my $organizationName = $c->validation->param('name');

  try {
    my $org = PatronStore::Organizations::getOrganization({name => $organizationName})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $org);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $organizationName = $c->validation->param('name');

  try {
    PatronStore::Organizations::deleteOrganizaton({name => $organizationName});
    return $c->render(status => 204, openapi => undef);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
  };
}


1;

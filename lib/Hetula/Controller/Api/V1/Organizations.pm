use 5.22.0;

package Hetula::Controller::Api::V1::Organizations;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Api::V1::Organizations

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use Hetula::Organizations;

=head2 post

Handles HTTP POST for /api/v1/organizations via Swagger

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $organization = $c->validation->param("organization");

  try {
    my $org = Hetula::Organizations::createOrganization($organization)->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $org);

  } catch {
    return $c->render(status => 500, text => PS::Exception::handleDefaults($_));
  };
}

=head2 get

=cut

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $org = Hetula::Organizations::getOrganization({id => $id})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $org);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
    return $c->render(status => 500, text => PS::Exception::handleDefaults($_));
  };
}

=head2 list

=cut

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $orgs = Hetula::Organizations::listOrganizations();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$orgs = map {$_->swaggerize($spec)} sort {$a->name cmp $b->name} @$orgs;
    return $c->render(status => 200, openapi => $orgs);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
    return $c->render(status => 500, text => PS::Exception::handleDefaults($_));
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    Hetula::Organizations::deleteOrganization({id => $id});
    return $c->render(status => 204, openapi => undef);

  } catch {
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
    return $c->render(status => 500, text => PS::Exception::handleDefaults($_));
  };
}


1;

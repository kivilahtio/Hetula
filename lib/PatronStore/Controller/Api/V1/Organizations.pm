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

=head2 get

=cut

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $org = PatronStore::Organizations::getOrganization({id => $id})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $org);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
  };
}

=head2 list

=cut

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $orgs = PatronStore::Organizations::listOrganizations();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$orgs = map {$_->swaggerize($spec)} sort {$a->name cmp $b->name} @$orgs;
    return $c->render(status => 200, openapi => $orgs);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    PatronStore::Organizations::deleteOrganization({id => $id});
    return $c->render(status => 204, openapi => undef);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Organization::NotFound');
  };
}


1;

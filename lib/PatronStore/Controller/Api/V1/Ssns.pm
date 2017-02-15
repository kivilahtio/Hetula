use 5.22.0;

package PatronStore::Controller::Api::V1::Ssns;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Ssns

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Ssns;

use PS::Exception::Ssn::NotFound;
use PS::Exception::BadParameter;

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $ssns = PatronStore::Ssns::listSsns();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$ssns = map {$_->swaggerize($spec)} @$ssns;
    return $c->render(status => 200, openapi => $ssns);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Ssn::NotFound');
  };
}

sub post {
  my $c = shift->openapi->valid_input or return;
  my $ssn = $c->validation->param("ssn");

  try {
    my ($newSsnCreated, $u) = PatronStore::Ssns::createSsn($ssn, $c->stash->{organization});
    $u = $u->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $u) if $newSsnCreated;
    return $c->render(status => 200, openapi => $u);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 409, openapi => $_->{ssn}->swaggerize($c->stash->{'openapi.op_spec'}))
            if $_->isa('PS::Exception::Ssn::AlreadyExists');
  };
}

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $ssn = PatronStore::Ssns::getSsnForOrganization({id => $id}, $c->stash->{organization})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $ssn);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Ssn::NotFound');
  };
}

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    PatronStore::Ssns::deleteSsn({id => $id}, $c->stash->{organization});
    return $c->render(status => 204, openapi => undef);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Ssn::NotFound');
  };
}

1;

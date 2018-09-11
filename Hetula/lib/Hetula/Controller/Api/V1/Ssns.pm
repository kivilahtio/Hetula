package Hetula::Controller::Api::V1::Ssns;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Api::V1::Ssns

=cut

use Hetula::Pragmas;

use Hetula::Ssns;

use Hetula::Exception::Ssn::NotFound;
use Hetula::Exception::BadParameter;

=head2 list

=cut

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $ssns = Hetula::Ssns::listSsns();
    my $spec = $c->stash->{'openapi.op_spec'};
    @$ssns = map {$_->swaggerize($spec)} @$ssns;
    return $c->render(status => 200, openapi => $ssns);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

=head2 post

=cut

sub post {
  my $c = shift->openapi->valid_input or return;
  my $ssn = $c->validation->param("ssn");

  try {
    my ($newSsnCreated, $u) = Hetula::Ssns::createSsn($ssn, $c->stash->{organization});
    $u = $u->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 201, openapi => $u) if $newSsnCreated;
    return $c->render(status => 200, openapi => $u);

  } catch {
    my @render = Hetula::Exception::handleDefaults($_);
    @render = (status => 409, openapi => $_->{ssn}->swaggerize($c->stash->{'openapi.op_spec'})) if $_->isa('Hetula::Exception::Ssn::AlreadyExists');
    $c->render(@render);
  };
}

=head2 batch

=cut

sub batch {
  my $c = shift->openapi->valid_input or return;
  $c->inactivity_timeout(30);
  my $ssns = $c->validation->every_param("ssns");

  try {
    my $ssnReports = Hetula::Ssns::batchCreateSsns($ssns, $c->stash->{organization});
    my $spec = $c->stash->{'openapi.op_spec'};
    @$ssnReports = map {
      $_->{ssn} = $_->{ssn}->swaggerize($spec) if blessed($_->{ssn});
      $_;
    } @$ssnReports;
    return $c->render(status => 200, openapi => $ssnReports);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

=head2 get

=cut

sub get {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    my $ssn = Hetula::Ssns::getSsnForOrganization({id => $id}, $c->stash->{organization})->swaggerize($c->stash->{'openapi.op_spec'});
    return $c->render(status => 200, openapi => $ssn);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

=head2 delete

=cut

sub delete {
  my $c = shift->openapi->valid_input or return;
  my $id = $c->validation->param('id');

  try {
    Hetula::Ssns::deleteSsn({id => $id}, $c->stash->{organization});
    return $c->render(status => 204, openapi => undef);

  } catch {
    $c->render(Hetula::Exception::handleDefaults($_));
  };
}

1;

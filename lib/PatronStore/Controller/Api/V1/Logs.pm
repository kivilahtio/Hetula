use 5.22.0;

package PatronStore::Controller::Api::V1::Logs;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Logs

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Logs;

=head2 list

=cut

sub list {
  my $c = shift->openapi->valid_input or return;

  try {
    my $logs = PatronStore::Logs::searchLogs({
      since          => $c->validation->param('since'),
      until          => $c->validation->param('until'),
      userid         => $c->validation->param('userid'),
      organizationid => $c->validation->param('organizationid'),
    });
    my $spec = $c->stash->{'openapi.op_spec'};
    @$logs = map {$_->swaggerize($spec)} @$logs;
    return $c->render(status => 200, openapi => $logs);

  } catch {
    my $default = PS::Exception::handleDefaults($_);
    return $c->render(status => 500, text => $default) if $default;
    return $c->render(status => 404, text => $_->toText) if $_->isa('PS::Exception::Log::NotFound');
  };
}

1;

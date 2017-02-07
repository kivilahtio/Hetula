use 5.22.0;

package PatronStore;

use Mojo::Base 'Mojolicious';

# ABSTRACT: A secure SSN-Store

=head1 NAME

PatronStore

=cut

use Mojo::IOLoop;

use PatronStore::DB;
use PatronStore::Schema;

=head2 startup

This method will run once at server start

=cut

sub startup {
  my $self = shift;
  my $mode = $self->mode;


  # Forward error messages to the application log
  Mojo::IOLoop->singleton->reactor->on(error => sub {
    my ($reactor, $err) = @_;
    $self->log->error("Exception in a non-blocking operation: ".$err);
  });

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  my $config;
  if ($mode eq 'testing') {
    $config = $self->plugin(Config => {file => 't/config/PatronStore.conf'});
  }
  elsif (-e '/etc/patronstore/PatronStore.conf') {
    $config = $self->plugin(Config => {file => '/etc/patronstore/PatronStore.conf'});
  }
  else {
    $config = $self->plugin(Config => {file => 'config/PatronStore.conf'});
  }
  checkConfig($self, $config);

  $self->sessions->cookie_name('PaStor');
  $self->sessions->default_expiration($config->{session_expiration});
  $self->secrets([$config->{secret}]);

  PatronStore::DB::SetConfig($config);
  PatronStore::Schema::SetConfig($config);

  $self->plugin("OpenAPI" => {
    url => $self->home->rel_file("swagger/v1/swagger.yaml"),
    #Set the root route for Swagger2 routes. Sets the namespace to look for Api::V1 automatically.
    route => $self->routes->under("/api/v1")->to(namespace => 'PatronStore::Controller::Api::V1', controller => 'Authenticate', action => 'under'),
    log_level => 'debug',
    coerce => 1,
  });

  my $r = $self->routes;
  # Normal route to controller
  $r->get('/')->to('default#index');
  $r->get('/api/v1/doc')->to('Api::V1::Doc#index');
}

=head2 checkConfig

Check that configuration options are properly given

=cut

sub checkConfig {
  my ($self, $config) = (@_);

  my $prologue = "Configuration parameter ";
  my @mandatoryConfig = (qw(session_expiration secret));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
  }
}

1;

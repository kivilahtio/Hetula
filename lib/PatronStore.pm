use 5.22.0;

package PatronStore;

use Mojo::Base 'Mojolicious';

# ABSTRACT: A secure SSN-Store

=head1 NAME

PatronStore

=cut

use PatronStore::DB;

=head2 startup

This method will run once at server start

=cut

sub startup {
  my $self = shift;
  my $mode = $self->mode;
  

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

  $self->sessions->default_expiration($config->{session_expiration});
  $self->secrets([$config->{secret}]);

  PatronStore::DB::SetConfig($config);

  $self->plugin("OpenAPI" => {
                  url => $self->home->rel_file("swagger/swagger.yaml"),
                  route => $self->routes->under("/api/v1")->to("Api::V1::Authenticate#route"),
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

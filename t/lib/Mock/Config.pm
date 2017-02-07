use 5.22.0;

package t::lib::Mock::Config;

=head2 checkConfig

Overload checkConfig. Useful for overloading config values to suit specific tests.

=cut

sub checkConfig {
  my ($app, $config) = @_;

  $config = $app->config();
  $config->{secret} = 'test';
}

1;


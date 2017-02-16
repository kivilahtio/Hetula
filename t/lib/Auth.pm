use 5.22.0;

package t::lib::Auth;

use t::lib::U;

=head2 doPasswordLogin

Logs in and sets the session cookie to Test::Mojo->ua

@PARAM1 Test::Mojo
@PARAM2 HASHRef, {
  organization => 'Vaara', #Sets the organization when logging in.
}

=cut

sub doPasswordLogin {
  my ($t, $args) = @_;

  my $login = {
    username => $args->{username} || 'admin',
    password => $args->{password} || '1234',
    organization => $args->{organization} || 'Vaara',
  };
  PatronStore::Users::getUser({username => $login->{username}})->unblockLogin();

  my $tx = $t->ua->post('/api/v1/auth' => {Accept => '*/*'} => json => $login);
  $t->tx($tx); #Set the received transaction
  t::lib::U::debugResponse($t);
  my $cookies = $tx->res->cookies;
  my $sessionCookie = $cookies->[0];
  $t->ua->cookie_jar->add($sessionCookie);

  my $csrfHeader = $tx->res->headers->header('X-CSRF-Token');

  $t->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header('X-CSRF-Token' => $csrfHeader);
  });
  return $t;
}

1;

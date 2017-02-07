use 5.22.0;

package PatronStore::Users;

=head1 NAME

PatronStore::Users

=head2 SYNOPSIS

Manage Users

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Params::Validate qw(:all);

use PatronStore::DB;


=head2 getUser

@RETURNS User-object, a hashref of a user-row

=cut

sub getUser {
  my $args = validate(@_, {
    username => {type => SCALAR, default => undef},
    userid => {type => SCALAR, default => undef},
    cookie_digest => {type => SCALAR, default => undef},
  });

  my $user = _getUser($args);

  bless($user, 'PatronStore::User');
  return $user;
}

=head2 _getUser

=cut

sub _getUser {
  my ($args) = @_;
  my $dbh = PatronStore::DB::dbh();

  my (@queryParams, @placeholders);
  if ($args->{username}) {
    push @queryParams, ' username = ? ';
    push @placeholders, $args->{username};
  }
  if ($args->{userid}) {
    push @queryParams, ' userid = ? ';
    push @placeholders, $args->{userid};
  }
  if ($args->{cookie_digest}) {
    push @queryParams, ' cookie_digest = ? ';
    push @placeholders, $args->{cookie_digest};
  }
  my $sql = 'SELECT * FROM user WHERE '.join('AND',@queryParams);
  my $sth = $dbh->prepare( $sql );
  $sth->execute( @placeholders );
  die $sth->errstr if $dbh->errstr;
  my $user = $sth->fetchrow_hashref();
  return $user;
}


1;

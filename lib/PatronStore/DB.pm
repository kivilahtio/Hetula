use 5.22.0;

package PatronStore::DB;

=head1 NAME

PatronStore::DB

=head2 SYNOPSIS

Manage DB access

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

use DBI;
use Data::Dumper;

our $dbconfig;
our $dbh;


=head2 SetConfig

Validate and set DB config

=cut

sub SetConfig {
  my ($config) = @_;

  my $prologue = "Database configuration parameter ";
  my @mandatoryConfig = (qw(db_driver db_name));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
  }
  if ($config->{db_driver} =~ /^sqlite/i) {
    $dbconfig = $config;
    return; #We got it all for sqlite
  }
  @mandatoryConfig = (qw(db_user db_pass));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
  }
  unless ($config->{db_socket} || ($config->{db_host} && $config->{db_port})) {
    die "$prologue 'db_socket' or 'db_host' and 'db_port' are not defined";
  }
  $dbconfig = $config;
}

sub dbh
{
  if (  ! $dbconfig  ) {
    die "Cannot instantiate a new database handle when \$dbconfig is undefined!";
  }
  if (  (! $dbh) || (! $dbh->ping())  ) {
    $dbh = _new_dbh();
  }
  return $dbh;
}


sub _new_dbh
{
  my $db_driver = $dbconfig->{db_driver};
  my $db_name   = $dbconfig->{db_name};
  my $db_host   = $dbconfig->{db_host};
  my $db_port   = $dbconfig->{db_port};
  my $db_user   = $dbconfig->{db_user};
  my $db_passwd = $dbconfig->{db_pass};
  my $db_socket = $dbconfig->{db_socket};

  #if a unix socket is given use that instead of TCP (as it is way faster!) ONLY Mysql-derivatives
  # Instead of dying, just warn about the error because we can fall back to a TCP-connection.
  if ($db_driver =~ /^sqlite/i) {
    $dbh = DBI->connect("DBI:SQLite:dbname=$db_name", {'RaiseError' => $ENV{DEBUG}?1:0 }) or die $DBI::errstr;
    return $dbh;
  }
  if ($db_socket && ($db_driver =~ /^mysql/i || $db_driver =~ /^mariadb/i)) {
    # MJR added or die here, as we can't work without dbh
    $dbh = DBI->connect("DBI:$db_driver:dbname=$db_name;mysql_socket=$db_socket", $db_user, $db_passwd, {'RaiseError' => $ENV{DEBUG}?1:0 }) or die $DBI::errstr;
  }
  #Try making a TCP connection
  if ((! defined ($dbh))) {
    # MJR added or die here, as we can't work without dbh
    $dbh = DBI->connect("DBI:$db_driver:dbname=$db_name;host=$db_host;port=$db_port", $db_user, $db_passwd, {'RaiseError' => $ENV{DEBUG}?1:0 }) or die $DBI::errstr;
  }

  if ( $db_driver eq 'mysql' ) {
    $dbh->{mysql_auto_reconnect} = 1;
  }

  my $tz = $ENV{TZ};
  if ( $db_driver eq 'mysql' ) { 
    # Koha 3.0 is utf-8, so force utf8 communication between mySQL and koha, whatever the mysql default config.
    # this is better than modifying my.cnf (and forcing all communications to be in utf8)
    $dbh->{'mysql_enable_utf8'}=1; #enable
    $dbh->do("set NAMES 'utf8'");
    ($tz) and $dbh->do(qq(SET time_zone = "$tz"));
  }
  elsif ( $db_driver eq 'Pg' ) {
    $dbh->do( "set client_encoding = 'UTF8';" );
    ($tz) and $dbh->do(qq(SET TIME ZONE = "$tz"));
  }
  return $dbh;
}

=head2 createSchema

Creates the database schema at the configured database

=cut

sub createSchema {
  my $dbh = dbh();

  
}

return 1; #oh my god so awesome!

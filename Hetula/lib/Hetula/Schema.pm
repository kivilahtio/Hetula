package Hetula::Schema;

use Hetula::Pragmas;

use base qw/DBIx::Class::Schema/;
__PACKAGE__->load_namespaces();

my $l = bless({}, 'Hetula::Logger');

=head1 NAME

Hetula::Schema

=head2 SYNOPSIS

Manages DBIx::Class DB access

  use Hetula::Schema;
  my $schema = Hetula::Schema->get();

=cut

# Copyright 2017 Koha-Suomi Oy
# Copyright 2013 Catalyst IT
# chrisc@catalyst.net.nz
#
# This file was part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

our $database = {};
our $dbconfig;

=head2 SetConfig

Validate and set DB config

=cut

sub SetConfig {
  my ($config) = @_;

  my $prologue = "Database configuration parameter ";
  my @mandatoryConfig = (qw(db_driver db_name db_raise_error db_print_error));
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

=head2 _new_schema

# Internal helper function (not a method!). This creates a new
# database connection from the data given in the current context, and
# returns it.

@PARAM1 Boolean, Raise errors aka. turn errors into exceptions?
@PARAM2 Boolean, Print errors, print error messages to STDERR.

=cut

sub _new_schema {
  my ($raiseError, $printError) = @_;

  my $db_driver = $dbconfig->{db_driver};
  my $db_name   = $dbconfig->{db_name};
  my $db_host   = $dbconfig->{db_host} // ''; #In mem SQLite doesn't need host or port
  my $db_port   = $dbconfig->{db_port} // ''; #
  my $db_user   = $dbconfig->{db_user};
  my $db_passwd = $dbconfig->{db_pass};
  my $db_socket = $dbconfig->{db_socket};

  my ( %encoding_attr, $encoding_query, $tz_query );
  my $tz = $ENV{TZ};
  if ( $db_driver eq 'mysql' ) {
    %encoding_attr = (
      mysql_enable_utf8 => 1,
      RaiseError => $raiseError,
      PrintError => $printError,
    );
    $encoding_query = "set NAMES 'utf8'";
    $tz_query = qq(SET time_zone = "$tz") if $tz;
  }
  elsif ( $db_driver eq 'Pg' ) {
    %encoding_attr = (
      pg_enable_utf8 => 1,
      RaiseError => $raiseError,
      PrintError => $printError,
    );
    $encoding_query = "set client_encoding = 'UTF8';";
    $tz_query = qq(SET TIME ZONE = "$tz") if $tz;
  }
  elsif ( $db_driver eq 'SQLite') {
    %encoding_attr = (
      sqlite_unicode => 1,
      RaiseError => $raiseError,
      PrintError => $printError,
    );
  }

  my $schema = Hetula::Schema->connect(
    {
      dsn => "dbi:$db_driver:database=$db_name;host=$db_host;port=$db_port",
      user => $db_user,
      password => $db_passwd,
      %encoding_attr,
      unsafe => 1,
      quote_names => 1,
      on_connect_do => [
        $encoding_query || (),
        $tz_query || (),
      ]
    }
  );

  my $dbh = $schema->storage->dbh;
  $dbh->{RaiseError} = $raiseError;
  $dbh->{PrintError} = $printError;

  return $schema;
}

=head2 schema

  $schema = Hetula::Schema->schema;

Returns a database handle connected to the Koha database for the
current context. If no connection has yet been made, this method
creates one, and connects to the database.
This database handle is cached for future use: if you call
C<$database-E<gt>schema> twice, you will get the same handle both
times. If you need a second database handle, use C<&new_schema> and
possibly C<&set_schema>.

=cut

sub schema {
  my $class = shift;
  my $params = shift;

  unless ( $params->{new} ) {
      return $database->{$PID}->{schema} if (defined($database->{$PID}->{schema}));
  }

  $database->{$PID}->{schema} = &_new_schema();
  return $database->{$PID}->{schema};
}

=head2 keepaliveConnection

    my $schema = Hetula::Schema->keepaliveConnection();

Checks if the connection is alive, if not, reconnects.
This is to circumvent a bug in DBIx::Class where the auto reconnect feature is broken.
https://github.com/dbsrgits/dbix-class/commit/729656c504e5c "Ensure the $storage state reflects the current connection state closely"

=cut

sub keepaliveConnection {
  my $class = shift;

  my $schema = $class->schema();
  my $ensuredConnection = $schema->storage()->ensure_connected();
  $l->debug("\$ensuredConnection=$ensuredConnection");
  unless ($ensuredConnection) {
    $class->flushConnections();
    $schema = $class->schema();
  }
  return $schema;
}

=head2 flushConnections

Removes all active DB connections from caches

=cut

sub flushConnections {
  foreach my $pid (keys %$database) {
    if ($database->{$pid}) {
      if ($database->{$pid}->{schema} && blessed($database->{$pid}->{schema})) {
        $l->debug("\$pid=$pid, \$schema=".$database->{$pid}->{schema});
        $database->{$pid}->{schema}->storage->disconnect();
      }
      else {
        $l->error("Unknown database connection object \$pid=$pid:\n".$l->flatten($database->{$pid}->{schema}));
      }
    }
  }
  $database = {};
}

1;

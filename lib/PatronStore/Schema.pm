use 5.22.0;

package PatronStore::Schema;
use base qw/DBIx::Class::Schema/;

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

__PACKAGE__->load_namespaces();



=head1 NAME

PatronStore::Schema

=head2 SYNOPSIS

Manages DBIx::Class DB access

  use PatronStore::Schema;
  my $schema = PatronStore::Schema->get();

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

use vars qw($database);
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
  my $db_host   = $dbconfig->{db_host};
  my $db_port   = $dbconfig->{db_port};
  my $db_user   = $dbconfig->{db_user};
  my $db_passwd = $dbconfig->{db_pass};
  my $db_socket = $dbconfig->{db_socket};

  my ( %encoding_attr, $encoding_query, $tz_query );
  my $tz = $ENV{TZ};
  if ( $db_driver eq 'mysql' ) {
    %encoding_attr = ( mysql_enable_utf8 => 1 );
    $encoding_query = "set NAMES 'utf8'";
    $tz_query = qq(SET time_zone = "$tz") if $tz;
  }
  elsif ( $db_driver eq 'Pg' ) {
    $encoding_query = "set client_encoding = 'UTF8';";
    $tz_query = qq(SET TIME ZONE = "$tz") if $tz;
  }
  my $schema = PatronStore::Schema->connect(
    {
      dsn => "dbi:$db_driver:database=$db_name;host=$db_host;port=$db_port",
      user => $db_user,
      password => $db_passwd,
      %encoding_attr,
      RaiseError => $raiseError,
      PrintError => $printError,
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

  $schema = $database->schema;
Returns a database handle connected to the Koha database for the
current context. If no connection has yet been made, this method
creates one, and connects to the database.
This database handle is cached for future use: if you call
C<$database-E<gt>schema> twice, you will get the same handle both
times. If you need a second database handle, use C<&new_schema> and
possibly C<&set_schema>.

=cut

sub schema {
  my $self = shift;
  my $params = shift;

  unless ( $params->{new} ) {
      return $database->{schema} if defined $database->{schema};
  }

  $database->{schema} = &_new_schema();
  return $database->{schema};
}

=head2 new_schema

$schema = $database->new_schema;
Creates a new connection to the Koha database for the current context,
and returns the database handle (a C<DBI::db> object).
The handle is not saved anywhere: this method is strictly a
convenience function; the point is that it knows which database to
connect to so that the caller doesn't have to know.

@PARAM passes all params through to _new_schema()

=cut

#'
sub new_schema {
  shift @_ if $_[0] eq __PACKAGE__;
  return &_new_schema(@_);
}

=head2 set_schema

$my_schema = $database->new_schema;
$database->set_schema($my_schema);
...
$database->restore_schema;
C<&set_schema> and C<&restore_schema> work in a manner analogous to
C<&set_context> and C<&restore_context>.
C<&set_schema> saves the current database handle on a stack, then sets
the current database handle to C<$my_schema>.
C<$my_schema> is assumed to be a good database handle.

=cut

sub set_schema {
  my $self       = shift;
  my $new_schema = shift;

  # Save the current database handle on the handle stack.
  # We assume that $new_schema is all good: if the caller wants to
  # screw himself by passing an invalid handle, that's fine by
  # us.
  push @{ $database->{schema_stack} }, $database->{schema};
  $database->{schema} = $new_schema;
}

=head2 restore_schema

$database->restore_schema;
Restores the database handle saved by an earlier call to
C<$database-E<gt>set_schema>.

=cut

sub restore_schema {
  my $self = shift;

  if ( $#{ $database->{schema_stack} } < 0 ) {

      # Stack underflow
      die "SCHEMA stack underflow";
  }

  # Pop the old database handle and set it.
  $database->{schema} = pop @{ $database->{schema_stack} };

  # FIXME - If it is determined that restore_context should
  # return something, then this function should, too.
}

1;

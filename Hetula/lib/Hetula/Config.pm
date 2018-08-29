package Hetula::Config;

=head1 NAME

Hetula::Config

=head2 SYNOPSIS

Manage configurations

=cut

use Hetula::Pragmas;

use Hetula::Exception::Environment;

my $config; #Hetula config

=head2 loadConfigs

Loads and returns all known configuration filepaths

=cut

sub loadConfigs() {
  validateEnvironment();
  checkTimezone();
  my $configPath = getConfig();
  my $log4perlConfigPath = getLog4perlConfig();

  my $hetulaConfig = do $configPath;
  die "couldn't parse $configPath: $@" if $@;
  die "couldn't do $configPath: $!"    unless defined $hetulaConfig;
  die "couldn't run $configPath"       unless $hetulaConfig;
  validateConfig($hetulaConfig);
  $config = $hetulaConfig;

  Hetula::Schema::SetConfig($hetulaConfig);
  return ($configPath, $log4perlConfigPath);
}

=head2 getLog4perlConfig

=cut

sub getLog4perlConfig() {
  return _getConfig('log4perl.conf');
}

=head2 getConfig

=cut

sub getConfig() {
  return _getConfig('hetula.conf');
}

=head2 validateConfig

Check that configuration options are properly given

=cut

sub validateConfig($config) {
  my $prologue = "Configuration parameter ";
  my @mandatoryConfig = (qw(session_expiration secret));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
  }
  return $config;
}

=head3 _getConfig

Does it's best to find the correct configuration file from different operational modes
'testing'|...

 @returns String, path to the given config file from the current operational mode.
 @throws Hetula::Exception::Environment, if the config file is not accessible.

=cut

sub _getConfig($filename) {
  my $filepath = $ENV{HETULA_CONFIGS}.'/'.$filename.'-'.$ENV{MOJO_MODE};
  if (! -r $filepath) {
    Hetula::Exception::Environment->throw(error => "Configuration file '$filepath' is not readable by the current user '".$ENV{LOGNAME} || $ENV{USER} || getpwuid($<)."'");
  }
  return $filepath;
}

=head2 validateEnvironment

Make sure the expected environment variables do exist

Output a short summary about environment variables that can be used and are in use

=cut

sub validateEnvironment() {
  if (! $ENV{HETULA_CONFIGS}) {
    Hetula::Exception::Environment->throw(error => "Environment variable HETULA_CONFIGS is not defined!");
  }
  elsif(! -d $ENV{HETULA_CONFIGS}) {
    Hetula::Exception::Environment->throw(error => "Environment variable HETULA_CONFIGS='".$ENV{HETULA_CONFIGS}."' must point to a directory!");
  }

  unless($ENV{MOJO_MODE} && ($ENV{MOJO_MODE} eq 'production' || $ENV{MOJO_MODE} eq 'testing' || $ENV{MOJO_MODE} eq 'development')) {
    Hetula::Exception::Environment->throw(error => "Environment variable MOJO_MODE='".($ENV{MOJO_MODE} // 'undefined')."' is not one of production|testing|development !");
  }
}

=head2 getEnvironmentDescription

 @returns String, textual representation of the currently known environment variables Hetula uses

=cut

sub getEnvironmentDescription() {
  my @sb;
  push(@sb, "Available environment variables:");
  push(@sb, "TZ=".($ENV{TZ} // '').", sets the time zone. Defaults to 'date +%z'");
  push(@sb, "HETULA_CONFIGS=".($ENV{HETULA_CONFIGS} // 'undefined').", where the Hetula configuration files are located");
  push(@sb, "MOJO_MODE=".($ENV{MOJO_MODE} // 'undefined'));
  return join("\n", @sb);
}

=head2 checkTimezone

Sets $ENV{TZ} for DateTime to properly do timezone calculations

=cut

sub checkTimezone() {
  my $env = $ENV{TZ};
  unless($env) {
    my $tz = `date +%z`;
    unless ($tz) {
      Hetula::Exception::TimeZone->throw(error => "checkTimezone():> Couldn't infer the correct timezone from \$ENV{TZ} or `date +%z`. You must set your system timezone");
    }
    $ENV{TZ} = $tz;
  }
}

=head1 Config accessors

Typo-safely access config values

=cut

=head2 secret

=cut

sub secret($val=undef) {
  $config->{secret} = $val if $val;
  return $config->{secret};
}

=head2 admin_name

=cut

sub admin_name($val=undef) {
  $config->{admin_name} = $val if $val;
  return $config->{admin_name};
}

=head2 admin_pass

=cut

sub admin_pass($val=undef) {
  $config->{admin_pass} = $val if $val;
  return $config->{admin_pass};
}

=head2 admin_organization

=cut

sub admin_organization($val=undef) {
  $config->{admin_organization} = $val if $val;
  return $config->{admin_organization};
}

=head2 session_expiration

=cut

sub session_expiration($val=undef) {
  $config->{session_expiration} = $val if $val;
  return $config->{session_expiration};
}

=head2 max_failed_login_count

=cut

sub max_failed_login_count($val=undef) {
  $config->{max_failed_login_count} = $val if $val;
  return $config->{max_failed_login_count};
}

=head2 db_driver

=cut

sub db_driver($val=undef) {
  $config->{db_driver} = $val if $val;
  return $config->{db_driver};
}

=head2 db_name

=cut

sub db_name($val=undef) {
  $config->{db_name} = $val if $val;
  return $config->{db_name};
}

=head2 db_host

=cut

sub db_host($val=undef) {
  $config->{db_host} = $val if $val;
  return $config->{db_host};
}

=head2 db_port

=cut

sub db_port($val=undef) {
  $config->{db_port} = $val if $val;
  return $config->{db_port};
}

=head2 db_user

=cut

sub db_user($val=undef) {
  $config->{db_user} = $val if $val;
  return $config->{db_user};
}

=head2 db_pass

=cut

sub db_pass($val=undef) {
  $config->{db_pass} = $val if $val;
  return $config->{db_pass};
}

=head2 db_socket

=cut

sub db_socket($val=undef) {
  $config->{db_socket} = $val if $val;
  return $config->{db_socket};
}

=head2 db_raise_error

=cut

sub db_raise_error($val=undef) {
  $config->{db_raise_error} = $val if $val;
  return $config->{db_raise_error};
}

=head2 db_print_error

=cut

sub db_print_error($val=undef) {
  $config->{db_print_error} = $val if $val;
  return $config->{db_print_error};
}

1;

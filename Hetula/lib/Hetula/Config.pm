package Hetula::Config;

=head1 NAME

Hetula::Config

=head2 SYNOPSIS

Manage configurations

=cut

use Hetula::Pragmas;

use Hetula::Exception::Environment;

=head2 loadConfigs

Loads and returns all known configuration filepaths

=cut

sub loadConfigs() {
  validateEnvironment();
  checkTimezone();
  my $configPath = getConfig();
  my $log4perlConfigPath = getLog4perlConfig();

  my $config = do $configPath;
  die "couldn't parse $configPath: $@" if $@;
  die "couldn't do $configPath: $!"    unless defined $config;
  die "couldn't run $configPath"       unless $config;
  validateConfig($config);

  Hetula::Schema::SetConfig($config);
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

1;

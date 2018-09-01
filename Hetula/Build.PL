use 5.22.0;
use Module::Build;

use Cwd;
use File::Copy;

my $class = Module::Build->subclass(
  class => "Module::Build::Custom",
  code => <<'SUBCLASS' );

sub ACTION_install {
  my $self = shift;
  $self->SUPER::ACTION_install;

  my $systemdServiceFile = '/etc/systemd/system/hetula.service';
  my $HETULA_HOME = Cwd::getcwd().'/'; #Build.PL is in the root of the program directory, Module::Build normalizes cwd to point to the root of the app.
  my $HETULA_CONFIGS = '/etc/hetula/';
  my $HETULA_USER = 'hetula';


  ###########################
  ### Set the environment ###
  ###########################

  $self->log_info( "Setting HETULA_HOME=$HETULA_HOME\n" );
  my $cmd = "(grep -P '^HETULA_HOME' /etc/environment && sed -i 's!^HETULA_HOME.*\$!HETULA_HOME=$HETULA_HOME!' /etc/environment) || echo 'HETULA_HOME=$HETULA_HOME' >> /etc/environment";
  $self->do_system( $cmd );

  $self->log_info( "Setting HETULA_CONFIGS=$HETULA_CONFIGS\n" );
  $cmd = "(grep -P '^HETULA_CONFIGS' /etc/environment && sed -i 's!^HETULA_CONFIGS.*\$!HETULA_CONFIGS=$HETULA_CONFIGS!' /etc/environment) || echo 'HETULA_CONFIGS=$HETULA_CONFIGS' >> /etc/environment";
  $self->do_system( $cmd );


  ###########################
  ### Add the hetula-user ###
  ###########################

  my $userExists = `/bin/grep -P '$HETULA_USER' /etc/passwd`;
  unless ($userExists) {
    $self->log_info( "Adding user '$HETULA_USER'\n" );
    $self->do_system( '/usr/sbin/useradd $HETULA_USER' ) unless $userExists;
  }
  else {
    $self->log_info( "User '$HETULA_USER' exists\n" );
  }


  ###################################
  ### Install system config files ###
  ###################################

  unless (-d $HETULA_CONFIGS) {
    $self->log_info( "Creating $HETULA_CONFIGS\n" );
    mkdir $HETULA_CONFIGS;
  }
  unless (-e "$HETULA_CONFIGS/hetula.conf-production") {
    $self->log_info( "Creating '$HETULA_CONFIGS/hetula.conf'\n" );
    File::Copy::copy('config/hetula.conf', "$HETULA_CONFIGS/hetula.conf-production");
    File::Copy::copy('config/hetula.conf', "$HETULA_CONFIGS/hetula.conf-testing");
  }
  else {
    $self->log_info( "'$HETULA_CONFIGS/hetula.conf' exists\n" );
  }
  unless (-e "$HETULA_CONFIGS/log4perl.conf-production") {
    $self->log_info( "Creating '$HETULA_CONFIGS/log4perl.conf'\n" );
    File::Copy::copy('config/log4perl.conf', "$HETULA_CONFIGS/log4perl.conf-production");
    File::Copy::copy('config/log4perl.conf', "$HETULA_CONFIGS/log4perl.conf-testing");
  }
  else {
    $self->log_info( "'$HETULA_CONFIGS/log4perl.conf' exists\n" );
  }


  ###############################
  ### Install systemd service ###
  ###############################

  $self->log_info( "Deploying the 'hetula'-service\n" );
  File::Copy::copy('etc/systemd/system/hetula.service', $systemdServiceFile);

  $self->log_info( "Rewriting systemd unit file paths\n" );
  $cmd = "sed -i 's!\${HETULA_HOME}!$HETULA_HOME!' $systemdServiceFile";
  $self->do_system( $cmd );
  $cmd = "sed -i 's!\${HETULA_CONFIGS}!$HETULA_CONFIGS!' $systemdServiceFile";
  $self->do_system( $cmd );

  $self->log_info( "Enabling 'hetula'-service\n" );
  $self->do_system( '/bin/systemctl daemon-reload' );
  $self->do_system( '/bin/systemctl enable hetula' );


  ##############################################
  ### Show manual configuration instructions ###
  ##############################################

  print "\n";
  print "Hetula has been installed.\n";
  print "To be able to test and run Hetula in production, you must configure the configuration files for different modes of operation.\n";
  print "Configuration files are installed into '$HETULA_CONFIGS'.\n";
  print "\n";
  print "After configuring $HETULA_CONFIGS/hetula.conf-testing, run ./Build test to make sure your Hetula-instance works correctly in your environment.\n";
  print "If everything passes, you are ready for production.\n";
  print "\n";
}

sub ACTION_test {
  my $self = shift;

  die "Environment variable HETULA_CONFIGS not set, have you installed and configured hetula.conf-testing first?" unless $ENV{HETULA_CONFIGS};

  $self->do_system( '/usr/bin/prove -I. -Ilib t' );
}

sub ACTION_commit {
  #This is just a useless reminder to extend more features
  my $self = shift;

  $self->depends_on("test");
  $self->log_warn( "#I am a useless commit action stub#" );
}
SUBCLASS

$class->new(
  module_name => 'Hetula',
  dist_author => 'Olli-Antti Kivilahti <olli-antti.kivilahti@jns.fi>',
  dist_abstract => '"Simple" SSN store',

  build_requires => {

  },
  requires => {
    'Carp::Always'                      => '> 0.01',
    'DateTime'                          => '> 0.01',
    'DateTime::Format::ISO8601'         => '> 0.01',
    'DBIx::Class'                       => '> 0.01',
    'DBIx::Class::Migration'            => '> 0.01',
    'DBIx::Class::TimeStamp'            => '> 0.01',
    'DBIx::Class::InflateColumn::Object::Enum' => '> 0.01',
    'Digest::SHA'                       => '> 0.01',
    'Import::Into'                      => '> 0.01',
    'List::Util'                        => '> 0.01',
    'Log::Log4perl'                     => '> 0.01',
    'Modern::Perl'                      => '> 0.01',
    'Mojolicious'                       => '> 0.01',
    'Mojolicious::Plugin::OpenAPI'      => '> 0.01',
    'MojoX::Log::Log4perl'              => '> 0.01',
    'SQL::Translator'                   => '> 0.01',
    'Test::MockModule'                  => '> 0.01',
    'Time::HiRes'                       => '> 0.01',
    'Try::Tiny'                         => '> 0.01',
    'YAML::XS'                          => '> 0.01',
  },
)->create_build_script;


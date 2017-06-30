use 5.22.0;
use Module::Build;

use Cwd;

my $class = Module::Build->subclass(
  class => "Module::Build::Custom",
  code => <<'SUBCLASS' );

sub ACTION_install {
  my $self = shift;
  $self->SUPER::ACTION_install;

  ###Add the hetula-user###
  my $userExists = `/bin/grep -P 'hetula' /etc/passwd`;
  unless ($userExists) {
    $self->log_info( "Adding user 'hetula'\n" );
    $self->do_system( '/usr/sbin/useradd hetula' ) unless $userExists;
  }
  else {
    $self->log_info( "User 'hetula' exists\n" );
  }

  ###Install systemd service and system config file
  require File::Copy;
  $self->log_info( "Deploying the 'hetula'-service\n" );
  File::Copy::copy('etc/systemd/system/hetula.service', '/etc/systemd/system/hetula.service');
  unless (-d '/etc/hetula') {
    $self->log_info( "Creating '/etc/hetula'\n" );
    mkdir '/etc/hetula';
  }
  unless (-e '/etc/hetula/hetula.conf') {
    $self->log_info( "Creating '/etc/hetula/hetula.conf'\n" );
    File::Copy::copy('config/hetula.conf', '/etc/hetula/hetula.conf');
  }
  else {
    $self->log_info( "'/etc/hetula/hetula.conf' exists\n" );
  }
  unless (-e '/etc/hetula/log4perl.conf') {
    $self->log_info( "Creating '/etc/hetula/log4perl.conf'\n" );
    File::Copy::copy('config/log4perl.conf', '/etc/hetula/log4perl.conf');
  }
  else {
    $self->log_info( "'/etc/hetula/log4perl.conf' exists\n" );
  }

  my $HETULA_HOME = Cwd::getcwd();
  $self->log_info( "Setting HETULA_HOME=$HETULA_HOME environment variable" );
  my $cmd = "(grep -P '^HETULA_HOME' /etc/environment && sed -i 's!^HETULA_HOME.*\$!HETULA_HOME=$HETULA_HOME!' /etc/environment) || echo 'HETULA_HOME=$HETULA_HOME' >> /etc/environment";
  $self->do_system( $cmd );

  $self->log_info( "Enabling 'hetula'-service\n" );
  $self->do_system( '/bin/systemctl daemon-reload' );
  $self->do_system( '/bin/systemctl enable hetula' );
}

sub ACTION_test {
  my $self = shift;

  $self->do_system( '/usr/bin/prove -Ilib t' );
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
    'Carp'                              => '> 0.01',
    'DateTime'                          => '> 0.01',
    'DateTime::Format::ISO8601'         => '> 0.01',
    'DBIx::Class'                       => '> 0.01',
    'DBIx::Class::TimeStamp'            => '> 0.01',
    'DBIx::Class::InflateColumn::Object::Enum' => '> 0.01',
    'Digest::SHA'                       => '> 0.01',
    'Log::Log4perl'                     => '> 0.01',
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


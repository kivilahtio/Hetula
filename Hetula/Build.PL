use 5.22.0;
use Module::Build;

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
  $self->log_info( "Enabling 'hetula'-service\n" );
  $self->do_system( '/bin/systemctl daemon-reload' );
  $self->do_system( '/bin/systemctl enable hetula' );
}

sub ACTION_test {
  my $self = shift;

  $self->do_system( '/usr/local/bin/prove -Ilib t' );
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
    'Carp'                              => undef,
    'DateTime'                          => undef,
    'DateTime::Format::ISO8601'         => undef,
    'DBIx::Class'                       => undef,
    'DBIx::Class::TimeStamp'            => undef,
    'Digest::SHA'                       => undef,
    'Mojolicious'                       => undef,
    'Mojolicious::Plugin::OpenAPI'      => undef,
    'SQL::Translator'                   => undef,
    'Test::MockModule'                  => undef,
    'Time::HiRes'                       => undef,
    'Try::Tiny'                         => undef,
    'YAML::XS'                          => undef,
  },
)->create_build_script;


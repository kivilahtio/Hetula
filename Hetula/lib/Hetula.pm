use 5.22.0;

package Hetula;

use Mojo::Base 'Mojolicious';

# ABSTRACT: A secure SSN-Store

=head1 NAME

Hetula

=cut

use Mojo::IOLoop;

use FindBin;
use Try::Tiny;
use Scalar::Util qw(blessed);

use Log::Log4perl;
use MojoX::Log::Log4perl;

use Hetula::Schema;
use Hetula::Schema::DefaultDB;
use Hetula::Permissions;
use Hetula::Users;
use Hetula::Logs;

use Hetula::Exception::TimeZone;
use Hetula::Exception::Environment;

=head2 startup

This method will run once at server start

=cut

sub startup {
  my $self = shift;
  my $mode = $self->mode;

  $self->checkTimezone();

  # Forward error messages to the application log
  Mojo::IOLoop->singleton->reactor->on(error => sub {
    my ($reactor, $err) = @_;
    $self->log->error("Exception in a non-blocking operation: ".$err);
  });

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');

  my $config = $self->getConfig();
  $self->log( MojoX::Log::Log4perl->new( $self->getLog4perlConfig() ) );
  $self->log->info('Initialized MojoX::Log::Log4perl');

  $self->sessions->cookie_name('PaStor');
  $self->sessions->default_expiration($config->{session_expiration});
  $self->secrets([$config->{secret}]);

  Hetula::Schema::SetConfig($config);
  Hetula::Schema::isDBOk();
  Hetula::Schema::DefaultDB::populateDB($self);

  $self->plugin("OpenAPI" => {
    url => $self->home->rel_file("public/api/v1/swagger/swagger.yaml"),
    #Set the root route for Swagger2 routes. Sets the namespace to look for Api::V1 automatically.
    route => $self->routes->under("/api/v1")->to(namespace => 'Hetula::Controller::Api::V1', controller => 'Authenticate', action => 'under'),
    log_level => 'debug',
    coerce => 1,
    spec_route_name => 'apiv1spec',
  });

  $self->createPermissions();

  my $r = $self->routes;
  # Normal route to controller
  $r->get('/')->to('default#index');
  $r->get('/api/v1/doc')->to('Api::V1::Doc#index');
  $r->get('/api/v1/doc/*path')->to('Api::V1::Doc#swagger_ui');

  ## Log the transaction
  $self->hook(after_dispatch => sub {
    my $c = shift;
    my $path = $c->req->url->path;
    Hetula::Logs::createLog($c) if ($path =~ m!^/api/v1! && $path !~ m!^/api/v1/doc!);
  });

  ##Fix a bug in DBIx::Class version 0.082840 where 'MySQL server has gone away at...' regardless of auto reconnect parameters.
  $self->hook(around_dispatch => sub {
    my ($next, $c) = @_;
    Hetula::Schema->keepaliveConnection();
    $next->();
  });

  #DB connection has been cached for the server process, and the same cache is copied for the forked workers.
  #Prevent sharing the same connection and instead let workers get their own DB connections.
  #When testing, we use a in-memory DB accessible only by the DB connection created by Hetula::Schema::DefaultDB::createDB();
  #We cannot lose this connection or we lose the test DB.
  Hetula::Schema::flushConnections() unless ($mode eq 'testing');
}

=head2 checkTimezone

Sets $ENV{TZ} for DateTime to properly do timezone calculations

=cut

sub checkTimezone {
  my ($self) = @_;

  my $env = $ENV{TZ};
  unless($env) {
    my $tz = `date +%z`;
    unless ($tz) {
      Hetula::Exception::TimeZone->throw(error => "checkTimezone():> Couldn't infer the correct timezone from \$ENV{TZ} or `date +%z`. You must set your system timezone");
    }
    $ENV{TZ} = $tz;
  }
}

=head2 getLog4perlConfig

=cut

sub getLog4perlConfig {
  my ($self) = @_;
  return $self->_getConfig('log4perl.conf');
}

=head2 getConfig

=cut

sub getConfig {
  my ($self) = @_;
  my $config = $self->plugin(Config => {file => $self->_getConfig('hetula.conf')});
  return validateConfig($self, $config);
}

=head2 validateConfig

Check that configuration options are properly given

=cut

sub validateConfig {
  my ($self, $config) = (@_);

  my $prologue = "Configuration parameter ";
  my @mandatoryConfig = (qw(session_expiration secret));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
  }
  return $config;
}

=head3 _getConfig

Does it's best to find the correct configuration file from different operational modes
'testing'|something_else

@returns String, path to the given config file from the current operational mode.

=cut

sub _getConfig {
  my ($self, $filename) = @_;
  if ($self->mode eq 'testing') {
    return "$FindBin::Bin/../t/config/$filename";
  }
  elsif (-e "/etc/hetula/$filename") {
    return "/etc/hetula/$filename";
  }
  else {
    return "$FindBin::Bin/../config/$filename";
  }
}

=head2 createPermissions

Finds all the paths in the Swagger2-spec and constructs the needed permissions from that.
Saves the new permissions to DB.

Permissions are api paths, where the basepath and '/''s have been stripped away.
With the HTTP verb prepended.
OPTIONS-requests don't need permissions.

eg.
my $permissions = [
  organizations-get,
  organizations-put,
  organizations-post,
  ...
];

=cut

sub createPermissions {
  my ($self) = @_;

  my %permissions;
  my $oldPermissions = [];
  try {
    $oldPermissions = Hetula::Permissions::listPermissions();
  } catch {
    return if (blessed($_) && $_->isa('Hetula::Exception::Permission::NotFound')); #There are no permissions so that is ok
    return Hetula::Exception::rethrowDefaults($_);
  };

  my $apiV1Route = $self->routes->find('apiv1');
  my $children = $apiV1Route->children;
  foreach my $childRoute (@$children) {
    my $perm = $self->getPermissionFromRoute($childRoute);
    $permissions{$perm} = 1 if $perm;
  }

  ## Intersect old permissions and current permissions
  ## What is left of the two data groups,
  ##    are permissions which are missing and needed,
  ##    or present and not needed.
  for (my $i=0 ; $i<scalar(@$oldPermissions) ; $i++) {
    my $oldPerm = $oldPermissions->[$i];
    if ($permissions{$oldPerm->name}) {
      #It exists, no problem
      $oldPermissions->[$i] = undef;
      delete $permissions{$oldPerm->name};
    }
  }
  ## These old permissions were not needed, so delete them
  foreach my $oldPerm (@$oldPermissions) {
    $oldPerm->delete if $oldPerm;
  }
  ## These new permissions are not present, so add them and grant them to the admin
  my $user = Hetula::Users::getUser({username => 'admin'});
  while(my ($k,$v) = each(%permissions)) {
    my $permission = Hetula::Permissions::createPermission({name => $k});
    $user->grantPermission($permission);
  }
}

=head2 getPermissionFromRoute

Use this to authorize user.

@PARAM1 Mojo::Route
@RETURNS String, the permission name

=cut

sub getPermissionFromRoute {
  my ($self, $route) = @_;

  my $verb = $route->via;
  my $routeString = $route->to_string;
  die "getPermissionFromRoute():> Route '$routeString' has multiple HTTP methods '@$verb' it is allowed to handle. I am not prepared to handle multiple methods!" if scalar(@$verb) > 1;
  $verb = $verb->[0];
  return $self->getPermissionFromRouteString($verb, $routeString);
}

=head2 getPermissionFromRouteString

@PARAM1 String, the HTTP verb
@PARAM2 String, the route path, eg. /api/v1/organizations
@RETURNS String, the permission name

=cut

sub getPermissionFromRouteString {
  my ($self, $verb, $routeString) = @_;
  $verb = lc($verb);
  return undef if $verb eq 'options';
  $routeString =~ s!^/api/v[^/]+/?!!;  #Remove api base path
  $routeString =~ s!/!-!g;             #Substitute / with -
  $routeString =~ s!\(.*\)!!;          #Remove placeholders
  $routeString =~ s!-$!!;              #Remove trailing -
  return undef unless $routeString;
  return "$routeString-$verb";
}

1;

use 5.22.0;

package PatronStore;

use Mojo::Base 'Mojolicious';

# ABSTRACT: A secure SSN-Store

=head1 NAME

PatronStore

=cut

use Mojo::IOLoop;

use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Schema;
use PatronStore::Schema::DefaultDB;
use PatronStore::Permissions;
use PatronStore::Users;

use PS::Exception::TimeZone;

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

  my $config;
  if ($mode eq 'testing') {
    $config = $self->plugin(Config => {file => 't/config/PatronStore.conf'});
  }
  elsif (-e '/etc/patronstore/PatronStore.conf') {
    $config = $self->plugin(Config => {file => '/etc/patronstore/PatronStore.conf'});
  }
  else {
    $config = $self->plugin(Config => {file => 'config/PatronStore.conf'});
  }
  checkConfig($self, $config);

  $self->sessions->cookie_name('PaStor');
  $self->sessions->default_expiration($config->{session_expiration});
  $self->secrets([$config->{secret}]);

  PatronStore::Schema::SetConfig($config);
  PatronStore::Schema::DefaultDB::createDB();

  $self->plugin("OpenAPI" => {
    url => $self->home->rel_file("public/api/v1/swagger/swagger.yaml"),
    #Set the root route for Swagger2 routes. Sets the namespace to look for Api::V1 automatically.
    route => $self->routes->under("/api/v1")->to(namespace => 'PatronStore::Controller::Api::V1', controller => 'Authenticate', action => 'under'),
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
    PatronStore::Logs::createLog($c) if ($path =~ m!^/api/v1! && $path !~ m!^/api/v1/doc!);
  });
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
      PS::Exception::TimeZone->throw(error => "checkTimezone():> Couldn't infer the correct timezone from \$ENV{TZ} or `date +%z`. You must set your system timezone");
    }
    $ENV{TZ} = $tz;
  }
}

=head2 checkConfig

Check that configuration options are properly given

=cut

sub checkConfig {
  my ($self, $config) = (@_);

  my $prologue = "Configuration parameter ";
  my @mandatoryConfig = (qw(session_expiration secret));
  foreach my $mc (@mandatoryConfig) {
    die "$prologue '$mc' is not defined" unless ($config->{$mc});
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
  my @oldPermissions;
  try {
    @oldPermissions = PatronStore::Permissions::listPermissions();
  } catch {
    return if (blessed($_) && $_->isa('PS::Exception::Permission::NotFound')); #There are no permissions so that is ok
  };

  my $apiV1Route = $self->routes->find('apiv1');
  my $children = $apiV1Route->children;
  foreach my $childRoute (@$children) {
    my $perm = getPermissionFromRoute($childRoute);
    $permissions{$perm} = 1 if $perm;
  }

  ## Intersect old permissions and current permissions
  ## What is left of the two data groups,
  ##    are permissions which are missing and needed,
  ##    or present and not needed.
  for (my $i=0 ; $i<scalar(@oldPermissions) ; $i++) {
    my $oldPerm = $oldPermissions[$i];
    if ($permissions{$oldPerm->name}) {
      #It exists, no problem
      $oldPermissions[$i] = undef;
      delete $permissions{$oldPerm->name};
    }
  }
  ## These old permissions were not needed, so delete them
  foreach my $oldPerm (@oldPermissions) {
    $oldPerm->delete;
  }
  ## These new permissions are not present, so add them and grant them to the admin
  my $user = PatronStore::Users::getUser({username => 'admin'});
  while(my ($k,$v) = each(%permissions)) {
    my $permission = PatronStore::Permissions::createPermission({name => $k});
    $user->grantPermission($permission);
  }
}

=head2 getPermissionFromRoute

Use this to authorize user.

=cut

sub getPermissionFromRoute {
  my ($route) = @_;

  my $verb = $route->via;
  die "getPermissionFromRoute():> Route '".$route->to_string."' has multiple HTTP methods '@$verb' it is allowed to handle. I am not prepared to handle multiple methods!" if scalar(@$verb) > 1;
  $verb = lc($verb->[0]);
  return undef if $verb eq 'OPTIONS';
  my $path = $route->to_string;
  $path =~ s!^/api/v[^/]+/?!!;  #Remove api base path
  $path =~ s!/!-!g;             #Substitute / with -
  $path =~ s!\(.*\)!!;          #Remove placeholders
  $path =~ s!-$!!;              #Remove trailing -
  return undef unless $path;
  return "$path-$verb";
}

1;

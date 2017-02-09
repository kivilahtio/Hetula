use 5.22.0;

package PatronStore::Controller::Api::V1::Doc;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Doc

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

sub index {
  my ($c) = @_;

  my $path = $c->req->url->path->to_string;
  if ($path eq '/api/v1/doc') {
    $c->res->headers->location('/api/v1/doc/');
    return $c->render(status => 301, text => '');
  }

  return $c->reply->static("$path/index.html");
}

sub swagger_ui {
  my ($c) = @_;

  my $path = $c->stash->{path}; #Route placeholder
  return $c->reply->static($path);
}



1;

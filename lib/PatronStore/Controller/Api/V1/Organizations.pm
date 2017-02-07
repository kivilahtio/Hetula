use 5.22.0;

package PatronStore::Controller::Api::V1::Organizations;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

PatronStore::Api::V1::Organizations

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;

sub get {
  my ($c) = @_;

  return $c->render(status => 200, json => {lol => 'mice'});
}

sub post {
  my ($c) = @_;

  return $c->render(status => 200, json => {log => 'post'});
}



1;

package Hetula::Controller::Default;

use Hetula::Pragmas;

use Mojo::Base 'Mojolicious::Controller';

=head1 NAME

Hetula::Controller::Default

=cut

=head2 index

Render the main page

=cut

sub index {
  my $self = shift;
  $self->reply->static('help.txt');
}

1;

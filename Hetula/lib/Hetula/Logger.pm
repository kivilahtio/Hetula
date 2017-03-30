use 5.22.0;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";

package Hetula::Logger;

use Carp qw(longmess);
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Scalar::Util qw(blessed);

# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Hetula.

use Log::Log4perl;
our @ISA = qw(Log::Log4perl);
Log::Log4perl->wrapper_register(__PACKAGE__);

sub AUTOLOAD {
  my $l = shift;
  my $method = our $AUTOLOAD;
  $method =~ s/.*://;
  return $l->$method(@_) if $method eq 'DESTROY';
  unless (blessed($l)) {
    longmess "Hetula::Logger invoked with an unblessed reference??";
  }
  unless ($l->{_log}) {
    $l->{_log} = Log::Log4perl->get_logger();
  }
  return $l->{_log}->$method(@_);
}

sub DESTROY {}

=head2 flatten

    my $string = $logger->flatten(@_);

Given a bunch of $@%, the subroutine flattens those objects to a single human-readable string.

@PARAMS Anything, concatenates parameters to one flat string

=cut

sub flatten {
    my $self = shift;
    die __PACKAGE__."->flatten() invoked improperly. Invoke it with \$logger->flatten(\@params)" unless ((blessed($self) && $self->isa(__PACKAGE__)) || ($self eq __PACKAGE__));
    $Data::Dumper::Indent = 0;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Quotekeys = 0;
    $Data::Dumper::Maxdepth = 2;
    $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper(\@_);
}

1;

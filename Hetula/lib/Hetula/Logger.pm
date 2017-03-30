# Copyright (C) 2017 Koha-Suomi
#
# This file is part of Hetula.

package Hetula::Logger;

use Modern::Perl;
use Carp qw(longmess);
use Scalar::Util qw(blessed);

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

1;

package Hetula::Pragmas;

=head1 NAME

Hetula::Pragmas

=head2 SYNOPSIS

Shared pargmas and modules for all Hetula modules.

=cut

binmode( STDOUT, ":encoding(UTF-8)" ); #Afaik this sets the shared handles for all modules
binmode( STDIN,  ":encoding(UTF-8)" );

use Import::Into;

=head2 import

Imports the shared pragmas and modules into the calling module.

Parameters:

  'no-schema' => Avoid importing Hetula::Schema, this is useful when used by DBIx::Class Result Objects, which get confused otherwise.

=cut

sub import {
  my $target = caller;
  my %args = map {$_ => 1} @_;

  #Pragmas
  Modern::Perl->import::into($target, '2018');
  utf8->import::into($target); #This file and all Strings within are utf8-encoded
  Carp::Always->import::into($target);
  experimental->import::into($target, 'smartmatch', 'signatures');
  English->import::into($target);
  Try::Tiny->import::into($target);

  #External modules
  Data::Dumper->import::into($target);
  Scalar::Util->import::into($target, 'blessed', 'weaken');
  Log::Log4perl->import::into($target);
  FindBin->import::into($target);

  #Local modules
  Hetula::Schema->import::into($target) unless $args{'no-schema'};
  Hetula::Config->import::into($target);
  Hetula::Logger->import::into($target);
}

1;

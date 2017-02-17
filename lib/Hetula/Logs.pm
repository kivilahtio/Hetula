use 5.22.0;

package Hetula::Logs;

=head1 NAME

Hetula::Logs

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;
use DateTime::Format::ISO8601;

use Hetula::Schema;

use PS::Exception::Log::NotFound;

=head2 getLog

@RETURNS Hetula::Schema::Result::Log
@THROWS PS::Exception::Log::NotFound

=cut

sub getLog {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Log');
  my $o = $rs->find($args->{id});
  PS::Exception::Organization::NotFound->throw(error => 'No log found with params "'.Data::Dumper::Dumper($args).'"') unless $o;
  return $o;
}

=head2 searchLogs

@RETURNS ARRAY of Hetula::Schema::Result::Log
@THROWS PS::Exception::Log::NotFound

=cut

sub searchLogs {
  my ($args) = @_;
  my $schema = Hetula::Schema::schema();
  my $rs = $schema->resultset('Log');
  my $dtf = $schema->storage->datetime_parser;
  my $argsx = {};
  #See. http://search.cpan.org/~ribasushi/DBIx-Class-0.082840/lib/DBIx/Class/Manual/Cookbook.pod#Formatting_DateTime_objects_in_queries
  $argsx->{updatetime}->{'>='} = $dtf->format_datetime(
                                      DateTime::Format::ISO8601->parse_datetime($args->{since}))
                                          if $args->{since};
  $argsx->{updatetime}->{'<='} = $dtf->format_datetime(
                                      DateTime::Format::ISO8601->parse_datetime($args->{until}))
                                          if $args->{until};
  $argsx->{userid}         = $args->{userid} if $args->{userid};
  $argsx->{organizationid} = $args->{organizationid} if $args->{organizationid};

  my @l = $rs->search($argsx)->all;
  PS::Exception::Log::NotFound->throw(error => 'No log found with params "'.Data::Dumper::Dumper($args).'"') unless scalar(@l);
  return \@l;
}

=head2 logTransaction

Creates a Log entry from a Mojolicious Controller
regarding the transaction that happened.

@PARAM1 Mojo::Controller
@RETURNS Mojo::Controller

=cut

sub createLog {
  my ($c) = @_;
  my $l = Hetula::Schema::schema()->resultset('Log')->create({
    userid         => $c->session->{userid} || ($c->stash->{logginginuser} ? $c->stash->{logginginuser}->id : undef),
    request        => $c->stash->{status}.' '.$c->req->method.' '.$c->req->url,
    description    => substr($c->res->text, 0, 50) || '',
    ip             => $c->tx->original_remote_address,
    organizationid => $c->session->{organizationid} || ($c->stash->{organization} ? $c->stash->{organization}->id : undef),
  });
  return $c;
}

1;

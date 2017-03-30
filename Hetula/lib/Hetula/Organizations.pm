use 5.22.0;

package Hetula::Organizations;

=head1 NAME

Hetula::Organizations

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace

use Hetula::Schema;

use Hetula::Exception::Organization::NotFound;


use Hetula::Logger;
my $l = bless({}, 'Hetula::Logger');

=head2 listOrganizations

@RETURNS ARRAYRef of Hetula::Schema::Result::Organization-objects
@THROWS Hetula::Exception::Organization::NotFound

=cut

sub listOrganizations {
  my $rs = Hetula::Schema::schema()->resultset('Organization');
  my @orgs = $rs->search()->all();
  Hetula::Exception::Organization::NotFound->throw(error => 'No organizations found') unless @orgs;
  return \@orgs;
}

=head2 getOrganization

@RETURNS Hetula::Schema::Result::Organization
@THROWS Hetula::Exception::Organization::NotFound

=cut

sub getOrganization {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Organization');
  my $o = $rs->find($args);
  Hetula::Exception::Organization::NotFound->throw(error => 'No organization found with params "'.$l->flatten($args).'"') unless $o;
  return $o;
}

=head2 createOrganization

Creates and returns a Organization

=cut

sub createOrganization {
  my ($organization) = @_;

  my $rs = Hetula::Schema::schema()->resultset('Organization');
  return $rs->create($organization);
}

=head2 deleteOrganization

Deletes an org

=cut

sub deleteOrganization {
  my ($args) = @_;
  getOrganization($args)->delete;
}

1;

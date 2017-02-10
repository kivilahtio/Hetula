use 5.22.0;

package PatronStore::Organizations;

=head1 NAME

PatronStore::Organizations

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;

use PatronStore::Schema;

use PS::Exception::Organization::NotFound;

=head2 getOrganization

@RETURNS PatronStore::Schema::Result::Organization
@THROWS PS::Exception::Organization::NotFound

=cut

sub getOrganization {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('Organization');
  my $o = $rs->find($args);
  PS::Exception::Organization::NotFound->throw(error => 'No organization found with params "'.Data::Dumper::Dumper($args).'"') unless $o;
  return $o;
}

=head2 createOrganization

Creates and returns a Organization

=cut

sub createOrganization {
  my ($organization) = @_;

  my $rs = PatronStore::Schema::schema()->resultset('Organization');
  return $rs->create($organization);
}

=head2 deleteOrganizaton

Deletes an org

=cut

sub deleteOrganizaton {
  my ($args) = @_;
  getOrganization($args)->delete;
}

1;

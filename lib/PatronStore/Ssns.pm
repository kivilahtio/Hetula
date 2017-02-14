use 5.22.0;

package PatronStore::Ssns;

=head1 NAME

PatronStore::Ssns

=head2 SYNOPSIS

Manage this class of objects

=cut

use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Data::Dumper;
use Digest::SHA;
use Try::Tiny;
use Scalar::Util qw(blessed);

use PatronStore::Schema;

use PS::Exception;
use PS::Exception::Ssn::NotFound;

=head2 listSsns

@RETURNS ARRAYRef of PatronStore::Schema::Result::Ssn-objects
@THROWS PS::Exception::Ssn::NotFound

=cut

sub listSsns {
  my $rs = PatronStore::Schema::schema()->resultset('Ssn');
  my @ssns = $rs->search()->all();
  PS::Exception::Ssn::NotFound->throw(error => 'No ssns found') unless @ssns;
  return \@ssns;
}

=head2 getSsn

@RETURNS PatronStore::Schema::Result::Ssn
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getSsn {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->find($args);
  PS::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getFullSsn

@RETURNS PatronStore::Schema::Result::Ssn, with Organizations and Permissions prefetched
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getFullSsn {
  my ($args) = @_;
  my $rs = PatronStore::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->find({id => $args->{id}}, {prefetch => {ssn_organization => 'organization'}});
  return $ssn;
}

=head2 createSsn

Adds a new organization which uses this ssn to an existing ssn,
or creates a new one and adds the organization from where it was created.

@PARAM1 HASHRef of Ssn-objects keys
@PARAM2 PatronStore::Schema::Result::Organization
@RETURNS ($ssn, $newSsnCreated)
          $ssn PatronStore::Schema::Result::Ssn
          $newSsnCreated, Boolean, true if new ssn created instead of appending
                                   organizations to an existing one

=cut

sub createSsn {
  my ($ssn, $organization) = @_;
  my ($organizations) = ($ssn->{organizations});
  delete $ssn->{organizations}; #We ignore the organizations here.

  my $newSsnCreated;
  try {
    $ssn = getSsn({ssn => $ssn->{ssn}});
    $ssn->add_to_organizations($organization);
    $newSsnCreated = 0;
  } catch {

    if (blessed($_) && $_->isa('PS::Exception::Ssn::NotFound')) {
      $ssn = _createNewSsn($ssn);
      $ssn->add_to_organizations({name => $organization});
      $newSsnCreated = 1;
      return if $ssn;
    }

    PS::Exception::rethrowDefaults($_);
  };

  return ($newSsnCreated, $ssn);
}

=head2 _createNewSsn

=cut

sub _createNewSsn {
  my ($ssn) = @_;
  return PatronStore::Schema::schema()->resultset('Ssn')->create($ssn);
}

=head2 modSsn

Updates and returns a Ssn

=cut

sub modSsn {
  my ($ssn) = @_;
  my ($organizations) = ($ssn->{organizations});
  delete $ssn->{organizations};

  my $oldSsn = getSsn({id => $ssn->{id}});
  $oldSsn->update($ssn);

  if ($organizations) {
    $oldSsn->setOrganizations($organizations);
  }

  return $oldSsn;
}

=head2 deleteSsn

Deletes a organizations reference to a ssn or the ssn if
no more references exists for it.

@PARAM1 HASHRef of Ssn-objects keys
@PARAM2 PatronStore::Schema::Result::Organization
@RETURNS ($ssn, $ssnDeleted)
          $ssn PatronStore::Schema::Result::Ssn
          $ssnDeleted, Boolean, true if ssn deleted instead just of removing
                                   organizations from an existing one

=cut

sub deleteSsn {
  my ($args, $organization) = @_;
  my $ssnDeleted;

  my $ssn = getSsn({id => $args->{id}});
  $ssn->removeOrganization($organization);
  unless ($ssn->countOrganizations) {
    $ssn->delete;
    $ssnDeleted = 1;
  }

  return ($ssnDeleted);
}

=head2 _hashPassword

@PARAM1 HASHRef of ssn attributes.

=cut

sub _hashPassword {
  my ($ssn) = @_;
  $ssn->{password} = Digest::SHA::sha256($ssn->{password});
}

1;

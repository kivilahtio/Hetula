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
use PS::Exception::Ssn::AlreadyExists;

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

@PARAM1 HASHRef of ssn-keys
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

=head2 getSsnForOrganization

@PARAM1 HASHRef of ssn-keys
@PAARM2 PatronStore::Schema::Result::Organization
@RETURNS PatronStore::Schema::Result::Ssn
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getSsnForOrganization {
  my ($args, $organization) = @_;
  $args = {
    'me.id' => $args->{id},
    'ssn_organizations.organizationid' => $organization->id,
  };
  my $rs = PatronStore::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->search($args, {join => 'ssn_organizations'})->single();
  PS::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getFullSsn

@RETURNS PatronStore::Schema::Result::Ssn, with Organizations and Permissions prefetched
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getFullSsn {
  my ($args, $organization) = @_;
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

    if ($_->isa('PS::Exception::Ssn::NotFound')) {
      $ssn = PatronStore::Schema::schema()->resultset('Ssn')->create($ssn);
      $ssn->add_to_organizations($organization);
      $newSsnCreated = 1;
      return if $ssn;
    }

    #Catch trying to re-add a organization dependency to an existing ssn
    PS::Exception::Ssn::AlreadyExists->throw(ssn => $ssn, error => 'Ssn already exists for this given organization') if $_->isa('DBIx::Class::Exception') && $_->{msg} =~ /UNIQUE constraint failed/;
    PS::Exception::rethrowDefaults($_);
  };

  return ($newSsnCreated, $ssn);
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

  my $ssn = getSsn({id => $args->{id}}, $organization);
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

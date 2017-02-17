use 5.22.0;

package Hetula::Ssns;

=head1 NAME

Hetula::Ssns

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

use Hetula::Schema;

use PS::Exception;
use PS::Exception::Ssn::NotFound;
use PS::Exception::Ssn::AlreadyExists;
use PS::Exception::Ssn::Invalid;

=head2 listSsns

@RETURNS ARRAYRef of Hetula::Schema::Result::Ssn-objects
@THROWS PS::Exception::Ssn::NotFound

=cut

sub listSsns {
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my @ssns = $rs->search()->all();
  PS::Exception::Ssn::NotFound->throw(error => 'No ssns found') unless @ssns;
  return \@ssns;
}

=head2 getSsn

@PARAM1 HASHRef of ssn-keys
@RETURNS Hetula::Schema::Result::Ssn
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getSsn {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->find($args);
  PS::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getSsnForOrganization

@PARAM1 HASHRef of ssn-keys
@PAARM2 Hetula::Schema::Result::Organization
@RETURNS Hetula::Schema::Result::Ssn
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getSsnForOrganization {
  my ($args, $organization) = @_;
  $args = {
    'me.id' => $args->{id},
    'ssn_organizations.organizationid' => $organization->id,
  };
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->search($args, {join => 'ssn_organizations'})->single();
  PS::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getFullSsn

@RETURNS Hetula::Schema::Result::Ssn, with Organizations and Permissions prefetched
@THROWS PS::Exception::Ssn::NotFound

=cut

sub getFullSsn {
  my ($args, $organization) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->find({id => $args->{id}}, {prefetch => {ssn_organization => 'organization'}});
  return $ssn;
}

=head2 batchCreateSsns

=cut

sub batchCreateSsns {
  my ($batch, $organization) = @_;

  for (my $i=0 ; $i<scalar(@$batch) ; $i++) {
    my $newSsn = $batch->[$i];
    try {
      $batch->[$i] = {};
      my ($newSsnCreated, $ssn) = createSsn({ssn => $newSsn}, $organization);
      $batch->[$i]->{ssn} = $ssn;
      $batch->[$i]->{status} = ($newSsnCreated ? 201 : 200);
    } catch {
      if ($_->isa('PS::Exception::Ssn::AlreadyExists')) {
        $batch->[$i]->{ssn} = $_->ssn;
        $batch->[$i]->{status} = 409;
        $batch->[$i]->{error} = $_->toText;
      }
      elsif ($_->isa('PS::Exception::Ssn::Invalid')) {
        $batch->[$i]->{ssn} = $_->ssn;
        $batch->[$i]->{status} = 400;
        $batch->[$i]->{error} = $_->toText;
      }
      else {
        $batch->[$i]->{ssn} = {ssn => $newSsn};
        $batch->[$i]->{status} = 500;
        $batch->[$i]->{error} = "$_";
      }
    };
  }
  return $batch;
}

=head2 createSsn

Adds a new organization which uses this ssn to an existing ssn,
or creates a new one and adds the organization from where it was created.

@PARAM1 HASHRef of Ssn-objects keys
@PARAM2 Hetula::Schema::Result::Organization
@RETURNS ($ssn, $newSsnCreated)
          $ssn Hetula::Schema::Result::Ssn
          $newSsnCreated, Boolean, true if new ssn created instead of appending
                                   organizations to an existing one

=cut

sub createSsn {
  my ($ssn, $organization) = @_;
  my ($organizations) = ($ssn->{organizations});
  delete $ssn->{organizations}; #We ignore the organizations here.
  $organization = Hetula::Organizations::getOrganization({name => $organization}) unless blessed($organization);

  my $newSsnCreated;
  try {
    validateSsn($ssn->{ssn});
    $ssn = getSsn({ssn => $ssn->{ssn}});
    $ssn->add_to_organizations($organization);
    $newSsnCreated = 0;
  } catch {

    if ($_->isa('PS::Exception::Ssn::NotFound')) {
      $ssn = Hetula::Schema::schema()->resultset('Ssn')->create($ssn);
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
@PARAM2 Hetula::Schema::Result::Organization
@RETURNS ($ssn, $ssnDeleted)
          $ssn Hetula::Schema::Result::Ssn
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

=head2 validateSsn

@FROM Parts taken from https://gist.github.com/puumuki/11172310

=cut

my @ssnValidCheckKeys = (0..9,'A'..'Y');
my %ssnCenturySeparators = (18 => '+', 19 => '-', 20 => 'A');
my $ssnParserRegexp = qr/^(\d\d)(\d\d)(\d\d)(\d\d)(.)(\d\d\d)(.)$/;

sub validateSsn {
  my ($ssnString) = @_;

  if ($ssnString =~ $ssnParserRegexp) {
    #$1 Day
    #$2 Month
    #$3 Century
    #$4 Decade + year
    #$5 Century separator
    #$6 order number
    #$7 check number
    unless ($1 <= 31 && $1 > 0) {
      PS::Exception::Ssn::Invalid->throw(error => "Bad day '$1'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($2 <= 12 && $2 > 0) {
      PS::Exception::Ssn::Invalid->throw(error => "Bad month '$2'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($ssnCenturySeparators{$3}) {
      PS::Exception::Ssn::Invalid->throw(error => "Unknown century '$3'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($5 eq $ssnCenturySeparators{$3}) {
      PS::Exception::Ssn::Invalid->throw(error => "Given century separator '$5' doesn't match the expected '$ssnCenturySeparators{$3}'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    my $checkChar = _getSsnChecksum($1, $2, $3, $4, $6);
    unless ($7 eq $checkChar) {
      PS::Exception::Ssn::Invalid->throw(error => "Given check character '$7' doesn't match the expected '$checkChar'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
  }
  else {
    PS::Exception::Ssn::Invalid->throw(error => "Ssn '$ssnString' is invalid", ssn => {ssn => $ssnString});
  }
}

=head2 _getSsnChecksum

=cut

sub _getSsnChecksum {
  my ($day, $month, $century, $year, $checkNumber) = @_;

  my $checkNumberSum = sprintf("%02d%02d%2d%2d%03d", $day, $month, $century, $year, $checkNumber);
  my $checkNumberIndex = $checkNumberSum % 31;
  return $ssnValidCheckKeys[$checkNumberIndex];
}

=head2 createRandomSsn

=cut

sub createRandomSsn {
  my $s = [int(1+rand(28)), int(1+rand(12)), int(18+rand(3)), int(1+rand(99)), undef, int(2+rand(889)), undef];
  $s = sprintf("%02d%02d%02d%02d%s%03d%s", $s->[0], $s->[1], $s->[2], $s->[3], $ssnCenturySeparators{$s->[2]}, $s->[5], _getSsnChecksum($s->[0], $s->[1], $s->[2], $s->[3], $s->[5]));
  return $s;
}

1;

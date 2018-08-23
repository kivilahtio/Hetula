package Hetula::Ssns;

=head1 NAME

Hetula::Ssns

=head2 SYNOPSIS

Manage this class of objects

=cut

use Hetula::Pragmas;

use Digest::SHA;

use Hetula::Exception;
use Hetula::Exception::Ssn::NotFound;
use Hetula::Exception::Ssn::AlreadyExists;
use Hetula::Exception::Ssn::Invalid;

=head2 listSsns

@RETURNS ARRAYRef of Hetula::Schema::Result::Ssn-objects
@THROWS Hetula::Exception::Ssn::NotFound

=cut

sub listSsns {
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my @ssns = $rs->search()->all();
  Hetula::Exception::Ssn::NotFound->throw(error => 'No ssns found') unless @ssns;
  return \@ssns;
}

=head2 getSsn

@PARAM1 HASHRef of ssn-keys
@RETURNS Hetula::Schema::Result::Ssn
@THROWS Hetula::Exception::Ssn::NotFound

=cut

sub getSsn {
  my ($args) = @_;
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->find($args);
  Hetula::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getSsnForOrganization

@PARAM1 HASHRef of ssn-keys
@PAARM2 Hetula::Schema::Result::Organization
@RETURNS Hetula::Schema::Result::Ssn
@THROWS Hetula::Exception::Ssn::NotFound

=cut

sub getSsnForOrganization {
  my ($args, $organization) = @_;
  $args = {
    'me.id' => $args->{id},
    'ssn_organizations.organizationid' => $organization->id,
  };
  my $rs = Hetula::Schema::schema()->resultset('Ssn');
  my $ssn = $rs->search($args, {join => 'ssn_organizations'})->single();
  Hetula::Exception::Ssn::NotFound->throw(error => 'No ssn found with params "'.Data::Dumper::Dumper($args).'"') unless $ssn;
  return $ssn;
}

=head2 getFullSsn

@RETURNS Hetula::Schema::Result::Ssn, with Organizations and Permissions prefetched
@THROWS Hetula::Exception::Ssn::NotFound

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
      if ($_->isa('Hetula::Exception::Ssn::AlreadyExists')) {
        $batch->[$i]->{ssn} = $_->ssn;
        $batch->[$i]->{status} = 409;
        $batch->[$i]->{error} = $_->toText;
      }
      elsif ($_->isa('Hetula::Exception::Ssn::Invalid')) {
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

    if ($_->isa('Hetula::Exception::Ssn::NotFound')) {
      $ssn = Hetula::Schema::schema()->resultset('Ssn')->create($ssn);
      $ssn->add_to_organizations($organization);
      $newSsnCreated = 1;
      return if $ssn;
    }

    #Catch trying to re-add a organization dependency to an existing ssn
    Hetula::Exception::Ssn::AlreadyExists->throw(ssn => $ssn, error => 'Ssn already exists for this given organization') if $_->isa('DBIx::Class::Exception') && $_->{msg} =~ /UNIQUE constraint failed/;
    Hetula::Exception::rethrowDefaults($_);
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
my %ssnCenturySeparators = ('+' => 18, '-' => 19, 'A' => 20);
my @ssnCenturySeparatorsKeys = keys(%ssnCenturySeparators);
my $ssnParserRegexp = qr/^(\d\d)(\d\d)(\d\d)(.)(\d\d\d)(.)$/;
my $isDigitRegexp = qr/^\d+$/;

sub validateSsn {
  my ($ssnString) = @_;

  if (my @g = $ssnString =~ $ssnParserRegexp) {
    #$g[0] Day
    #$g[1] Month
    #$g[2] Decade + year
    #$g[3] Century separator
    #$g[4] order number
    #$g[5] check number
    unless ($g[0] =~ $isDigitRegexp && $g[0] <= 31 && $g[0] > 0) {
      Hetula::Exception::Ssn::Invalid->throw(error => "Bad day '$g[0]'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($g[1] =~ $isDigitRegexp && $g[1] <= 12 && $g[1] > 0) {
      Hetula::Exception::Ssn::Invalid->throw(error => "Bad month '$g[1]'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($g[2] =~ $isDigitRegexp) {
      Hetula::Exception::Ssn::Invalid->throw(error => "Bad month '$g[1]'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    unless ($ssnCenturySeparators{$g[3]}) {
      Hetula::Exception::Ssn::Invalid->throw(error => "Unknown century separator '$g[3]'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
    my $checkChar = _getSsnChecksum($g[0], $g[1], $g[2], $g[4]);
    unless ($g[5] eq $checkChar) {
      Hetula::Exception::Ssn::Invalid->throw(error => "Given check character '$g[5]' doesn't match the expected '$checkChar'. When parsing ssn '$ssnString'", ssn => {ssn => $ssnString});
    }
  }
  else {
    Hetula::Exception::Ssn::Invalid->throw(error => "Ssn '$ssnString' is invalid", ssn => {ssn => $ssnString});
  }
}

=head2 _getSsnChecksum

=cut

sub _getSsnChecksum {
  my ($day, $month, $year, $checkNumber) = @_;

  my $checkNumberSum = sprintf("%02d%02d%2d%03d", $day, $month, $year, $checkNumber);
  my $checkNumberIndex = $checkNumberSum % 31;
  return $ssnValidCheckKeys[$checkNumberIndex];
}

=head2 createRandomSsn

=cut

sub createRandomSsn {
  my $s = [int(1+rand(28)), int(1+rand(12)), int(1+rand(99)), undef, int(2+rand(889)), undef];
  my $centurySeparator = $ssnCenturySeparatorsKeys[ int((rand(scalar(@ssnCenturySeparatorsKeys)*100)+0.01)/100) ];
  $s = sprintf("%02d%02d%02d%s%03d%s", $s->[0], $s->[1], $s->[2], $centurySeparator, $s->[4], _getSsnChecksum($s->[0], $s->[1], $s->[2], $s->[4]));
  return $s;
}

1;

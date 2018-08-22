#!/usr/bin/env perl
use 5.22.0;
use utf8;
binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";
use FindBin;
use lib "$FindBin::Bin/../lib";

use English;
use Carp;
use autodie;
$Carp::Verbose = 'true'; #die with stack trace
use Try::Tiny;
use Scalar::Util qw(blessed);

use Test::More;

use File::Find;


ok(1, "Find all .pl and .pm -files and check if they actually compile");

#Find files in the usual places
my $searchDir = "$FindBin::Bin/../lib/";
File::Find::find( \&testFile, $searchDir );

#Test odd assortment of other files
testFile("$FindBin::Bin/../ks-test-harness.pl");

sub testFile {
  my ($filename) = @_;
  $filename = $File::Find::name unless $filename;

  return unless $filename =~ m/\.p[ml]$/;

  `perl -I$searchDir  $filename`;
  my $exitCode = ${^CHILD_ERROR_NATIVE} >> 8;
  ok(not($exitCode), "$filename");

=head deprecated - for some reason fails miserably, maybe circular dependencies?
  print "$filename\n";
  if ($filename =~ s/\.pm$//) {
    $filename =~ s/\Q$searchDir\E//;
    $filename =~ s{/}{::}g;
    use_ok($filename); #Actually a module name now
  }
  else {
    require_ok($filename);
  }
=cut
}

done_testing();


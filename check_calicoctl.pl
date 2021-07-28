#!/usr/bin/perl -w

# This plugin parse output of calicoctl and alerts if any peers has other state than "up".
# Author: Ole Fredrik Skudsvik <ole.skudsvik@gmail.com>

# nagios: -epn

use strict;
use Getopt::Std;

my $calicoctl_bin = "/usr/local/bin/calicoctl.sh";
my $useSudo = 0;

sub printUsage {
  printf("Usage:\n" .
  "%s -c <path to calicoctl> [-s] ...\n\n" .
  "Flags:\n" .
  "-c\t<path to calicoctl>\tPath to calicoctl binary.\n" .
  "-s\tUse sudo.\n", $0);
  exit(0);
}

my %opts;
getopts('c:sh', \%opts);
printUsage()                  if (defined($opts{'h'}));
$calicoctl_bin = $opts{'c'}   if (defined($opts{'c'}));
$useSudo = 1                  if (defined($opts{'s'}));

if ($useSudo) {
  $calicoctl_bin = sprintf("sudo %s", $calicoctl_bin);
}

open(FH, $calicoctl_bin . " node status|") or die("Failed to run " . $calicoctl_bin);

my %failedPeers;
my $numPeers = 0;
my $calicoIsRunning = 0;

while(<FH>) {
  $calicoIsRunning = 1 if (m/process\sis\srunning/);

  my ($peer, $type, $state, $since, $info) = m/(\d+\.\d+\.\d+\.\d+)[|\s]+([a-z\-\s]+[a-z])[|\s]+([a-z\-\s]+[a-z])[|\s]+([0-9\-\s]+[0-9])[|\s]+([a-zA-Z\-\s]+[a-z])/;
  next if !defined($peer) || !defined($state) || !defined($info);

  if ($state ne "up") {
    $failedPeers{$peer} = {
      peer => $peer,
      type => $type,
      state => $state,
      since => $since,
      info => $info
    };
  }

  $numPeers++;
}

close(FH);

if (!$calicoIsRunning) {
  printf("CRITICAL: calicoctl did not report that Calico is running.\n");
  exit(2);
}

if (!$numPeers) {
  printf("CRITICAL: calicoctl returned 0 peers.\n");
  exit(2);
}

my $numFailedPeers = scalar keys %failedPeers;

if ($numFailedPeers > 0) {
  my @errors;

  foreach my $peer (keys %failedPeers) {
    push @errors, sprintf("%s (%s)", $peer, $failedPeers{$peer}->{"info"});
  }

  printf("CRITICAL: %d failed Calico peers detected: %s\n", $numFailedPeers, join(", ", @errors));
  exit(2);
}

printf("OK: All (%d) Calico peers is up.\n", $numPeers);
exit(0);
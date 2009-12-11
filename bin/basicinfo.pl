#!/usr/bin/perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/../src";

use Bongo::Canopy::BasicInfo;

use Data::Dumper;

if (@ARGV == 2) {
  my $host = $ARGV[0];
  my $cstr = $ARGV[1];

  my $infoq = Bongo::Canopy::BasicInfo->new(host => $host, community => $cstr);

  $infoq->poll();

  if ($infoq->name) {
    print "Name: " . $infoq->name . "\n";
    print "Type: " . $infoq->type . "\n";
    print "SW: " . $infoq->swversion . "\n";
  } else {
    print "Could not poll $host with community $cstr\n";
  }

} else {
  print "Usage: basicinfo.pl hostname SNMP_community\n";
  exit 1;
}


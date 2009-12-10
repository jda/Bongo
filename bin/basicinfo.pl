#!/usr/bin/env perl -w
use strict;

use FindBin;
use lib "$FindBin::Bin/../src";

use Bongo::Canopy::BasicInfo;

if (@ARGV == 2) {
  my $host = $ARGV[0];
  my $cstr = $ARGV[1];

  my $infoq = Bongo::Canopy::BasicInfo->new(timout => 5);

  $infoq->get(host => $host, community => $cstr);

} else {
  print "Usage: basicinfo.pl hostname SNMP_community\n";
  exit 1;
}


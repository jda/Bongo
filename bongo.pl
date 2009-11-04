#!/usr/bin/perl -w
# Bongo: Recording the beat of your Canopy jungle
#
# Copyright (C) 2008  Jon Auer <jda@tapodi.net>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;

use YAML;
use SNMP::Effective;
use RRD::Simple;
use NetAddr::IP;
use File::Path;
use Time::Duration;
use DBI;
use Data::Dumper;

my $polledHosts = 0; # Number of hosts that we have polled
my $startTime = time();

# Make sure config file was provided and load it
my $cfgFile;
if (defined $ARGV[0]) {
  $cfgFile = $ARGV[0];
} else {
  print "Usage: bongo.pl config.yaml\n";
  exit 1;
}
my $config = YAML::LoadFile($cfgFile);

my $verbose = "no";
if (exists($config->{verbose})) {
  $verbose = $config->{verbose};
}

# Canopy MIBs online: 
#  http://motorola.motowi4solutions.com/support/online_tools/mib/
my @CanopyOIDs = ('RFC1213-MIB::ifPhysAddress.2',
          'RFC1213-MIB::ifInOctets.2',
          'RFC1213-MIB::ifOutOctets.2',
          'RFC1213-MIB::ifInUcastPkts.2',
          'RFC1213-MIB::ifOutUcastPkts.2',
          'RFC1213-MIB::ifInNUcastPkts.2',
          'RFC1213-MIB::ifOutNUcastPkts.2',
          'RFC1213-MIB::ifInErrors.2',
          'RFC1213-MIB::ifOutErrors.2',
          'RFC1213-MIB::ifInDiscards.2',
          'RFC1213-MIB::ifOutDiscards.2',
          '1.3.6.1.4.1.161.19.3.2.2.2.0',
          '1.3.6.1.4.1.161.19.3.2.2.3.0',
          '1.3.6.1.4.1.161.19.3.2.2.21.0',
          '1.3.6.1.4.1.161.19.3.2.2.9.0',
          '1.3.6.1.4.1.161.19.3.2.1.19.0');

# generate int math compat timestamp for SQLite
sub timestamp {
  use POSIX qw(strftime);
  my $now = strftime "%Y%m%d%H%M%S", localtime;
  return $now;
}

# Run by SNMP::Effective as callback to process result for host
sub handleSNMP {
    my ($host, $error) = @_;

  if (!$error) {
    $polledHosts++;
    my %data = %{$host->data};
    my $rssi = $data{'1.3.6.1.4.1.161.19.3.2.2.2.0'}{'1'};
    my $jitter = $data{'1.3.6.1.4.1.161.19.3.2.2.3.0'}{'1'};
    my $dbm = $data{'1.3.6.1.4.1.161.19.3.2.2.21.0'}{'1'};
    my $mac = $data{'1.3.6.1.2.1.2.2.1.6.2'}{'2'};
    my $inOct = $data{'1.3.6.1.2.1.2.2.1.10.2'}{'2'}; 
    my $outOct = $data{'1.3.6.1.2.1.2.2.1.16.2'}{'2'};
    my $inUcast = $data{'1.3.6.1.2.1.2.2.1.11.2'}{'2'};
    my $outUcast = $data{'1.3.6.1.2.1.2.2.1.17.2'}{'2'};
    my $inNUcast = $data{'1.3.6.1.2.1.2.2.1.12.2'}{'2'};
    my $outNUcast = $data{'1.3.6.1.2.1.2.2.1.18.2'}{'2'};
    my $inError = $data{'1.3.6.1.2.1.2.2.1.14.2'}{'2'};
    my $outError = $data{'1.3.6.1.2.1.2.2.1.20.2'}{'2'};
    my $inDiscard = $data{'1.3.6.1.2.1.2.2.1.13.2'}{'2'};
    my $outDiscard = $data{'1.3.6.1.2.1.2.2.1.19.2'}{'2'};
    my $parentAP = $data{'1.3.6.1.4.1.161.19.3.2.2.9.0'}{'1'};
    my $isNAT = $data{'1.3.6.1.4.1.161.19.3.2.1.19.0'}{'1'};

    $parentAP =~ s/-//g;

    $mac = unpack("H12", $mac); # Change from octet string to normal MAC format
    #$dbm = abs($dbm); # Make dbm positive number to ease processing

    if ($verbose eq "yes") {
      print "SM: $mac\n RSSI: $rssi\n Jitter: $jitter\n DBM: $dbm\n";
      print " On AP: $parentAP\n";
      print " Traffic: In: $inOct\tOut: $outOct\n";
      print " Unicast: In: $inUcast\tOut: $outUcast\n";
      print " [M/B]cast: In: $inNUcast\tOut: $outNUcast\n";
      print " Errors: In: $inError\tOut: $outError\n";
      print " Discards: In $inDiscard\tOut: $outDiscard\n";
      print "\n";
    }
    
    # Set up RRD path prefix
    my $rrddir = $config->{rrdpath} . "/" . substr($mac, 4, 2) . "/"
      . substr($mac, 6, 2) . "/" . substr($mac, 8, 2);
    my $rrdfile = $rrddir . "/$mac.rra";
    mkpath($rrddir);
    
    my $rrd = RRD::Simple->new(file=>$rrdfile);
    if (!-e $rrdfile) {
      print "RRA $rrdfile does not exist... Creating...\n";
      $rrd->create("mrtg",
        rssi => "GAUGE",
        jitter => "GAUGE",
        dbm => "GAUGE",
        inOct => "COUNTER",
        outOct => "COUNTER",
        inUcast => "COUNTER",
        outUcast => "COUNTER",
        inNUcast => "COUNTER",
        outNUcast => "COUNTER",
        inError => "COUNTER",
        outError => "COUNTER",
        inDiscard => "COUNTER",
        outDiscard => "COUNTER"
      );
    }
    
    # Record values
    $rrd->update(
      rssi => $rssi,
      jitter => $jitter,
      dbm => $dbm,
      inOct => $inOct,
      outOct => $outOct,
      inUcast => $inUcast,
      outUcast => $outUcast,
      inNUcast => $inNUcast,
      outNUcast => $outNUcast,
      inError => $inError,
      outError => $outError,
      inDiscard => $inDiscard,
      outDiscard => $outDiscard
    ) or warn "RRD update failed for $mac";
   
    # Log config settings to DB
    my $logtime = timestamp();
    $logtime =~ s/-//g;

    my $dbfile = $rrddir . "/$mac.sqlite";

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", "", "", 
      { RaiseError => 1, AutoCommit => 1});

    $dbh->do("CREATE TABLE IF NOT EXISTS history (timestamp integer, ap text, nat integer)");
    
    my $sth = $dbh->prepare("INSERT INTO history (timestamp, ap, nat) VALUES (?, ?, ?)");
    $sth->execute($logtime, $parentAP, $isNAT);
    
    $dbh->disconnect();
  }
}

# Build list of hosts to poll from ranges in config file
my %preHosts;
foreach my $apgroup (@{$config->{ranges}}) {
  my $cidr = new NetAddr::IP($apgroup->{cidr});
  
  foreach my $host (@{$cidr->hostenumref()}) {
    my @h = split(/\//, $host);
    my $ip = $h[0];
    $preHosts{$ip}++;
  }
}
my @snmpHosts = keys %preHosts;

# Setup and run SNMP poller
my $snmp = SNMP::Effective->new(
  max_sessions => $config->{pollsessions}, 
  master_timeout => $config->{maxruntime}
);

$snmp->add(
  dest_host => \@snmpHosts, 
  callback => \&handleSNMP, 
  get => \@CanopyOIDs,
  arg => {
    Community => $config->{community},
    Version => 2,
  }
);
$snmp->execute;

# Clean up and show stats
my $runtime = duration_exact(time()- $startTime);
print "Logged $polledHosts SMs in $runtime.\n";


#!/usr/bin/perl -w
# Bongo: Recording the beat of your Canopy jungle
#
# Copyright (C) 2008 Jonathan Auer <jda@tapodi.net>
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
use RRD::Simple;
use File::Find;
use File::Path;
use Net::MAC;
use Data::Dumper;

my $startTime = time();

# Make sure config file was provided and load it
my $cfgFile;
if (defined $ARGV[0]) {
  $cfgFile = $ARGV[0];
} else {
  print "Usage: drawgraphs.pl config.yaml\n";
  exit 1;
}
my $config = YAML::LoadFile($cfgFile);

my $verbose = "no";
if (exists($config->{verbose})) {
  $verbose = $config->{verbose};
}

sub drawGraph {
  if (-d $File::Find::name) {
    return;
  }
  
  if ($_ =~ m/\.rra$/) {
    my $rra = $File::Find::name;
    my $graphPrefix = $_;
    $graphPrefix =~ s/\.rra//;
  
    my $macOld = Net::MAC->new('mac' => $graphPrefix);
    my $mac = $macOld->convert(
      'bit_group' => 8,
      'delimiter' => ':'
      )->get_mac();
  
  
    my $graphPath = $config->{graphpath} . '/' . $graphPrefix;
    mkpath($graphPath);
  
    my $rrd = RRD::Simple->new(file=>$rra);
  
    # graph config options
    my @periods = qw(hour day week month);
    my $gwidth = 550;
  
    # Draw signal jitter graph
    my %jg = $rrd->graph($rra,
      destination => $graphPath,
      basename => "jitter",
      periods => [@periods],
      sources => [ qw(jitter) ],
      source_labels => [ qw(Jitter) ],
      source_drawtypes => [ qw(AREA) ],
      title => "Multipath Interference for $mac",
      extended_legend => "true",
      width => $gwidth,
    );

    # Draw dbm graph
    my %dbg = $rrd->graph($rra,
      destination => $graphPath,
      basename => "dbm",
      periods => [@periods],
      sources => [qw(dbm)],
      source_labels => [qw(dBm)],
      source_drawtypes => [ qw(AREA) ],
      title => "Signal quality for $mac",
      extended_legend => "true",
      width => $gwidth,
    );
  
    # Draw RSSI graph - seperate because of scale issues vs. dbm/jit
    my %rg = $rrd->graph($rra,
      destination => $graphPath,
      basename => "strength",
      periods => [@periods],
      sources => [ qw(rssi) ],
      source_labels => [ ("RSSI") ],
      source_drawtypes => [ qw(AREA) ],
      title => "Recieved Signal Strength for $mac",
      extended_legend => "true",
      width => $gwidth,
    );
  
    # Draw network traffic graph
    my %ntg = $rrd->graph($rra,
      destination => $graphPath,
      basename => "net",
      periods => [@periods],
      sources => [ qw(inOct outOct inUcast outUcast inNUcast 
        outNUcast inError outError inDiscard outDiscard)],
      source_labels => [ ("Total in", "Total out", "Unicast in", 
        "Unicast out", "M/Bcast in", "M/Bcast out", 
        "Errors in", "Errors out", "Discards in", "Discards out") ],
      title => "Network traffic for $mac",
      extended_legend => "true",
      width => $gwidth,
    );
  }
}
  
find(\&drawGraph, $config->{rrdpath});

#my $rrd = RRD::Simple->new(file=>$rrdfile);
#if (!-e $rrdfile) {
#	print "RRA $rrdfile does not exist... Creating...\n";
#			$rrd->create("3years",
#				rssi => "GAUGE",
#				jitter => "GAUGE",
#				inOct => "COUNTER",
#				outOct => "COUNTER",
#				inUcast => "COUNTER",
#				outUcast => "COUNTER",
#				inNUcast => "COUNTER",
#				outNUcast => "COUNTER",
#				inError => "COUNTER",
#				outError => "COUNTER",
#				inDiscard => "COUNTER",
#				outDiscard => "COUNTER"
#			);


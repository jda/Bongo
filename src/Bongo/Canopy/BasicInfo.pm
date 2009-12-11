#!/usr/bin/perl -w
# SNMP query Canopy device for basic info
# (c) 2009 Jonathan Auer

use strict;

package Bongo::Canopy::BasicInfo;

use SNMP::Simple;
use Moose;

has 'host' => (is => 'rw', isa => 'Str', required => 1);
has 'community' => (is => 'rw', isa => 'Str', required => 1);
has 'name' => (is => 'ro', isa => 'Str', writer => '_set_name');
has 'swversion' => (is => 'ro', isa => 'Str', writer => '_set_swversion');
has 'type' => (is => 'ro', isa => 'Str', writer => '_set_type');

sub poll {
  my $self = shift;

  my $s = SNMP::Simple->new(
    DestHost  => $self->host,
    Community => $self->community,
    Version   => 2,
    Timeout   => 500000,
    Retries   => 3,
  ) or die "Couldn't create session\n";

  # sysName, sysVersion
  my $name;
  my $descr_raw;
  
  eval {
    $name = $s->get('.1.3.6.1.2.1.1.5.0');
    $descr_raw = $s->get('.1.3.6.1.2.1.1.1.0')
  };
  if ($@) {
    
  } else {
    $self->_set_name($name);
    
    my @descr = split(/ /, $descr_raw);
    $self->_set_swversion($descr[1]);
    
    my @type = split(/-/, $descr[2]);
    $self->_set_type($type[0]);
  }
 
 return 1;
}

1;

#!/usr/bin/perl -w
# SNMP query Canopy device for basic info
# (c) 2009 Jonathan Auer

use strict;

package Bongo::Canopy::BasicInfo;

#use SNMP::Simple;
use Mouse;

use Data::Dumper;

has 'timeout' => (is => 'rw', isa => 'Int');

sub get {
  my $self = shift;
  my %args = @_;

  print $args{community} . "\n";
  print $args{host} . "\n";

}

1;

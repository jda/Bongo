#!/usr/bin/perl -w
# SNMP query Canopy device for basic info
# (c) 2009 Jonathan Auer

use strict;

package Bongo::Canopy::BasicInfo;

use SNMP::Effective;
use Moose;



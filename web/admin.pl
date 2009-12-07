#!/usr/bin/perl -w
# Launcher for Bongo web admin
# (c) 2009 Jonathan Auer <jda@tapodi.net> , All rights reserved.

use strict;
use Bongo::Web::Admin;
my $webapp = Bongo::Web::Admin->new();
$webapp->run();

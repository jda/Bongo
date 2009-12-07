#!/usr/bin/perl -w
# Launcher for Bongo web admin
# (c) 2009 Jonathan Auer <jda@tapodi.net> , All rights reserved.

use strict;
use Bongo::Web::View;
my $webapp = Bongo::Web::View->new();
$webapp->run();

#!/usr/bin/perl -w
# Bongo Web Admin 
# (c) 2009 Jonathan Auer

use strict;

package Bongo::Web::Admin;
use base 'CGI::Application';

use Data::Dumper;

sub setup {
  my $self = shift;
  $self->start_mode('list');
  $self->error_mode('errMode');
  $self->run_modes(
    'list' => 'listAPs',
    'add' => 'addForm',
  );
}

sub listAPs {
  return Dumper(@INC); 
}

sub addAPform {

};

sub errMode {
  my ($self, $err) = @_;
  my $display = "Error encountered: $err'; stopped";
  return $display;
}

1;

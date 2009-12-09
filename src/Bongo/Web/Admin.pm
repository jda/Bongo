#!/usr/bin/perl -w
# Bongo Web Admin 
# (c) 2009 Jonathan Auer

use strict;

package Bongo::Web::Admin;
use base 'CGI::Application';

use CGI::Application::Plugin::AutoRunmode;
use CGI::Application::Plugin::ValidateRM;
use CGI::Application::Plugin::AnyTemplate;
use HTML::Template;

use Data::Dumper;


sub cgiapp_prerun {
  my $self = shift;
  
  # not sure if template path is relative to module or cgi runner dir
  my @tPaths = qw(../../../tmpl ../tmpl);
  
  $self->template->config(
    default_type => "HTMLTemplate",
    include_paths => \@tPaths,
  );
}

sub listAPs : StartRunmode {
  my $self = shift;

  my %params = (
    title => 'AP List',
  );
  $self->template->fill(\%params);
}

sub addAP : Runmode {
  my $self = shift;

  # display flags
  my $form = 1; # by default show form
  my $form_error = 1; # by default, form is in error

  my $q = $self->query();
  
  # if we don't have a isform value the form wasn't submitted so we 
  # don't show input error
  if (not $q->param("isform")) {
    $form_error = 0;
  } else {
    # we have a form. make sure all elements exist - no empty boxes.
    if (($q->param("address") ne "") && ($q->param("community") ne "" ) 
      && ($q->param("device_type") ne "")) {
      $form_error = 0;
    }
  }
  my %params = (
    title => 'Add AP',
    form => $form,
    form_error => $form_error,
    runmode =>  $self->get_current_runmode(),
  );
  $self->template->fill(\%params);
}

sub modAP : Runmode {
  my $self = shift;

  my %params = (
    title => 'Modify AP',
  );
  $self->template->fill(\%params);
}

sub delAP : Runmode {
  my $self = shift;

  my %params = (
    title => 'Remove AP',
  );
  $self->template->fill(\%params);
}

1;

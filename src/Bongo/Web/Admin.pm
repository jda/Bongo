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

use Bongo::Canopy::BasicInfo;

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

  my %params = (
    title      => 'Add AP',
    form       => 1, # by default, show form
    form_error => 1, # by default, form is in error
    error_msg  => "",
    runmode    => $self->get_current_runmode(),
    confirm    => 0,
  );

  my $q = $self->query();
  
  # if we don't have a isform value the form wasn't submitted so we 
  # don't show input error
  if (not $q->param("isform")) {
    $params{'form_error'} = 0;
  } else {
    # we have a form. make sure all elements exist - no empty boxes.
    if (($q->param("address") ne "") && ($q->param("community") ne "" ) 
      && ($q->param("device_type") ne "")) {
      $params{'form_error'} = 0;
      
      # check if params are valid by trying to contact AP
      my $infoq = Bongo::Canopy::BasicInfo->new(
        host      => $q->param("address"), 
        community => $q->param("community"),
      );
      $infoq->poll();

      # check if AP responded
      if ($infoq->name) {
        $params{'form'} = 0;
        $params{'confirm'} = 1; 
        $params{'runmode'} = 'doAddDevice';
        $params{'dev_name'} = $infoq->name;
        $params{'dev_community'} = $infoq->community;
        $params{'dev_address'} = $infoq->host;
        $params{'dev_version'} = $infoq->swversion;
        $params{'dev_type'} = $infoq->type;
      
      } else { # no AP... That's bad.
        $params{'form_error'} = 1;
        $params{'error_msg'} = "Could not contact "
          . $q->param("address")
          . " using community "
          . $q->param("community");
      }
    } else {
      $params{'error_msg'} = "One or more fields below were left blank.<br/>All fields are required";  
    }
  }
  $self->template->fill(\%params);
}

sub doAddDevice : Runmode {
  my $self = shift;
  my %params = (
    title => "Device Added",
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

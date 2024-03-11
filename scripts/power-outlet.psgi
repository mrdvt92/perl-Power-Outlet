#!/usr/bin/perl
use strict;
use warnings;
use Plack::Builder qw{builder enable};
use Plack::Request;
use Power::Outlet::Config;
use JSON::XS qw{encode_json};
require Plack::Middleware::Favicon_Simple;
require Plack::Middleware::Method_Allow;

my $app = sub {
  my $env     = shift;
  my $req     = Plack::Request->new($env);
  my $params  = $req->query_parameters; #isa Hash::MultiValue to isa HASH
  my $name    = $params->get('name');   #name of outlet
  my $action  = $params->get('action'); #action e.g., ON|OFF|QUERY|SWITCH
  my $output  = {};
  if (defined($name) and length($name) and defined($action) and length($action)) {
    local $@;
    my $state = eval{Power::Outlet::Config->new(section=>$name)->action($action)};
    my $error = $@;
    $output   = $error ? {code=>500, status=>'ERROR', error=>$error} : {code=>200, status=>'OK', state=>$state, error=>''};
  } else {
    $output   = {code=>400, status=>'BAD_REQUEST', error=>'Error: name and action parameters required'};
  }
  my $code    = delete($output->{'code'});
  my $content = encode_json($output);
  return [$code => ['Content-Type' => 'application/json'] => [$content]];
};

builder {
  enable 'Plack::Middleware::Favicon_Simple';
  enable 'Plack::Middleware::Method_Allow', allow=>['GET'];
  $app;
};

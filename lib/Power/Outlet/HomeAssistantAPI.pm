package Power::Outlet::HomeAssistantAPI;
use strict;
use warnings;
use base qw{Power::Outlet::Common::IP::HTTP::JSON};

our $VERSION = '0.54';

=head1 NAME

Power::Outlet::HomeAssistantAPI - Control and query a switch via the Home Assistant API

=head1 SYNOPSIS

  my $outlet = Power::Outlet::HomeAssistantAPI->new(host=>"my_ha_hostname", token=>"my_token", entity_id=>"my.entity_id");
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::HomeAssistantAPI is a package for controlling and querying a switch via the Home Assistant API.

From: L<https://developers.home-assistant.io/docs/api/rest/>

Examples:

Query switch entity

  $ curl -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" http://127.0.0.1:8123/api/states/switch.my_switch
  { "entity_id":"switch.my_switch", "state":"off", "attributes":{"friendly_name":"My Switch Name"}, ... }

Toggle switch entity

  $ curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"entity_id": "switch.my_switch"}' http://127.0.0.1:8123/api/services/switch/toggle

Turn ON switch entity

  $ curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"entity_id": "switch.my_switch"}' http://127.0.0.1:8123/api/services/switch/turn_on

Turn OFF switch entity

  $ curl -X POST -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"entity_id": "switch.my_switch"}' http://127.0.0.1:8123/api/services/switch/turn_off

=head1 USAGE

  use Power::Outlet::HomeAssistantAPI;
  my $outlet = Power::Outlet::HomeAssistantAPI->new(host=>"hostname", token=>$token, entity_id=>"POWER2");
  print $outlet->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"HomeAssistantAPI", host=>"hostname", token=>$token, entity_id=>"POWER2");
  my $outlet = Power::Outlet::HomeAssistantAPI->new(host=>"hostname", token=>$token, entity_id=>"my.entity_id");

=head1 PROPERTIES

=head2 token

A Home Assistant Long-lived access token is required to access the API.

=cut

sub token {
  my $self         = shift;
  $self->{'token'} = shift if @_;
  die('Error: token is required') unless defined $self->{'token'};
  return $self->{'token'};
}

=head2 entity_id

Home Assistant entity_id is required and is normally formatted string such as switch.short_name.

=cut

sub entity_id {
  my $self             = shift;
  $self->{'entity_id'} = shift if @_;
  die('Error: entity_id is required') unless defined $self->{'entity_id'};
  return $self->{'entity_id'};
}

=head2 host

Sets and returns the hostname or IP address.

Default: 127.0.0.1

=cut

sub _host_default {'127.0.0.1'};

=head2 port

Sets and returns the port number.

Default: 8123

=cut

sub _port_default {'8123'};

=head1 METHODS

=head2 name

Returns the FriendlyName from the HomeAssistantAPI hardware.

Note: The FriendlyName is cached for the life of the object.

=cut

sub name {
  my $self = shift;
  unless ($self->{'name'}) {
    my $attributes  = $self->_get->{'attributes'}    // {};
    $self->{'name'} = $attributes->{'friendly_name'} // $self->entity_id;
  }
  return $self->{'name'};
}

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self   = shift;
  my $return = $self->_get;
  return uc($return->{'state'});
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  $self->_post('turn_on');
  return 'ON'; #$self->query
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  $self->_post('turn_off');
  return 'OFF'; #$self->query
}

=head2 switch

Sends a message to the device to toggle the power

=cut

sub switch {
  my $self  = shift;
  my $query = $self->query;
  $self->_post('toggle'); #service delay
  return $query eq 'ON' ? 'OFF' : 'ON';
}

=head2 cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

=cut

#see Power::Outlet::Common->cycle

sub _http_path_default {return '/'};

sub _http_headers {
  my $self    = shift;
  my $token   = $self->token;
  my $headers = {'Authorization' => "Bearer $token", 'Content-Type', 'application/json'};
  return $headers;
}

sub _post{
  my $self    = shift;
  my $command = shift or die;
  my $path    = "/api/services/switch/$command";
  my $data    = {entity_id => $self->entity_id};
  my $url     = $self->url;
  my %options = (headers => $self->_http_headers);
  $url->path($path);
  my $return    = $self->json_request(POST => $url, $data, \%options);
  return 'ok';
}

sub _get {
  my $self      = shift;
  my $entity_id = $self->entity_id;
  my $path      = "/api/states/$entity_id";
  my $url       = $self->url;
  my %options   = (headers=>$self->_http_headers);
  $url->path($path);
  my $return    = $self->json_request(GET => $url, undef, \%options);
  die('Error: Method _get failed to return expected JSON object') unless ref($return) eq 'HASH';
  return $return;
}

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT

=head1 COPYRIGHT

Copyright (c) 2026 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;

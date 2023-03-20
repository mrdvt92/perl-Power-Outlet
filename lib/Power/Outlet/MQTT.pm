package Power::Outlet::MQTT;
use strict;
use warnings;
use Net::MQTT::Simple 1.24; #1.21 subscribe broken, 1.22 added login method
use Net::MQTT::Simple::SSL;
use Net::MQTT::Simple::One_Shot_Loader;
use base qw{Power::Outlet::Common::IP};

our $VERSION = '0.49';

=head1 NAME

Power::Outlet::MQTT - Control and query an outlet or relay via MQTT

=head1 SYNOPSIS

Tasmota defaults

  my $outlet = Power::Outlet::MQTT->new(
                                        host                => "mqtt",
                                        name                => "my_device",
                                        relay               => "POWER1",
                                       );

or topic defaults

  my $outlet = Power::Outlet::MQTT->new(
                                        host                => "mqtt",
                                        publish_topic       => "cmnd/my_device/POWER1",
                                        subscribe_topic     => "stat/my_device/POWER1",
                                       );

or explicit definitions with no defaults

  my $outlet = Power::Outlet::MQTT->new(
                                        host                => "mqtt",
                                        publish_on          => "cmnd/my_device/POWER1+ON", #plus sign delimited topic and message
                                        publish_off         => "cmnd/my_device/POWER1+OFF",
                                        publish_switch      => "cmnd/my_device/POWER1+TOGGLE",
                                        publish_query       => "cmnd/my_device/POWER1+",
                                        subscribe_topic     => "stat/my_device/POWER1",
                                        subscribe_value_on  => 'ON'  #or qr/\A(?:ON|1)\Z/i,
                                        subscribe_value_off => 'OFF, #or qr/\A(?:OFF|0)\Z/i,
                                       );
  print $outlet->query, "\n";
  print $outlet->on, "\n";
  print $outlet->off, "\n";

=head1 DESCRIPTION

Power::Outlet::MQTT is a package for controlling and querying an outlet or relay via MQTT

Examples:

  $ mosquitto_pub -h mqtt -t "cmnd/my_device/POWER1" -m ON
  $ mosquitto_pub -h mqtt -t "cmnd/my_device/POWER1" -m OFF
  $ mosquitto_sub -h mqtt -t "stat/my_device/POWER1" -v

=head1 USAGE

  use Power::Outlet::MQTT;
  my $outlet = Power::Outlet::MQTT->new(host=>"mqtt", name=>"my_device");
  print $outlet->on, "\n";

=head1 CONSTRUCTOR

=head2 new

  my $outlet = Power::Outlet->new(type=>"MQTT", host=>"mqtt");
  my $outlet = Power::Outlet::MQTT->new(host=>"mqtt");

=head1 PROPERTIES

=head2 host

Sets and returns the host name of the MQTT broker.

Default: mqtt

=cut

sub _host_default {'mqtt'};

=head2 port

Sets and returns the port number of the MQTT broker.

Default: 1883

=cut

sub _port_default {'1883'};

=head2 secure

Sets and returns a boolean property to use secure MQTT protocol or not.

Default: if port=8883 then 1 else 0

=cut

sub secure {
  my $self          = shift;
  $self->{'secure'} = shift if @_;
  unless (defined $self->{'secure'}) {
    $self->{'secure'} = $self->port eq '8883' ? 1 : 0;
  }
  return $self->{'secure'}; 
}

=head2 name

Sets and returns the name of the device.  Also, enables defaults for publish and subscribe massages to support Tasmota hardware.

=cut

=head2 relay

Sets and returns the relay of the device.  Only used when name is used to define default publish and subscribe topics.

Default: POWER1

=cut

sub relay {
  my $self         = shift;
  $self->{'relay'} = shift if @_;
  $self->{'relay'} = 'POWER1' unless $self->{'relay'};
  return $self->{'relay'};
}

=head2 publish_topic

MQTT topic to publish to control the relay

Default: "cmnd/$name/$relay"

=cut

sub publish_topic  {
  my $self                 = shift;
  $self->{'publish_topic'} = shift if @_;
  $self->{'publish_topic'} = join('/', 'cmnd', $self->name, $self->relay) if (!$self->{'publish_topic'} and defined $self->name);
  die("Error: publish_topic required") unless $self->{'publish_topic'};
  return $self->{'publish_topic'};
}

=head2 publish_on

MQTT topic and message payload to publish to turn the relay on (plus sign delimited)

Default: "cmnd/$name/$relay+ON"

=cut

sub publish_on {
  my $self              = shift;
  $self->{'publish_on'} = shift if @_;
  $self->{'publish_on'} = join('+', $self->publish_topic, 'ON') if (!$self->{'publish_on'} and defined $self->publish_topic);
  die("Error: publish_on required") unless $self->{'publish_on'};
  return $self->{'publish_on'};
}

=head2 publish_off

MQTT topic and message payload to turn the relay off (plus sign delimited)

Default: "cmnd/$name/$relay+OFF"

=cut

sub publish_off {
  my $self               = shift;
  $self->{'publish_off'} = shift if @_;
  $self->{'publish_off'} = join('+', $self->publish_topic, 'OFF') if (!$self->{'publish_off'} and defined $self->publish_topic);
  die("Error: publish_off required") unless $self->{'publish_off'};
  return $self->{'publish_off'};
}

=head2 publish_switch

MQTT topic and message payload to toggle the relay (plus sign delimited)

Default: "cmnd/$name/$relay+TOGGLE"

=cut

sub publish_switch {
  my $self                  = shift;
  $self->{'publish_switch'} = shift if @_;
  $self->{'publish_switch'} = join('+', $self->publish_topic, 'TOGGLE') if (!$self->{'publish_switch'} and defined $self->publish_topic);
  die("Error: publish_switch required") unless $self->{'publish_switch'};
  return $self->{'publish_switch'};
}

=head2 publish_query

MQTT topic and message payload to request the turn the current state of the relay (plus sign delimited)

Default: "cmnd/$name/$relay+"

=cut

sub publish_query {
  my $self                 = shift;
  $self->{'publish_query'} = shift if @_;
  $self->{'publish_query'} = join('+', $self->publish_topic, '') if (!$self->{'publish_query'} and defined $self->publish_topic);
  die("Error: publish_query required") unless $self->{'publish_query'};
  return $self->{'publish_query'};
}

=head2 subscribe_topic

MQTT topic which indicates the current state of the relay

Default: "stat/$name/$relay+"

=cut

sub subscribe_topic {
  my $self                   = shift;
  $self->{'subscribe_topic'} = shift if @_;
  $self->{'subscribe_topic'} = join('/', 'stat', $self->name, $self->relay) if (!$self->{'subscribe_topic'} and defined $self->name);
  die("Error: subscribe_topic required") unless $self->{'subscribe_topic'};
  return $self->{'subscribe_topic'};
}

=head2 subscribe_value_on

MQTT message payload to indicate the current state of the relay as on

Default: "ON" or 1

=cut

sub subscribe_value_on {
  my $self                      = shift;
  $self->{'subscribe_value_on'} = shift if @_;
  $self->{'subscribe_value_on'} = qr/\A(?:ON|1)\Z/i unless defined $self->{'subscribe_value_on'};
  return $self->{'subscribe_value_on'};
}

=head2 subscribe_value_off

MQTT message payload to indicate the current state of the relay as off

Default: "OFF" or 0

=cut

sub subscribe_value_off {
  my $self                       = shift;
  $self->{'subscribe_value_off'} = shift if @_;
  $self->{'subscribe_value_off'} = qr/\A(?:OFF|0)\Z/i unless defined $self->{'subscribe_value_off'};
  return $self->{'subscribe_value_off'};
}

=head2 user

Sets and returns the authentication user for the MQTT broker.

Default: undef

=cut

sub user {
  my $self        = shift;
  $self->{'user'} = shift if @_;
  $self->{'user'} = $self->_user_default unless defined $self->{'user'};
  return $self->{'user'};
}

sub _user_default {undef};

=head2 password

Sets and returns the password used for authentication with the MQTT broker

Default: ""

=cut

sub password {
  my $self            = shift;
  $self->{'password'} = shift if @_;
  $self->{'password'} = $self->_password_default unless defined $self->{'password'};
  return $self->{'password'};
}

sub _password_default {''};


=head1 METHODS

=head2 query

Sends an HTTP message to the device to query the current state

=cut

sub query {
  my $self = shift;
  return $self->_mqtt_one_shot_value($self->subscribe_topic, $self->publish_query);
}

=head2 on

Sends a message to the device to Turn Power ON

=cut

sub on {
  my $self = shift;
  return defined(wantarray()) ? $self->_mqtt_one_shot_value($self->subscribe_topic, $self->publish_on)
                              : $self->_publish($self->publish_on);
}

=head2 off

Sends a message to the device to Turn Power OFF

=cut

sub off {
  my $self = shift;
  return defined(wantarray()) ? $self->_mqtt_one_shot_value($self->subscribe_topic, $self->publish_off)
                              : $self->_publish($self->publish_off);
}

=head2 switch

=cut

sub switch {
  my $self = shift;
  return defined(wantarray()) ? $self->_mqtt_one_shot_value($self->subscribe_topic, $self->publish_switch)
                              : $self->_publish($self->publish_switch);
}

=head2 cycle

=cut

#see Power::Outlet::Common->cycle

sub _topic_message_split {
  my $self          = shift;
  my $topic_message = shift;
  my ($topic, $message);
  if ($topic_message =~ m/\A([^+]+)\+(.*)\Z/) {
    $topic   = $1;
    $message = $2;
  } else {
    $topic   = $topic_message;
    $message = undef;
  }
  return($topic, $message);
}

sub _publish {
  my $self          = shift;
  my $topic_message = shift; 
  my $epoch         = $self->mqtt->publish($self->_topic_message_split($topic_message));
  return $epoch;
}

sub _mqtt_one_shot_value {
  my $self                  = shift;
  my $topic_subscription    = shift;
  my $topic_message_publish = shift;
  my $timeout               = shift || 1.5;
  my $return                = $self->mqtt->one_shot($topic_subscription, $self->_topic_message_split($topic_message_publish), $timeout);
  my $msg                   = $return->message;
  my $on                    = $self->subscribe_value_on;
  my $off                   = $self->subscribe_value_off;
  return ( ref($on)  eq 'Regexp' and $msg =~ m/$on/ ) ? 'ON'
       : ( ref($off) eq 'Regexp' and $msg =~ m/$off/) ? 'OFF'
       : (!ref($on)              and $msg eq $on    ) ? 'ON'
       : (!ref($off)             and $msg eq $off   ) ? 'OFF'
       : $msg;
}

=head1 ACCESSORS

=head2 mqtt

=cut

our $MQTT_CLASS     = 'Net::MQTT::Simple';
our $MQTT_CLASS_SSL = 'Net::MQTT::Simple::SSL';

sub mqtt {
  my $self = shift;
  unless ($self->{'mqtt'}) {
    my $host        = join(':', $self->host, $self->port);
    my $class       = $self->secure ? $MQTT_CLASS_SSL : $MQTT_CLASS;
    $self->{'mqtt'} = $class->new($host);
    $self->{'mqtt'}->login($self->user, $self->password) if $self->user;
  }
  return $self->{'mqtt'};
}

=head1 BUGS

Please log on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

Copyright (c) 2023 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

=cut

1;

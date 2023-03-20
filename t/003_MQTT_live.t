# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 13 + 25;

#TODO: add tests for SSL
#TODO: add tests for auth

BEGIN { use_ok( 'Power::Outlet' ); }
BEGIN { use_ok( 'Power::Outlet::MQTT' ); }

my $host = $ENV{'MQTT_HOST'};
my $name = $ENV{'MQTT_NAME'};
my $skip = not ($host and $name);

my $obj = Power::Outlet::MQTT->new;
isa_ok ($obj, 'Power::Outlet::MQTT');
can_ok($obj, 'new');
can_ok($obj, 'host');
can_ok($obj, 'name');
can_ok($obj, 'relay');
can_ok($obj, 'on');
can_ok($obj, 'off');
can_ok($obj, 'query');
can_ok($obj, 'switch');
can_ok($obj, 'cycle');
can_ok($obj, 'action');

SKIP: {
  skip 'ENV MQTT_HOST, MQTT_NAME must be set', 25 if $skip;

  my $outlet = Power::Outlet::MQTT->new(host=>$host, name=>$name);
  isa_ok($outlet->mqtt, 'Net::MQTT::Simple');
  can_ok($outlet->mqtt, 'one_shot'); #added by One_Shot_Loader

  is($outlet->host, $host, 'host');
  is($outlet->name, $name, 'name');
  is($outlet->port, '1883', 'port');

  is($outlet->publish_topic , "cmnd/$name/POWER1"       , 'publish_topic');
  is($outlet->publish_on    , "cmnd/$name/POWER1+ON"    , 'publish_on');
  is($outlet->publish_off   , "cmnd/$name/POWER1+OFF"   , 'publish_off');
  is($outlet->publish_switch, "cmnd/$name/POWER1+TOGGLE", 'publish_switch');
  is($outlet->publish_query , "cmnd/$name/POWER1+"      , 'publish_query');

  is($outlet->subscribe_topic    , "stat/$name/POWER1"  , 'subscribe_topic');
  isa_ok($outlet->subscribe_value_on,  'Regexp'         , 'subscribe_value_on');
  isa_ok($outlet->subscribe_value_off, 'Regexp'         , 'subscribe_value_off');
  is($outlet->subscribe_value_on('ON')  , 'ON'          , 'subscribe_value_on');
  is($outlet->subscribe_value_off('OFF'), 'OFF'         , 'subscribe_value_off');

  my $state = $outlet->query;
  if ($state eq 'ON') {
    diag('Turning Off');
    $outlet->off;
    sleep 1;
  }

  diag('Turning On');
  is($outlet->on, 'ON', 'on method');
  is($outlet->query, 'ON', 'query method');
  sleep 1;

  diag('Turning Off');
  is($outlet->off, 'OFF', 'off method');
  is($outlet->query, 'OFF', 'query method');
  sleep 1;

  diag('Switching');
  is($outlet->switch, 'ON', 'on method');
  is($outlet->query, 'ON', 'query method');
  sleep 1;

  diag('Switching');
  is($outlet->switch, 'OFF', 'off method');
  is($outlet->query, 'OFF', 'query method');
  sleep 1;

  diag('Cycling');
  is($outlet->cycle, 'OFF', 'cycle method'); #blocking
  is($outlet->query, 'OFF', 'query method');

  if ($state eq 'ON') {
    diag('Turning On');
    $outlet->on;
  }
}

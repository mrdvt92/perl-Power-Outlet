# -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'Power::Outlet::HomeAssistantAPI' ); }

my $host        = $ENV{"NET_HOMEASSISTANTAPI_HOST"}      || '127.0.0.1';
my $token       = $ENV{"NET_HOMEASSISTANTAPI_TOKEN"}     || undef;
my $entities    = $ENV{"NET_HOMEASSISTANTAPI_ENTITY_ID"} || "switch.sw_firepit";
my $names       = $ENV{"NET_HOMEASSISTANTAPI_NAMES"}     || "sw-firepit";

my $loop_tests  = 16;
my @entities    = split(/,/, $entities);
my @names       = split(/,/, $names);
my %names       = ();
@names{@entities} = @names;

SKIP: {

  unless ($token) {
    my $text='$ENV{"NET_HOMEASSISTANTAPI_TOKEN"} not set skipping live tests';
    diag($text);
    skip $text, @entities * $loop_tests;
  }

  foreach my $entity_id (@entities) {
    my $device = Power::Outlet::HomeAssistantAPI->new(host=>$host, token=>$token, entity_id=>$entity_id);

    diag("\nOutlet: $entity_id\n\n");

    is($device->entity_id, $entity_id, 'entity_id');
    is($device->host, $host, 'host');
    is($device->port, '8123', 'port');
    is($device->token, $token, 'token');
    is($device->name, $names{$entity_id}, 'name');

    isa_ok ($device, 'Power::Outlet::HomeAssistantAPI');
    my $state=$device->query;
    if ($state eq "ON") {
      diag("Turning Off");
      $device->off;
      sleep 1;
    }

    diag("Turning On");
    is($device->on, "ON", 'on method');
    sleep 1;
    is($device->query, "ON", 'query method');

    diag("Turning Off");
    is($device->off, "OFF", 'off method');
    sleep 1;
    is($device->query, "OFF", 'query method');

    diag("Switching");
    is($device->switch, "ON", 'on method');
    sleep 1;
    is($device->query, "ON", 'query method');

    diag("Switching");
    is($device->switch, "OFF", 'off method');
    sleep 1;
    is($device->query, "OFF", 'query method');

    diag("Cycling");
    is($device->cycle, "OFF", 'cycle method'); #blocking
    sleep 1;
    is($device->query, "OFF", 'query method');

    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}

done_testing( @entities * $loop_tests + 1 );

# -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'Power::Outlet::Dingtian' ); }

my $host        = $ENV{"NET_DINGTIAN_HOST"}   || undef;
my $relays      = $ENV{"NET_DINGTIAN_RELAYS"} || "1,2";
my $names       = $ENV{"NET_DINGTIAN_NAMES"}  || "Relay 1,Relay 2"; #my devices defaults...

my $loop_tests  = 16;
my @relays      = split(/,/, $relays);
my @names       = split(/,/, $names);
my %names       = ();
@names{@relays} = @names;

SKIP: {

  unless ($host) {
    my $text='$ENV{"NET_DINGTIAN_HOST"} not set skipping live tests';
    diag($text);
    skip $text, @relays * $loop_tests;
  }

  foreach my $relay (@relays) {
    my $device = Power::Outlet::Dingtian->new(host=>$host, relay=>$relay);

    diag("\nOutlet: $relay\n\n");

    is($device->relay, $relay, 'relay');
    is($device->host, $host, 'host');
    is($device->port, '80', 'port');
    is($device->pwd, '0', 'password');
    is($device->name, $names{$relay}, 'name');

    isa_ok ($device, 'Power::Outlet::Dingtian');
    my $state=$device->query;
    if ($state eq "ON") {
      diag("Turning Off");
      $device->off;
      sleep 1;
    }

    diag("Turning On");
    is($device->on, "ON", 'on method');
    is($device->query, "ON", 'query method');
    sleep 1;

    diag("Turning Off");
    is($device->off, "OFF", 'off method');
    is($device->query, "OFF", 'query method');
    sleep 1;

    diag("Switching");
    is($device->switch, "ON", 'on method');
    is($device->query, "ON", 'query method');
    sleep 1;

    diag("Switching");
    is($device->switch, "OFF", 'off method');
    is($device->query, "OFF", 'query method');
    sleep 1;

    diag("Cycling");
    is($device->cycle, "CYCLE", 'cycle method'); #non-blocking
    sleep($device->cycle_duration);
    sleep 1;
    is($device->query, "OFF", 'query method');

    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}

done_testing( @relays * $loop_tests + 1 );

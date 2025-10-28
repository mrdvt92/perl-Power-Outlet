# -*- perl -*-

use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'Power::Outlet::OpenBeken' ); }

my $host        = $ENV{"NET_OPENBEKEN_HOST"}     || undef;
my $relays      = $ENV{"NET_OPENBEKEN_RELAYS"}   || "POWER,POWER1,1"; #I do not own a multirelay device to test POWER2
my $names       = $ENV{"NET_OPENBEKEN_NAMES"}    || "FriendlyName1,FriendlyName1,FriendlyName1";

my $loop_tests  = 17;
my @relays      = split(/,/, $relays);
my @names       = split(/,/, $names);
my %names       = ();
@names{@relays} = @names;

SKIP: {

  unless ($host) {
    my $text='$ENV{"NET_OPENBEKEN_HOST"} not set skipping live tests';
    diag($text);
    skip $text, @relays * $loop_tests;
  }

  foreach my $relay (@relays) {
    my $device = Power::Outlet::OpenBeken->new(host=>$host, relay=>$relay);

    diag("\nOutlet: $relay\n\n");

    is($device->relay, $relay, 'relay');
    is($device->host, $host, 'host');
    is($device->port, '80', 'port');
    is($device->user, undef, 'username');
    is($device->password, '', 'password');
    is($device->name, $names{$relay}, 'name');

    isa_ok ($device, 'Power::Outlet::OpenBeken');
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
    is($device->cycle, "OFF", 'cycle method'); #blocking
    is($device->query, "OFF", 'query method');

    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}

done_testing( @relays * $loop_tests + 1 );

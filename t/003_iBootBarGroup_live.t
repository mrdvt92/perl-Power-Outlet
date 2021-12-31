# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 1 + 17 * 3;
my $skip      = 17 * 3;

BEGIN { use_ok( 'Power::Outlet::iBootBarGroup' ); }

my $host      = $ENV{'NET_IBOOTBAR_HOST'}     || undef;
my $community = $ENV{'NET_IBOOTBAR_COMUNITY'} || undef;

SKIP: {
  unless ($host) {
    my $text = '$ENV{"NET_IBOOTBAR_HOST"} not set skipping live tests';
    diag($text);
    skip $text, $skip;
  }

  foreach my $outlet ('1,2', '1,2,3,4,5,6,7,8', 8) {
    diag("\n\nOutlet: $outlet\n\n");

    my $device = Power::Outlet::iBootBarGroup->new(host=>$host, community=>$community, outlets=>$outlet, name=>"My Name $outlet");
    is($device->outlets, $outlet, 'outlets');
    is($device->host, $host, 'host');
    is($device->port, "161", 'port');
    is($device->community, "private", 'community');
    is($device->name, "My Name $outlet", 'name');

    isa_ok ($device, 'Power::Outlet::iBootBarGroup');
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
    is($device->cycle, "CYCLE", 'cycle method');
    is($device->query, "CYCLE", 'query method');
    sleep 10; #assume set up "Cycle Time" = 10 seconds
  
    is($device->query, "OFF", 'query method');
    sleep 1;
  
    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}

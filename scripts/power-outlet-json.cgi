#!/usr/bin/perl
use strict;
use warnings;
use CGI qw{};
use JSON qw{encode_json};
use Power::Outlet::Config qw{};

my $cgi        = CGI->new;
my $ini        = '/etc/power-outlet.ini';
my $status     = '';
my $state      = '';
my $error      = '';
my $httpstatus = '';
my $name       = $cgi->param('name');

if (defined($name) and length($name)) {
  my $action = $cgi->param('action');
  if (defined($action) and length($action)) {
    local $@;
    my $outlet = eval{Power::Outlet::Config->new(section=>$name)};
    $error     = $@;
    if ($error) {
      if ($error =~ m/Error: .* Section .* does not exist/) {
        $status     = 'PARAMETER_NAME_INVALID';
        $httpstatus = '400 Bad Request';
      } else {
        $status     = 'UNKNOWN';
        $httpstatus = '500 Internal Server Error';
      }
    } else {

      sub _call {
        my $outlet     = shift or die;
        my $method     = shift or die;
        my $list       = shift or die;
        my $status     = '';
        local $@;
        my $state      = eval{$outlet->$method};
        my $error      = $@;
        my $httpstatus = '';
        if ($error) {
          $status     = 'COMMUNICATIONS_ISSUE';
          $httpstatus = '502 Bad Gateway';
        } elsif (grep {$state eq $_} @$list) {
          $status     = 'OK';
          $httpstatus = '200 OK';
        } else {
          $status     = 'UNKNOWN';
          $httpstatus = '500 Internal Server Error';
        }
        return($status, $state, $error, $httpstatus);
      }

      if ($action =~ m/\AON\Z/i) {
        ($status, $state, $error, $httpstatus) = _call($outlet => on     => [qw{ ON     }]);
      } elsif ($action =~ m/\AOFF\Z/i) {
        ($status, $state, $error, $httpstatus) = _call($outlet => off    => [qw{    OFF }]);
      } elsif ($action =~ m/\AQUERY\Z/i) {
        ($status, $state, $error, $httpstatus) = _call($outlet => query  => [qw{ ON OFF }]);
      } elsif ($action =~ m/\ASWITCH\Z/i) {
        ($status, $state, $error, $httpstatus) = _call($outlet => switch => [qw{ ON OFF }]);
      } else {
        $status     = 'PARAMETER_ACTION_INVALID';
        $error      = 'Error: Parameter "action" must be one of "ON", "OFF", "QUERY", "SWITCH"';
        $httpstatus = '400 Bad Request';
      }
    }
  } else {
    $status     = 'PARAMETER_ACTION_MISSING';
    $error      = 'Error: Parameter "action" required';
    $httpstatus = '400 Bad Request';
  }
} else {
  $status     = 'PARAMETER_NAME_MISSING';
  $error      = 'Error: Parameter "name" required';
  $httpstatus = '400 Bad Request';
}

my %return = (
              status => $status,
              state  => $state,
              error  => $error,
             );

print $cgi->header(-status => $httpstatus,
                   -type   => 'application/json'),
      encode_json(\%return),
      "\n";

__END__

=head1 NAME

power-outlet-json.cgi - Control Power::Outlet device with JSON web service (e.g. Node-Red)

=head1 DESCRIPTION

power-outlet-json.cgi is a CGI application to control a Power::Outlet device with a web service.

=head1 API

The script is called over HTTP with name and action parameters.  The name is the Section Name from the INI file and the action is one of on, off, query, or switch.

  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=off
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=on
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=query
  http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=switch

Return is a JSON hash with keys status and state.  status is OK if there are no errors, state is the state of the switch after command either ON or OFF.

  {"status":"OK","state":"ON"}

=head1 Node-Red Integration

Use three nodes: inject, http request, and debug.

=over

=item * In the inject node

=over

=item * Set the "Topic" to the desired INI config file [section] name.

=item * Set the "Payload" to one of "ON", "OFF", "QUERY" or "SWITCH"

=back

=item * In the http request node

=over

=item * Set the "Method" to GET (script also supports POST)

=item * Set the "URL" to https://127.0.0.1/power-outlet/power-outlet-json.cgi?name={{topic}};action={{payload}}

=item * Set the "Return" to a parsed JSON Object

=back

=item * In the debug node

=over

=item * Set the "Output" to msg.payload.state which returns "ON" or "OFF"

=back

=back

=head2 Node Red Example

  [{"id":"736cc2df.cc616c","type":"inject","z":"bbbcee28.8891c","name":"","topic":"Christmas Tree","payload":"On","payloadType":"str","repeat":"","crontab":"","once":false,"onceDelay":0.1,"x":330,"y":1480,"wires":[["6f024760.ea5058"]]},{"id":"6f024760.ea5058","type":"http request","z":"bbbcee28.8891c","name":"power-outlet-json.cgi","method":"GET","ret":"obj","paytoqs":false,"url":"https://127.0.0.1/power-outlet/power-outlet-json.cgi?name={{topic}};action={{payload}}","tls":"","persist":false,"proxy":"","authType":"","x":560,"y":1480,"wires":[["2673faca.21f8d6"]],"inputLabels":["Topic=>name, Payload=>action"]},{"id":"2673faca.21f8d6","type":"debug","z":"bbbcee28.8891c","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload.state","targetType":"msg","x":790,"y":1480,"wires":[]}]

=head1 CONFIGURATION

To add an outlet for the web service, add a new INI section to the power-outlet.ini file.

  [Tree]
  type=Tasmota
  host=light-tree
  groups=Outside Lights

If you need to override the defaults

  [Kitchen]
  type=Shelly
  name=Kitchen
  host=sw-kitchen
  port=80
  style=relay
  index=0
  groups=Inside Lights

WeMo device

  [Living Room]
  type=WeMo
  host=sw-living-room
  groups=Inside Lights

Default Location: /etc/power-outlet.ini

=head2 BUILD

  rpmbuild -ta Power-Outlet-*.tar.gz

=head1 INSTALLATION

I recommend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet.

  sudo yum install perl-Power-Outlet-application-cgi

=cut

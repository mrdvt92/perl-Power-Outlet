#!/usr/bin/perl
use strict;
use warnings;
use File::Basename qw{};
use Getopt::Std qw{getopts};
use IO::Socket qw{};
use Time::HiRes qw{time alarm};

# - https://www.dingtian-tech.com/en_us/support.html?tab=download
#   - https://www.dingtian-tech.com/sdk/relay_sdk.zip
#     - string protocol
#       - programming_manual_en.pdf
#         - 1 Protocol:Dingtian string
#           '00' => 2-port '00:11:2' ||4 port '0101:1111:4' 
#     - UDP Port Configured
#       - Menu -> Relay Connect -> UDP2 -> Dingtian String -> port 60001

my $basename = File::Basename::basename($0);
my $syntax   = qq{Syntax: $basename [-d] [-p port] host [command] [relay]
  -d      - enable debug printing
  -p port - alternative UDP port          - default 60001
  host    - UDP/IP hostname or IP address - required
  command - status|on|off                 - default status
  relay   - relay number 1-32             - default 1
};

my $opt      = {};
getopts('dp:', $opt);
my $debug    = $opt->{'d'} || '';
my $port     = $opt->{'p'} || '60001';
my $host     = shift or die($syntax);
my $command  = shift || 'status';
my $relay    = shift || 1;

my $socket   = IO::Socket::INET->new(
                                    Proto    => 'udp',
                                    PeerAddr => $host,
                                    PeerPort => $port,
                                   ) or die "Error: $@";

my $send     = $command eq 'status' ? '00'
             : $command eq 'on'     ? "1$relay"
             : $command eq 'off'    ? "2$relay"
             : die($syntax);

my $res      = _send($send);

if ($res->{'error'}) {
  printf "Error: %s\n", $res->{'error'};
} else {
  printf "Response: %s\n", $res->{'content'} if $debug;
  printf "%s\n", _parse($relay, $res->{'content'});
}

sub _parse {
  my $relay                                     = shift;
  my $content                                   = shift; #"00:11:2" || "1010:1111:4"
  my ($relay_flags, $input_flags, $relay_count) = split /:/, $content;
  my @relay_flag_array                          = split //, $relay_flags;
  if ($relay eq 'X') {
    return scalar(grep {$_} @relay_flag_array) ? 'ON' : 'OFF';
  } else {
    return $relay_flag_array[$relay - 1] == '1' ? 'ON'
         : $relay_flag_array[$relay - 1] == '0' ? 'OFF'
         : die("Error: content format unknown $content");
  }
}

sub _send {
  my $send   = shift;
  my $recv   = '';
  my $timer  = time;
  $socket->send($send);
  eval {
    local $SIG{ALRM} = sub {die "Timeout\n"};
    my $alarm = alarm 0.75;
    $socket->recv($recv, 255, 0);
    alarm $alarm;
  };
  my $error  = $@;
  $timer     = (time - $timer) * 1000;
  chomp $error; #Timeout
  $error     = "Empty Response" if (!$error and length($recv) == 0);
  printf "Time: %0.2fms\n", $timer if $debug;
  return {error=>$error, time=>$timer, content=>$recv};
}

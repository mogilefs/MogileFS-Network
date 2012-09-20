#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 9;
use FindBin qw($Bin);

use MogileFS::Network;
use IO::Socket::INET;

MogileFS::Network->test_config(
    zone_one    => '127.0.0.0/16',
    zone_two    => '10.0.0.0/8, 172.16.0.0/16',
    zone_three => '10.1.0.0/16',
    network_zones => 'one, two, three',
);


is(lookup('127.0.0.1'), 'one', "Standard match");
is(lookup('10.0.0.1'), 'two', "Outer netblock match");
is(lookup('10.1.0.1'), 'three', "Inner netblock match");
is(lookup('172.16.0.1'), 'two', "Zone with multiple netblocks");
is(lookup('192.168.0.1'), undef, "Unknown zone");


my $sock = IO::Socket::INET->new(Proto => 'udp',
                                 PeerAddr => '10.0.0.1',
                                 PeerPort => 1);
my $self_ip = $sock->sockhost;
$sock->close;
my $self_net = $self_ip;
$self_net =~ s!\.\d+\z!.0/24!;

MogileFS::Network->test_config(
    zone_self   => $self_net,
    zone_one    => '10.1.0.0/16',
    zone_two    => '10.2.0.0/16',
    zone_big    => '10.0.0.0/8',
    network_zones => 'one,two,big,self',
);

is(lookup('127.0.0.1'), 'self', "local connection goes to self");

# ensure existing configs work
is(lookup('10.1.1.1'), 'one', "one match");
is(lookup('10.2.1.1'), 'two', "two match");
is(lookup('10.9.1.1'), 'big', "big match");

sub lookup {
    return MogileFS::Network->zone_for_ip(@_);
}

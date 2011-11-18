#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use App::Kuragepo::Worker qw/ register run /;

my($kuragepo_host, $kuragepo_port) = @ARGV;

register 'echo' => {
    host => $kuragepo_host,
    port => $kuragepo_port,
    cb   => sub {
        my($func, $args) = @_;
        "$args->{from_nickname}: $args->{message}";
    },
    init => +{
        join => ['#ikachan'],
    },
};

run;

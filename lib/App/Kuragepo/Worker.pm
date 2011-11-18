package App::Kuragepo::Worker;
use strict;
use warnings;
use parent qw/Exporter/;
our $VERSION = '0.01';
our @EXPORT = qw/ register run /;

use JSON;
use Net::MPRPC::Client;
use Gearman::Worker;

my %workers;
my %gearman;

sub register {
    my $caller = caller;
    my($worker, $args) = @_;
    $workers{$caller} ||= +{};

    if ($workers{$caller}{$worker}) {
        warn "$worker is registerd";
        return;
    }

    my $client = Net::MPRPC::Client->new(
        host => $args->{host},
        port => $args->{port},
    );
    my $res = $client->call( register => +{
        worker => $worker,
    });
    unless ($res) {
        warn "$worker can not registerd";
        return;
    }
    start_pinger($args->{host}, $args->{port}, $worker);

    $gearman{$caller} ||= do {
        my $g = Gearman::Worker->new;
        $g->job_servers("$res->{gearmand_host}:$res->{gearmand_port}");
        $g;
    };
    $gearman{$caller}->register_function(
        $worker => sub {
            my $req = shift;
            $args->{cb}->($req->{func}, decode_json(${ $req->{argref} }));
        });

    if ($args->{init}) {
        if ($args->{init}{join}) {
            for my $channel (@{ $args->{init}{join} || [] }) {
                $client->call( join => +{
                    worker  => $worker,
                    channel => $channel,
                });
            }
        }
    }

    return 1;
}

sub run {
    my $caller = caller;
    return unless $gearman{$caller};
    $gearman{$caller}->work while 1;
}


my %ping_hosts;
my @pids;
sub start_pinger {
    my($host, $port, $worker) = @_;
    next if $ping_hosts{"$host:$port:$worker"};
    my $pid = fork();
    if ($pid == 0) {
        my $client = Net::MPRPC::Client->new(
            host => $host,
            port => $port,
        );
        while (1) {
            sleep 60;
            $client->call( ping => +{ worker => $worker } );
        }
    }
    $ping_hosts{"$host:$port:$worker"} = $pid;
    push @pids, $pid;
}

END {
    for my $pid (@pids) {
        kill 9, $pid;
    }
}

1;
__END__

=head1 NAME

App::Kuragepo::Worker -

=head1 SYNOPSIS

    use App::Kuragepo::Worker;

see C<example/echo.pl>

=head1 DESCRIPTION

App::Kuragepo::Worker is

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {at} shibuya {dot} plE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

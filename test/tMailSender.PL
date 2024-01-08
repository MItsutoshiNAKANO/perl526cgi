#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;
use Scalar::Util qw(reftype);
use Cwd;
use TOML::Tiny;
use Mojo::Log;
use lib '/var/www/perl';
use MailSender;

my $config_file = '../secrets/MailSender.toml';
my $log = Mojo::Log->new(level => 'trace');

my $texts = [
    ["Subject: test\n", "\n", "test\n"],
    ["Subject: test\n", "\n", "日本語test\n"]
];

print('test1: ');
my $mail = MailSender->new($config_file, $log);
for (my $i = 0; $i < @{$texts}; ++$i) {
    unless ($mail->send($texts->[$i])) {
        print("NG\n");
        die;
    }
}
print("OK\n");


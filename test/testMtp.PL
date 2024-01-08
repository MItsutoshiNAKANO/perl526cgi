#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;
use Email::Stuffer;
use TOML::Tiny;
use lib '/var/www/perl';
use Mtp;

my $addresses_file = '../etc/mail.toml';
my $address = Mtp->_load($addresses_file);

my $mtp = Mtp->new();
my $sender = $mtp->sender();

my $mails = [
    { subject => "test", text => "test\n" },
    { subject => "テスト", text => "日本語\n" },
];

print('test1: ');
foreach my $hr (@{$mails}) {
    Email::Stuffer->transport($sender)
    ->from($address->{from})->to($address->{to})
    ->subject($hr->{subject})->text_body($hr->{text})->send_or_die; 
}
print("OK\n");

#! /usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use Carp qw(cluck);
use utf8;
use File::Basename;
use lib '/var/www/perl';
use Workers;

no strict 'subs';
# $workers は単に 'Workers' という string.
my $workers = Workers;
use strict;

my $webapp = $workers->new(TMPL_PATH => dirname($0) . '/../templates');
$webapp->run();

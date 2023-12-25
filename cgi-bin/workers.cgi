#! /usr/bin/env perl

use v5.26.0;
use strict;
use warnings;
use Carp qw(cluck);
use utf8;
use File::Basename;
use lib '/var/www/perl';
use Workers;

my $webapp = Workers->new(TMPL_PATH => dirname($0) . '/../templates');
$webapp->run();

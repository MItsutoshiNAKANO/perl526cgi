#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;
use File::Basename;
use lib '/var/www/perl';
use Driver;

my $webapp = Driver->new(TMPL_PATH => dirname($0) . '/../templates');
$webapp->run();

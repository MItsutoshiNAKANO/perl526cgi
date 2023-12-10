#! /usr/bin/env perl

use v5.26;
use strict;
use warnings;
use utf8;
use File::Basename;
use lib '/var/www/perl';
use ListEnv;

my $webapp = MyCGIApp->new(TMPL_PATH => dirname($0) . '/../templates');
$webapp->run();

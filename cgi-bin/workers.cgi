#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;
use lib '/var/www/perl';
use Workers;

my $webapp = Workers->new(TMPL_PATH => '../templates');
$webapp->run();

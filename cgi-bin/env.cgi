#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;
use Cwd;
# use English;

print <<'END_OF_HEAD';
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Environments</title>
    </head>
    <body>
        <h1>Environments</h1>
        <h2>%ENV</h2>
END_OF_HEAD

foreach my $key (keys(%ENV)) {
    my $value = $ENV{$key};
    print "<p>$key=$value</p>\n";
}

print '<h2>@INC</2>';
print "\n@INC\n";

print "<h2>Cwd</h2>\n";
print Cwd::cwd();

print "\n<h2>abs_path</h2>\n";
print Cwd::abs_path();

print <<'END_OF_TAIL';
    </body>
</html>
END_OF_TAIL

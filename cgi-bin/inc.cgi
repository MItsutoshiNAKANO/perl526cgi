#! /usr/bin/env perl

use v5.26.3;
use strict;
use warnings;
use utf8;

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
END_OF_HEAD

print "@INC\n";

print <<'END_OF_TAIL';
    </body>
</html>
END_OF_TAIL

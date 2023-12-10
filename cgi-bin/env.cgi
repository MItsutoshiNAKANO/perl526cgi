#! /usr/bin/env perl

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

foreach my $key (keys(%ENV)) {
    my $value = $ENV{$key};
    print "<p>$key=$value</p>\n";
}

print <<'END_OF_TAIL';
    </body>
</html>
END_OF_TAIL

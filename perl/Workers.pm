=pod

=encoding utf8

=head1 NAME

Workers

=head1 MEMBERS

=cut
package Workers;

use 5.26.3;
use strict;
use warnings;
use Carp qw(cluck);
use utf8;
use base qw(CGI::Application);
use DBI;
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use Scalar::Util qw(reftype); 

__PACKAGE__->authen->config(
      DRIVER => [ 'Generic', { user1 => '123' } ],
      STORE => 'Session'
);

__PACKAGE__->authen->protected_runmodes(qr/^auth_/);

our $our_dbh;

=pod

=head2 my $dbh = __PACKAGE__->connect_db 

=cut
sub connect_db() {
    if ($our_dbh) { return $our_dbh }
    my $dbname = $ENV{PGDATABASE} || 'vagrant';
    my $connection_string = "dbi:Pg:dbname=$dbname";
    my $dbuser = $ENV{PGUSER} || 'apache';
    my $dbpassword = $ENV{PGPASSWORD} || 'vagrant';
    return $our_dbh = DBI->connect($connection_string, $dbuser, $dbpassword);
}

=pod

=head2 $self->setup()

=cut
sub setup($) {
    my $self = shift;
    $self->start_mode('auth_workers');
    $self->mode_param('rm');
    $self->run_modes([
        'auth_workers', 'auth_add', 'auth_do_add',
        'auth_update', 'auth_do_update', 'auth_delete',
        'auth_dump', 'auth_self', 'dump_html']);
    binmode STDIN, ':utf8';
    binmode STDOUT, ':utf8';
    binmode STDERR, ':utf8';
    $self->header_props(-charset => 'UTF-8');
}

=pod

=head2 my $html_string = $self->list_workers(\@error_messages)

=cut
sub list_workers($$) {
    my $self = shift;
    my ($messages) = @_;
    my @errors = ();
    foreach my $message (@$messages) {
        my %tmp;
        $tmp{MESSAGE} = $message;
        push(@errors, \%tmp);
    }
    my $username = $self->authen->username;
    my $dbh = __PACKAGE__->connect_db;
    my $sth = $dbh->prepare_cached('
    SELECT worker_number, worker_name, worker_katakana, phone
    FROM workers
    WHERE account_id = ?
    ORDER BY worker_katakana');
    my $rv = $sth->execute($username);
    my @workers = ();
    while (my $row = $sth->fetchrow_arrayref) {
        my %tmp;
        $tmp{NUMBER} = $row->[0];
        utf8::decode($tmp{NUMBER});
        $tmp{NAME} = $row->[1];
        utf8::decode($tmp{NAME});
        $tmp{PHONE} = $row->[3];
        utf8::decode($tmp{PHONE});
        push(@workers, \%tmp);
    }
    my $template = $self->load_tmpl('workers.html', utf8 => 1);
    $template->param(AFFILIATION => $username);
    $template->param(ERRORS => \@errors);
    $template->param(WORKERS => \@workers);
    return $template->output;
}

=pod

=head2 my $html_string = $self->auth_workers # list workers

=cut
sub auth_workers($) {
    my $self = shift;
    return $self->list_workers([]);
}

=pod

=head2 my $html_string = $self->auth_delete # delete a worker

=cut
sub auth_delete($) {
    my $self = shift;
    my $q = $self->query;
    my $worker = $q->param('check');
    unless ($worker) {
        return $self->list_workers(['削除対象を選んでください。']);
    }
    my $username = $self->authen->username;
    my $dbh = __PACKAGE__->connect_db;
    my $sth = $dbh->prepare_cached('
    DELETE FROM workers WHERE account_id = ? AND worker_number = ?');
    my $rv = $sth->execute($username, $worker);
    return $self->list_workers([]);
}

=pod

=head2 my $edit_screen_html = $self->edit_worker($args)

=cut
sub edit_worker($$) {
    my $self = shift;
    my ($args) = @_;
    # warn $args;
    my $username = $self->authen->username;
    my $template = $self->load_tmpl('edit.html', utf8 => 1);
    $template->param(AFFILIATION => $username);
    $template->param(NEXT_ACTION => $args->{next_action});

    my @errors = ();
    foreach my $message (@{$args->{errors}}) {
        my %tmp;
        $tmp{MESSAGE} = $message;
        push(@errors, \%tmp); 
    }
    # utf8::encode($args->{worker});
    # utf8::encode($args->{kana});
    # utf8::encode($args->{phone});
    $template->param(ERRORS => \@errors);
    $template->param(NUMBER => $args->{number} || '');
    $template->param(WORKER => $args->{worker} || '');
    $template->param(KANA => $args->{kana} || '');
    $template->param(PHONE => $args->{phone} || '');
    return $template->output;
}

=pod

=head2 my $html_string = $self->auth_add # Show the screen to add a worker.

=cut
sub auth_add($) {
    my $self = shift;
    my $username = $self->authen->username;
    return $self->edit_worker({ next_action => 'auth_do_add' });
}

=pod

=head2 my %regulated = $self->regulate # regulate charactors.

=cut
sub regulate($) {
    my $self = shift;
    my $q = $self->query;
    my $worker = $q->param('worker');
    utf8::decode($worker);
    my $kana = $q->param('kana');
    utf8::decode($kana);
    my $phone = $q->param('phone');
    utf8::decode($phone);
    $worker =~ s/[　\s]+/ /g;
    $worker =~ tr/ｦｧｨｩｪｫｬｭｮｯ\ｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ\ﾞ\ﾟ/ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜/;
    $worker =~ s/^ +//;
    $worker =~ s/ +$//;
    $phone =~ s/[　\s]+/ /g;
    $phone =~ tr/０-９\ー\（\）\＋/0-9\-\(\)\+/;
    $phone =~ s/^ +//;
    $phone =~ s/ +$//;
    $kana =~ s/[　\s]+/ /g;
    $kana =~ tr/ｦｧｨｩｪｫｬｭｮｯ\ｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ\ﾞ\ﾟ/ヲァィゥェォャュョッーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜/;
    $kana =~ s/^ +//;
    $kana =~ s/ +$//;
    return (worker => $worker, kana => $kana, phone => $phone);
}

=pod

=head2 my @errors = $self->validate(%regulated) # Validate charactors.

=cut
sub validate($%) {
    my $self = shift;
    my (%regulated) = @_;
    my $worker = $regulated{worker};
    my $kana = $regulated{kana};
    my $phone = $regulated{phone};
    my @errors = ();
    unless ($worker and $kana and $phone) {
        push(@errors, '全て入力必須です。');
    }
    if ($kana =~ m/([^ヲァィゥェォャュョッ\ーアイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワン゛゜ガギグゲゴザジズゼゾダヂヅデドバビブベボパピプペポ ]+)/) {
        push(@errors, "カタカナ欄の「$1」は不正な文字です。");
    }
    if ($phone =~ m/([^\d \-\(\)\+]+)/) {
        push(@errors, "電話番号欄の「$1」は不正な文字です。");
    }
    return @errors;
}

=pod

=head2 $html_string = $self->auth_do_add # Add a worker.

=cut
sub auth_do_add($) {
    my $self = shift;
    my %regulated = $self->regulate;
    my $worker = $regulated{worker};
    # utf8::encode($worker);
    my $kana = $regulated{kana};
    # utf8::encode($kana);
    my $phone = $regulated{phone};
    # utf8::encode($phone);
    if (my @errors = $self->validate(%regulated)) {
        return $self->edit_worker({
            errors => \@errors, next_action => 'auth_do_add',
            worker => $worker, kana => $kana, phone => $phone
        });
    }
    my $username = $self->authen->username;
    my $dbh = __PACKAGE__->connect_db;
    my $sth = $dbh->prepare_cached('
    INSERT INTO workers (
        worker_number,
        account_id, affiliation, abbreviation_for_affiliation,
        worker_name, worker_katakana, phone, creator, updater)
    SELECT
        COALESCE(MAX(worker_number), 0) + 1 AS worker_number,
        ? AS account_id, ? AS affiliation, ? AS abbreviation_for_affiliation,
        ? AS worker_name, ? AS worker_katakana, ? AS phone,
        ? AS creator, ? AS updater
    FROM workers WHERE account_id = ?'
    );
    my $rv = $sth->execute(
        $username, $username, $username, $worker, $kana, $phone,
        $username, $username, $username);
    return $self->list_workers;
}

=pod

=head2 my $html_string = $self->auth_update # Show the screen to edit a worker.

=cut
sub auth_update($) {
    my $self = shift;
    my $q = $self->query;
    my $worker_number = $q->param('check');
    unless ($worker_number) {
        return $self->list_workers(['変更対象を選んでください。']);
    }
    my $username = $self->authen->username;
    my $dbh = __PACKAGE__->connect_db;
    my $sth = $dbh->prepare_cached('
    SELECT worker_number, worker_name, worker_katakana, phone
    FROM workers WHERE account_id = ? AND worker_number = ?');
    my $rv = $sth->execute($username, $worker_number);
    my $row = $sth->fetchrow_arrayref;
    my ($worker_name, $kana, $phone) = ($row->[1], $row->[2], $row->[3]);
    utf8::decode($worker_name);
    utf8::decode($kana);
    utf8::decode($phone);
    return $self->edit_worker({
        next_action => 'auth_do_update', number => $worker_number,
        worker => $worker_name, kana => $kana, phone => $phone
    });
}

=pod

=head2 my $html_string = $self->auth_do_update # Update a worker.

=cut
sub auth_do_update($) {
    my $self = shift;
    my %regulated = $self->regulate;
    my $worker = $regulated{worker};
    # utf8::encode($worker);
    my $kana = $regulated{kana};
    # utf8::encode($kana);
    my $phone = $regulated{phone};
    # utf8::encode($phone);
    my $q = $self->query;
    my $number = $q->param('number');
    if (my @errors = $self->validate(%regulated)) {
        return $self->edit_worker({
            errors => \@errors, next_action => 'auth_do_update',
            number => $number,
            worker => $worker, kana => $kana, phone => $phone,
        });
    }
    my $username = $self->authen->username;
    my $dbh = __PACKAGE__->connect_db;
    # warn($worker, $kana, $phone, $username, $number, $username); 
    my $sth = $dbh->prepare_cached('
    UPDATE workers SET
        worker_name = ?, worker_katakana = ?, phone = ?, updater = ?,
        update_at = CURRENT_TIMESTAMP
    WHERE worker_number = ? AND account_id = ?');
    my $rv = $sth->execute(
        $worker, $kana, $phone, $username, $number, $username
    );
    return $self->list_workers([]);
}

=pod

=head2 $html_string = $self->auth_dump # dump to debug.

=cut
sub auth_dump($) {
    my $self = shift;
    return $self->dump_html();
}

sub auth_self($) {
    my $self = shift;
    my @results;
    foreach my $key (keys(%{$self})) {
        my $value = $self->{$key};
        my $type = reftype $value;
        if ($type eq 'SCALAR') {
            push(@results, '<p>', $key, '=', '\\', $$value, '</p>');
        } elsif ($type eq 'ARRAY') {
            push(@results, '<p>', $key, '=', '[', @$value ,']</p>');
        } elsif ($type eq 'HASH') {
            push(@results, '<p>', $key, '=', '{', %$value, '}</p>');
        } else {
            push(@results, '<p>', $key, '=', $value, '</p>');
        }
    }
    return "@results"
}

1;

__END__

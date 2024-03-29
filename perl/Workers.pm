package Workers;

use v5.26.3;
use strict;
use warnings;
use utf8;
use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use CGI::Session;
use URI::Escape;
use Cwd;
use TOML::Tiny;
use DBI;
use Scalar::Util qw(reftype); 
use Mojo::Log;
use Email::Stuffer;
use lib '/var/www/perl';
use Mtp;
use WorkerValidator;

=encoding utf8

=head1 NAME

Workers - List & Edit workers.

=head1 SYNOPSIS

  use lib '/var/www/perl';
  use Workers;

  my $webapp = Workers->new();
  $webapp->run();

=head1 DESCRIPTION

=cut

__PACKAGE__->authen->config(
      DRIVER => [ 'Generic', { user1 => '123' } ], STORE => 'Session'
);

__PACKAGE__->authen->protected_runmodes(qr/^auth_/);

=head2 my $config = $self->load_config($file_name); # Load config.

=head3 See Also

=over 4

=item * @see https://metacpan.org/pod/TOML::Tiny

=back

=cut

sub load_config($$) {
    my ($self, $file_name) = @_;
    open(TOML, '<:utf8', $file_name) or die("Not found $file_name");
    my $toml = do { local $/; <TOML> };
    close(TOML);
    my $parser = TOML::Tiny->new();
    my $hash_ref = $parser->decode($toml);
    return $hash_ref;
}

=head2 $b = $self->send_mail($subject, $text, $params);

=cut

sub send_mail($$$$) {
    my ($self, $subject, $text, $params) = @_;
    defined($subject) or die('must set: subject');
    defined($text) or die('must set: body');
    my $mtp_params = $self->{config}->{Mtp}
    or die('Undefined parameter: Mtp');
    my $mtp = Mtp->new($mtp_params);
    my $sender = $mtp->sender();
    my $mail = $self->{config}->{mail} or die('Undefined parameter: mail');
    my $from = $mail->{from} or die('Undefined parameter: mail.from');
    my $to_ref = $mail->{to} or die('Undefined parameter: mail.to');
    my (@to) = @$to_ref;

    my $stuffer = Email::Stuffer->transport($sender)
    ->from($from)->subject($subject)->text_body($text);
    if ($params->{to}) {
        my @additional = reftype($params->{to})
        ? @{$params->{to}} : $params->{to};
        push(@to, @additional);
    }
    $stuffer = $stuffer->to(@to);
    if ($params->{cc}) {
        my @cc = reftype($params->{cc}) ? @{$params->{cc}} : $params->{cc};
        $stuffer = $stuffer->cc(@cc);
    }
    if ($params->{bcc}) {
        my @bcc = reftype($params->{bcc})
        ? @{$params->{bcc}} : $params->{bcc};
        $stuffer = $stuffer->bcc(@bcc);
    }
    return $stuffer->send;
}

=head2 $self->test_mail(); # Send test mail.

=cut

sub test_mail($) {
    my $self = shift;
    $self->send_mail('テスト', "本文1\n本文2") or die('fail $!');
    return "<h1>done</h1>";
}

=head2 my $data_source = _get_default_datasource();

=cut

sub _get_default_datasource() {
    my $dbname = $ENV{PGDATABASE} || 'vagrant';
    return "dbi:Pg:dbname=$dbname";
}

=head2 $self->_connect(); # Connect to DB.

=cut

sub _connect($$) {
    my ($self, $parameters) = @_;
    my ($data_source, $user, $pass, $attr) = @$parameters;
    my $db_data_source = $data_source || _get_default_datasource();
    my $dbuser = $user || $ENV{PGUSER} || 'apache';
    my $dbpassword = $pass || $ENV{PGPASSWORD} || 'vagrant';
    my $db_attr = $attr || { AutoCommit => 0 };
    return $self->{dbh} = DBI->connect(
        $db_data_source, $dbuser, $dbpassword, $db_attr
    );
}

=head2 my ($err, $errstr, $state) = errinf($db_handle);

Get error information.

=cut

sub errinf($) {
    my ($h) = @_;
    return ($h->err, $h->errstr, $h->state);
}

=head2 $self->setup(); # Setup this class.

=head3 See Also

=over 4

=item * CGI::Application(3p)

=back

=cut

sub setup($) {
    my $self = shift;
    $self->start_mode('auth_enter');
    $self->mode_param('rm');
    $self->run_modes([
        'auth_enter', 'auth_reflect', 'auth_return', 'auth_workers',
        'auth_add', 'auth_do_add', 'auth_update', 'auth_do_update',
        'auth_delete',
        'auth_dump', 'auth_self', 'dump_html', 'test_mail'
    ]);
    binmode(STDIN, ':utf8');
    binmode(STDOUT, ':utf8');
    binmode(STDERR, ':utf8');
    my $config = $self->load_config(
        $ENV{WORKERS_CONF_FILE_PATH} || '../etc/Workers.toml'
    );
    foreach my $key (keys(%{$config})) {
        my $file_path = $config->{$key}->{include};
        if (defined($file_path) && !reftype($file_path)) {
            $config->{$key} = $self->load_config($file_path);
        }
    }

    my $toml = to_toml($config);
    # warn($toml); # DEBUG config format.
    my $log = $self->{log} = Mojo::Log->new($config->{Log});
    $log->trace($toml);
    $self->_connect($config->{DBI}->{connect})
    or $log->fatal(errinf(qw(DBI)));
    $self->tmpl_path($config->{Application}->{tmpl_path} || '../templates');
    $self->header_props(
        $config->{Application}->{header_props} || { -charset => 'UTF-8' }
    );
    $self->{config} = $config;
}

=head2 $self->teardown() # Tear down.

=cut

sub teardown($) {
    my $self = shift;
    $self->{dbh}->commit();
    $self->{dbh}->disconnect();
}

=head2 my $sth = $self->prepare($statement); # Prepare a statement.

=cut

sub prepare($$) {
    my ($self, $statement) = @_;
    my ($dbh, $log) = ($self->{dbh}, $self->{log});
    $statement =~ s/\s+/ /g;
    $log->info($statement);
    my $sth = $dbh->prepare($statement) or $log->error(errinf($dbh));
    return $sth;
}

=head2 my $rv = $self->execute($sth, @params); # Execute DB statement.

=cut

sub execute($$@) {
    my ($self, $sth, @params) = @_;
    $self->{log}->info(@params);
    my $rv = $sth->execute(@params) or $self->{log}->error(errinf($sth));
    return $rv;
}

=head2 my $session = $self->get_my_session(); # Get my session object.

=cut

sub get_my_session($) {
    my $self = shift;
    my $q = $self->query();
    CGI::Session->name('workers');
    my $session = CGI::Session->new() or die CGI::Session->errstr();
    $self->{log}->debug($session->name(), $session->id());
    my $cookie = $q->cookie(
        -name => $session->name(), -value => $session->id()
    );
    $self->header_add(-cookie => [$cookie]);
    return $session;
}

=head2 $self->auth_return($); # Back to driver.cgi.

=cut

sub auth_return($) {
    my $self = shift;
    my $session = $self->get_my_session();
    my @params = ();
    foreach my $key ('worker', 'phone', 'remark') {
        my $value = $session->param($key);
        utf8::decode($value);
        my $encoded = uri_escape_utf8($value);
        push(@params, "$key=$encoded");
    }
    $self->header_type('redirect');
    $self->header_props(-url => "driver.cgi?" . join('&', @params));
}

=head2 $self->auth_reflect(); # Jump & refrect name.

=cut

sub auth_reflect($) {
    my $self = shift;
    my $q = $self->query();

    my $worker_number = $q->param('check');
    unless ($worker_number) {
        return $self->list_workers(['対象を選んでください。']);
    }
    my $username = $self->authen->username;
    my $sth = $self->prepare(q{
        SELECT worker_number, worker_name, phone
        FROM workers WHERE account_id = ? AND worker_number = ?
    });
    my $rv = $self->execute($sth, $username, $worker_number);
    my $row = $sth->fetchrow_arrayref();
    my ($worker, $phone) = ($row->[1], $row->[2]);
    utf8::decode($worker);
    utf8::decode($phone);

    my $session = $self->get_my_session();
    my $remark = $session->param('remark');
    utf8::decode($remark);
 
    my $enc_worker = uri_escape_utf8($worker);
    my $enc_phone = uri_escape_utf8($phone);
    my $enc_remark = uri_escape_utf8($remark);

    $self->header_type('redirect');
    $self->header_props(
        -url =>
        "driver.cgi?worker=$enc_worker&phone=$enc_phone&remark=$enc_remark"
    );
}

=head2 $html_string = $self->list_workers(\@error_messages); # List.

=cut

sub list_workers($$) {
    my ($self, $messages) = @_;
    my @errors = ();
    foreach my $message (@$messages) {
        my %tmp;
        $tmp{MESSAGE} = $message;
        push(@errors, \%tmp);
    }
    my $username = $self->authen->username;
    my $sth = $self->prepare(q{
        SELECT worker_number, worker_name, worker_katakana, phone
        FROM workers WHERE account_id = ?
        ORDER BY worker_katakana, worker_number
    });
    my $rv = $self->execute($sth, $username);
    my @workers = ();
    while (my $row = $sth->fetchrow_arrayref()) {
        my %tmp;
        $tmp{NUMBER} = $row->[0];
        utf8::decode($tmp{NUMBER});
        $tmp{NAME} = $row->[1];
        utf8::decode($tmp{NAME});
        $tmp{KATAKANA} = $row->[2];
        utf8::decode($tmp{KATAKANA});
        $tmp{PHONE} = $row->[3];
        utf8::decode($tmp{PHONE});
        push(@workers, \%tmp);
    }
    my $template = $self->load_tmpl('workers.html', utf8 => 1);
    $template->param(AFFILIATION => $username);
    $template->param(ERRORS => \@errors);
    $template->param(WORKERS => \@workers);
    return
    # $self->dump_html() . # DEBUG
    $template->output();
}

=head2 $html_string = $self->auth_workers(); # List workers

=cut

sub auth_workers($) {
    my $self = shift;
    return $self->list_workers();
}

=head2 $html_string = $self->auth_enter(); # Enter from Driver.

=cut

sub auth_enter($) {
    my $self = shift;
    my $q = $self->query();
    my $session = $self->get_my_session();
    foreach my $key ('remark', 'worker', 'phone') {
        my $value = $q->param($key);
        utf8::decode($value);
        $self->{log}->debug($key, $value);
        $session->param($key, $value);
    }
    $session->flush();
    return $self->list_workers();
}

=head2 $html_string = $self->auth_delete(); # Delete a worker

=cut

sub auth_delete($) {
    my $self = shift;
    my $q = $self->query();
    my $worker = $q->param('check');
    unless ($worker) {
        return $self->list_workers(['削除対象を選んでください。']);
    }
    my $username = $self->authen->username;
    my @messages = ();
    my $sth = $self->prepare(q{
        DELETE FROM workers WHERE account_id = ? AND worker_number = ?
    }) or return $self->list_workers([
        'failed to prepare deleting', errinf($self->{dbh})
    ]);
    my $rv = $self->execute($sth, $username, $worker)
    or return $self->list_workers(['failed to DELETE', errinf($sth)]);
    return $self->list_workers();
}

=head2 $edit_screen_html = $self->edit_worker($args); # Show the editor.

=cut

sub edit_worker($$) {
    my ($self, $args) = @_;
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
    $template->param(ERRORS => \@errors);
    $template->param(NUMBER => $args->{number} || '');
    $template->param(WORKER => $args->{worker} || '');
    $template->param(KANA => $args->{kana} || '');
    $template->param(PHONE => $args->{phone} || '');
    return $template->output();
}

=head2 $html_string = $self->auth_add(); # Show the adding screen.

=cut

sub auth_add($) {
    my $self = shift;
    return $self->edit_worker({ next_action => 'auth_do_add' });
}

=head2 my $errors = $self->duplicate($regulated);

Tell errors if it is duplicated.

=cut

sub duplicate($$) {
    my $self = shift;
    my ($regulated) = @_;
    my $worker = $regulated->{worker};
    my $kana = $regulated->{kana};
    my $phone = $regulated->{phone};
    my $username = $self->authen->username;
    my @errors = ();
    my $sth = $self->prepare(q{
        SELECT worker_number FROM workers
        WHERE account_id = ? AND worker_name = ?
        AND worker_katakana = ? AND phone = ?
    });
    $self->execute($sth, $username, $worker, $kana, $phone);
    if ($sth->fetchrow_arrayref()) { push(@errors, '既に登録済みです。') }
    return [@errors];
}

sub get_regulated_params($$) {
    my $self = shift;
    my $validator = shift;
    my $q = $self->query();
    my $worker = $q->param('worker');
    my $kana = $q->param('kana');
    my $phone = $q->param('phone');
    return $validator->regulate({
        worker => $worker, kana => $kana, phone => $phone
    });
}

=head2 $html_string = $self->auth_do_add(); # Add a worker.

=cut

sub auth_do_add($) {
    my $self = shift;
    my $validator = WorkerValidator->new();
    my $regulated = $self->get_regulated_params($validator);
    my $worker = $regulated->{worker};
    my $kana = $regulated->{kana};
    my $phone = $regulated->{phone};
    my @validate_errors = $validator->validate($regulated);
    if (@validate_errors) {
        my @messages = $validator->get_ja_messages(\@validate_errors);
        return $self->edit_worker({
            errors => \@messages, next_action => 'auth_do_add',
            worker => $worker, kana => $kana, phone => $phone
        });
    }
    my $duplicate_errors = $self->duplicate($regulated);
    if (@$duplicate_errors) {
        return $self->edit_worker({
            errors => $duplicate_errors, next_action => 'auth_do_add',
            worker => $worker, kana => $kana, phone => $phone
        });
    }
    my $username = $self->authen->username;
    my $sth = $self->prepare(q{
        INSERT INTO workers (
            worker_number,
            account_id, affiliation, abbreviation_for_affiliation,
            worker_name, worker_katakana, phone, creator, updater
        ) SELECT
            COALESCE(MAX(worker_number), 0) + 1 AS worker_number,
            ? AS account_id, ? AS affiliation,
            ? AS abbreviation_for_affiliation,
            ? AS worker_name, ? AS worker_katakana, ? AS phone,
            ? AS creator, ? AS updater
        FROM workers WHERE account_id = ?
    }) or return $self->list_workers([
        'failed to prepare inserting', errinf($self->{dbh})
    ]);
    my $rv = $self->execute(
        $sth, $username, $username, $username, $worker, $kana, $phone,
        $username, $username, $username
    ) or return $self->list_workers(['failed to INSERT', errinf($sth)]);
    return $self->list_workers();
}

=head2 $html_string = $self->auth_update(); # Show the modify screen.

=cut

sub auth_update($) {
    my $self = shift;
    my $q = $self->query();
    my $worker_number = $q->param('check');
    unless ($worker_number) {
        return $self->list_workers(['変更対象を選んでください。']);
    }
    my $username = $self->authen->username;
    my $sth = $self->prepare(q{
        SELECT worker_number, worker_name, worker_katakana, phone
        FROM workers WHERE account_id = ? AND worker_number = ?
    }) or return $self->list_workers([
        'failed to prepare selecting', errinf($self->{dbh})
    ]);
    my $rv = $self->execute($sth, $username, $worker_number)
    or return $self->list_workers(['failed to SELECT', errinf($sth)]);
    my $row = $sth->fetchrow_arrayref or return $self->list_workers([
        'failed to fetch', errinf($sth)
    ]);
    my ($worker_name, $kana, $phone) = ($row->[1], $row->[2], $row->[3]);
    utf8::decode($worker_name);
    utf8::decode($kana);
    utf8::decode($phone);
    return $self->edit_worker({
        next_action => 'auth_do_update', number => $worker_number,
        worker => $worker_name, kana => $kana, phone => $phone
    });
}

=head2 $html_string = $self->auth_do_update(); # Update a worker.

=cut

sub auth_do_update($) {
    my $self = shift;
    my $validator = WorkerValidator->new();
    my $regulated = $self->get_regulated_params($validator);
    my $worker = $regulated->{worker};
    my $kana = $regulated->{kana};
    my $phone = $regulated->{phone};
    my $q = $self->query();
    my $number = $q->param('number');
    my @validate_errors = $self->validate($regulated);
    if (@validate_errors) {
        my @messages = $validator->get_ja_messages(\@validate_errors);
        return $self->edit_worker({
            errors => \@messages, next_action => 'auth_do_update',
            number => $number,
            worker => $worker, kana => $kana, phone => $phone
        });
    }
    my $username = $self->authen->username;
    # warn($worker, $kana, $phone, $username, $number, $username); 
    my $sth = $self->prepare(q{
        UPDATE workers SET
            worker_name = ?, worker_katakana = ?, phone = ?, updater = ?,
            update_at = CURRENT_TIMESTAMP
        WHERE worker_number = ? AND account_id = ?
    }) or return $self->list_workers([
        'failed to prepare updating', errinf($self->{dbh})
    ]);
    my $rv = $self->execute(
        $sth, $worker, $kana, $phone, $username, $number, $username
    ) or return $self->list_workers(['failed to UPDATE', errinf($sth)]);
    return $self->list_workers();
}

=head2 $html_string = $self->auth_dump(); # Dump to debug.

=cut

sub auth_dump($) {
    my $self = shift;
    return $self->dump_html();
}

=head2 $html_string = $self->auth_self(); # Dump to debug.

=cut

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
        } else { push(@results, '<p>', $key, '=', $value, '</p>'); }
    }
    return "@results"
}

1;

__END__

=head1 TODO

  * [x] Config file.
  * [x] Mail.
  * [ ] 画面error messagesのstyle指定機能.
  * [ ] Error messagesのtoml file化.
  * [x] UPDATE時check duplication error.
  * [ ] Testable.

=head1 SEE ALSO

=over 4

=item * CGI::Application::Plugin::Authentication(3p)

=item * CGI::Application(3p)

=back

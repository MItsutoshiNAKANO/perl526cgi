package MailSender;

use v5.26.3;
use strict;
use warnings;
use utf8;
use Scalar::Util qw(reftype);
use TOML::Tiny;
use Net::SMTP;

=encoding utf8

=head1 NAME

MailSender - Interface to send mails.

=head1 SYNOPSIS

  use MailSender;
  my $mail = MailSender->new($conf, $log);

=head1 DESCRIPTION

=cut

=head2 my $config = $self->_load_config($file_name); # Load config.

=head3 See Also

=over 4

=item * @see https://metacpan.org/pod/TOML::Tiny

=back

=cut

sub _load_config($$) {
    my ($self, $file_name) = @_;
    open(TOML, '<:utf8', $file_name) or die("Couldn't read:", $file_name);
    my $toml = do { local $/; <TOML> };
    close(TOML);
    my $parser = TOML::Tiny->new();
    return $parser->decode($toml);
}

=head2 my $smtp = $self->_connect() or die($@);

=cut

sub _connect($) {
    my $self = shift;
    my $params = $self->{config}->{connect};
    $self->{log}->trace("Net::SMTP->new($params)") if $self->{log};
    return Net::SMTP->new(%{$params});
}

=head2 $self->_auth($smtp) or $smtp->quit(); # SMTP Auth.

=cut

sub _auth($$) {
    my ($self, $smtp) = @_;
    my $params = $self->{config}->{auth};
    unless ($params) { return 1; }
    my $user = $params->{username};
    my $password = $params->{password};
    $self->{log}->trace("Net::SMTP->auth($user)") if $self->{log};
    return $smtp->auth($user, $password);
}

=head2 $self->_set_from($smtp); # Set the sender & options.

=cut

sub _set_from($$) {
    my ($self, $smtp) = @_;
    my $mail_params = $self->{config}->{mail};
    my $sender = $mail_params->{address};
    my $options = $mail_params->{options};
    $self->{log}->trace("Net::SMTP->mail($sender)") if $self->{log};
    return $smtp->mail($sender, $options && %{$options});
}

=head2 $b = $self->_set_to_smtp($smtp, $additional_address_list_ref);

=cut

sub _set_to($$$) {
    my ($self, $smtp, $additional_recipients) = @_;
    my $params = $self->{config}->{recipient};
    my $default_recipients = $params->{recipients};
    my @recipients = @{$default_recipients};
    push(@recipients, @{$additional_recipients}) if $additional_recipients;
    my $options = $params->{options};
    $self->{log}->trace("Net::SMTP->recipient(@recipients)") if $self->{log};
    return $options ? $smtp->recipient(@recipients, %{$options})
    : $smtp->recipient(@recipients);
}

=head2 $b = $self->send($data_array_ref, $additional_recipients);

=cut

sub send($$$) {
    my ($self, $data_ref, $additional_recipients) = @_;
    my $smtp = $self->_connect();
    unless ($smtp) {
        $self->{log}->error('connect_smtp():', $@) if $self->{log};
        return undef;
    }
    unless (
        $self->_auth($smtp) && $self->_set_from($smtp)
        && $self->_set_to($smtp, $additional_recipients)
    ) {
        $self->{log}->error('send(): failed prepare', $smtp->message())
        if $self->{log};
        $smtp->quit();
        return undef;
    }
    my $from = $self->{config}->{mail}->{address};
    my $to_ref = $self->{config}->{recipient}->{recipients};
    my $to = join(', ', @{$to_ref});
    my (@data) = ("From: $from\n", "To: $to\n", @{$data_ref});
    map(utf8::decode($_), @data);
    unless ($smtp->data(@data)) {
        if ($self->{log}) {
            $self->{log}->trace(@data);
            $self->{log}->error("data():", $smtp->message());
        }
        $smtp->quit();
        return undef;
    }
    my $results = $smtp->dataend();
    if (!$results && $self->{log}) {
        $self->{log}->trace(@data);
        $self->{log}->error("dataend():", $smtp->message());
    }
    $smtp->quit();
    return $results;
}

=head2 $self->test_mail(); # Send test mail.

=cut

sub _test($) {
    my $self = shift;
    my $data = [ "Subject: test\n", "\n", "test\n" ];
    if ($self->send($data)) { return 'OK' } else { return undef }
}

=head2 my $mail = MailSender->new($conf, $log); # Constructor.

=head3 Arguments

=over 4

=item * $conf # Configration file name or hash reference.

=item * $log # Optional log object.

=back

=cut

sub new($$$) {
    my $class = shift;
    my $arg = shift;
    my $log = shift;
    my $self = {};
    bless $self, $class;
    $self->{config} = reftype($arg) ? $arg : $self->_load_config($arg);
    $self->{log} = $log;
    return $self;
}

1;

__END__

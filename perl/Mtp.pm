package Mtp;

use v5.26.3;
use strict;
use warnings;
use utf8;
use Scalar::Util qw(reftype);
use TOML::Tiny;
use Email::Sender::Transport::SMTP;

sub _load($$) {
    my ($self, $file) = @_;
    open(TOML, '<:utf8', $file) or die("Couldn't read: $file: $!");
    my $toml = do { local $/; <TOML> };
    close(TOML);
    my $parser = TOML::Tiny->new();
    return $parser->decode($toml);
}

sub sender($) {
    my $self = shift;
    return $self->{_sender};
}

sub new($$) {
    my ($class, $arg) = @_;
    my $self = {};
    bless($self, $class);
    unless (defined($arg)) { $arg = '../secrets/Mtp.toml' }
    my $config = reftype($arg) ? $arg : $self->_load($arg);
    $self->{_sender} = Email::Sender::Transport::SMTP->new($config->{new});
    return $self;
}

1;

__END__

=head1 NAME

Mtp - Mail Transport Protocol Wrapper.

=head1 SYNOPSIS

  use Email::Stuffer;
  ues lib '/var/www/perl';
  use Mtp;
  my $mtp = Mtp->new();
  my $sender = $mtp->sender();
  Email::Stuffer->transport($sender)
  ->from('postmaster@example.com')->to('postmaster@example.org')
  ->subject('test')->text_body('test')->send or die;

=head1 DESCRIPTION

=head2 my $mtp = Mtp->new($arg) # Constructor.

=head3 Arguments: $arg # The other TOML file or a hash reference.

Default: '../secrets/Mtp.toml'

=head2 my $sender = $mtp->sender(); # Get the sender.

=head1 SEE ALSO

=over 4

=item * https://metacpan.org/pod/Email::Sender::Transport::SMTP

=item * https://metacpan.org/pod/Email::Sender::Manual::QuickStart

=item * https://metacpan.org/pod/TOML::Tiny

=item * https://toml.io/en/v1.0.0

=item * https://metacpan.org/pod/Email::Stuffer

=back

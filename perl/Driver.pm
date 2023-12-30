=pod

=encoding utf8

=head1 NAME

Driver

=head1 MEMBERS

=cut
package Driver;

use 5.26.3;
use strict;
use warnings;
use Carp qw(cluck);
use utf8;
use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;
use Scalar::Util qw(reftype); 

__PACKAGE__->authen->config(
      DRIVER => [ 'Generic', { user1 => '123' } ],
      STORE => 'Session'
);

__PACKAGE__->authen->protected_runmodes(qr/^auth_/);

=pod

=head2 $self->setup()

=cut
sub setup($) {
    my $self = shift;
    $self->start_mode('auth_driver');
    $self->mode_param('rm');
    $self->run_modes(['auth_driver',
    'auth_dump', 'auth_self', 'dump_html']);
    binmode STDIN, ':utf8';
    binmode STDOUT, ':utf8';
    binmode STDERR, ':utf8';
    $self->header_props(-charset => 'UTF-8');
}

sub auth_driver($) {
    my $self = shift;
    my $q = $self->query();
    my $name = $q->param('name') || '';
    utf8::decode($name);
    my $phone = $q->param('phone') || '';
    utf8::decode($phone);
    my $template = $self->load_tmpl('driver.html', utf8 => 1);
    $template->param(WORKER => $name);
    $template->param(PHONE => $phone);
    return $template->output;
}

=pod

=head2 $html_string = $self->auth_dump # dump to debug.

=cut
sub auth_dump($) {
    my $self = shift;
    return $self->dump_html;
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

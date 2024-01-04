package ListEnv;

use v5.26.3;
use strict;
use warnings;
use utf8;

use base qw(CGI::Application);
use HTML::Template;

sub setup($) {
    my $self = shift;
    $self->header_props(-type => 'text/html; charset=UTF-8');
    $self->start_mode('list_names') unless $self->get_current_runmode;
    $self->mode_param('rm');
    $self->run_modes(['list_names']);
}

sub list_names($) {
    my $self = shift;
    my @names = ();
    foreach my $key (keys(%ENV)) {
        my %tmp;
        $tmp{name} = $key;
        $tmp{value} = $ENV{$key};
        push(@names, \%tmp);
    }
    my $template = $self->load_tmpl('list_names.tmpl', utf8 => 1);
    $template->param(LANG => 'ja');
    $template->param(TITLE => '選択');
    $template->param(NAMES => \@names);
    return $template->output;
}

1;

__END__

=encoding utf8

=head1 NAME

ListEnv - List Environment.

=head1 SEE ALSO

 * <https://metacpan.org/pod/CGI::Application>

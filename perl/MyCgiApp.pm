package MyCgiApp;
 
use base qw(CGI::Application);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::Authentication;

sub setup {
      my $self = shift;
      $self->start_mode('mode1');
      $self->mode_param('rm');
      $self->run_modes(['mode1']);
}

MyCgiApp->authen->config(
      DRIVER => [ 'Generic', { user1 => '123' } ],
      STORE => 'Session'
);

MyCgiApp->authen->protected_runmodes('mode1');

sub mode1 {
    my $self = shift;

    # The user should be logged in if we got here
    my $username = $self->authen->username;

    my @names = ();
    foreach my $key (keys(%ENV)) {
        my %tmp;
        $tmp{name} = $key;
        $tmp{value} = $ENV{$key};
        push(@names, \%tmp);
    }
    my $template = $self->load_tmpl('list_names.tmpl', utf8 => 1);
    $template->param(LANG => 'ja');
    $template->param(TITLE => $username);
    $template->param(NAMES => \@names);
    return $template->output;

}

1;

__END__

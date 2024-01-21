package WorkerValidator;
use v5.26.3;
use strict;
use warnings;
use utf8;
use Encode;
use Jcode;

sub new($) {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub regulate_string($$) {
    my $self = shift;
    my $str = shift;
    utf8::decode($str);
    $str =~ s{[\s　]+}{ }g;
    $str =~ s{^[\s　]+}{}g;
    $str =~ s{[\s　]+$}{}g;
    $str =~ tr
    {０-９Ａ-Ｚａ-ｚ\＋\ー\（\）}
    {0-9A-Za-z\+\-\(\)};
    my $j = Jcode->new($str);
    my $regulated = $j->h2z()->utf8();
    utf8::decode($regulated);
    return $regulated;
}

sub regulate($$) {
    my $self = shift;
    my $target = shift;
    foreach my $key (keys(%$target)) {
        $target->{$key} = $self->regulate_string($target->{$key});
    }
    return $target;
}

sub validate($$) {
    my $self = shift;
    my $target = shift;
    my @results;
    my $name = $target->{worker};
    unless ($name) {
        push(@results, {
            key => 'name', reason => 'required', detail => $name
        });
        return @results;
    }
    if ((my $name_length = length(Encode::encode('utf8', $name))) > 126) {
        push(@results, {
            key => 'name', reason => 'over 126 byte', detail => $name_length,
            limit => 126
        });
    }

    my $kana = $target->{kana};
    unless ($kana) {
        push(@results, {
            key => 'kana', reason => 'required', detail => $kana
        });
        return @results;
    }
    if ($kana =~ m{([^ ゛゜ァ-ヺ]+)}) {
        push(@results, {
            key => 'kana', reason => 'invalid charactors', detail => $1
        });
    }
    if ((my $kana_length = length(Encode::encode('utf8', $kana))) > 126) {
        push(@results, {
            key => 'kana', reason => 'over 126 byte', detail => $kana_length,
            limit => 126
        });
    }

    my $phone = $target->{phone};
    unless ($phone) {
        push(@results, {
            key => 'phone', reason => 'required', detail => $phone
        });
        return @results;
    }
    if ($phone =~ m{([^\d \+\-\(\)]+)}) {
        push(@results, {
            key => 'phone', reason => 'invalid charactors', detail => $1
        });
    }
    if ((my $phone_length = length($phone)) > 30) {
        push(@results, {
            key => 'phone', reason => 'over 30 byte', detail => $phone_length,
            limit => 30
        });
    }

    return @results;
}

sub get_ja_message($$) {
    my $self = shift;
    my $message = shift;
    my @ja;
    my $key = $message->{key};
    if ($key eq 'name') { push(@ja, '名前') }
    elsif ($key eq 'kana') { push(@ja, 'カナ') }
    elsif ($key eq 'phone') { push(@ja, '電話') }
    else { push(@ja, $message->{key}) }
    my $reason = $message->{reason};
    if ($reason eq 'required') { push(@ja, 'は必須です。') }
    if ($reason eq 'invalid charactors') {
        push(@ja, sprintf('「%s」は不正な文字列です。', $message->{detail}));
    }
    if ($reason =~ m{^over \d+ byte}) {
        push(@ja, sprintf(
            'が%d byteを超えています(現在%d byte)。',
            $message->{limit}, $message->{detail}));
    }
    return join('', @ja);
}

sub get_ja_messages($\@) {
    my $self = shift;
    my $ref = shift;
    my @messages = @$ref;
    return map($self->get_ja_message($_), @messages);
}

1;

__END__

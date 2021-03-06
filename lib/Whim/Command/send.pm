package Whim::Command::send;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

use Whim::Mention;
use Try::Tiny;

has description => 'Send webmentions';
has usage       => sub { shift->extract_usage };

sub run {
    my ( $self, $source, $target ) = @_;

    $source = check_argument( source => $source );

    $target = check_argument( target => $target ) if defined $target;

    if ( defined $target ) {
        return $self->_send_one_wm( $source, $target );
    }
    else {
        return $self->_send_many_wms($source);
    }
}

sub _send_one_wm ( $self, $source, $target ) {

    my $wm = Whim::Mention->new( { source => $source, target => $target } );

    my $success = $wm->send;

    if ($success) {
        say "Webmention sent.";
    }
    else {
        say "No webmention sent.";
    }
}

sub _send_many_wms ( $self, $source ) {

    my @wms;
    try {
        @wms = Whim::Mention->new_from_source($source);
    }
    catch {
        chomp;
        say "Cannot send any webmentions: $_";
    };

    my $success_count = 0;
    for my $wm (@wms) {
        if ( $wm->send ) {
            $success_count++;
        }
    }

    my $attempt_count = scalar(@wms);

    my $attempt_s = $attempt_count == 1 ? '' : 's';
    my $success_s = $success_count == 1 ? '' : 's';

    say "Sent $success_count webmention$success_s "
        . "(from $attempt_count attempt$attempt_s)";
}

sub check_argument ( $argument_name, $url_text ) {
    unless ( defined $url_text ) {
        die "Usage: $0 source-url [target-url]\n";
    }
    my $url = URI->new($url_text)
        or die
        "The argument for the $argument_name does not look like a valid "
        . "URL. (Got: $url_text)\n";

    return $url;
}

1;

=encoding utf8

=head1 NAME

Whim::Command::send - Send command

=head1 SYNOPSIS

  Usage: whim send [source-url] [target-url]

  Run with two arguments to send a single webmention with the given
  source and target URLs.

  Run with one argument to send webmentions to every valid target found
  within the content found at the given source URL.

=head1 DESCRIPTION

This command sends webmentions, as described above. It prints a short
description of what it did to standard output.

If called with one argument, it will attempt to load the content from
the given source URL, locate an C<h-entry> microformat with an
C<e-content> property, and then try to send webmentions to all linked
URLs found within.

=head1 SEE ALSO

L<whim>

=cut

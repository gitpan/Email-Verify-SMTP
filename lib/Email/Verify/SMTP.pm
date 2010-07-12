
package Email::Verify::SMTP;

use strict;
use warnings 'all';
use base 'Exporter';
use Net::Nslookup;
use IO::Socket::Telnet;
use Carp 'confess';

our @EXPORT = ('verify_email');
our $VERSION = '0.001';


sub verify_email
{
  my $email = shift;

  my (undef, $domain) = split /@/, $email;
  my ($mx) = nslookup(domain => $domain, type => "MX");
  my $t = IO::Socket::Telnet->new(
    PeerAddr => $mx,
    PeerPort => 25,
  ) or confess "Cannot open socket to '$mx': $!";

  my $res = eval {
    $t->send("helo hi\n");
    $t->recv(my $res, 4096) or die "Error: $!";

    $t->send(qq(mail from: <no-reply\@localhost>\n));
    $t->recv($res, 4096) or die "Error: $!";

    $t->send(qq(rcpt to: <$email>\n));
    $t->recv($res, 4096) or die "Error: $!";
    
    $res;
  };
  
  $t->close;
  confess $@ if $@;
  return $res =~ m/^250\b/;
}# end verify()

1;# return true:

=pod

=head1 NAME

Email::Verify::SMTP - Verify an email address by using SMTP.

=head1 SYNOPSIS

  use Email::Verify::SMTP;
  
  if( verify_email('foo@example.com') ) {
    # Email is valid
  }

=head1 DESCRIPTION

C<Email::Verify::Simple> is what I came with when I needed to verify several email 
addresses without actually sending them email.

To put that another way:

=over 4

B<This module verifies email addresses without actually sending email to them.>

=back

=head1 DEPENDENCIES

This module depends on the following:

=over 4

=item L<Net::Nslookup>

To discover the mail exchange servers for the email address provided.

=item L<IO::Socket::Telnet>

A nice socket interface to use, even if you're not using Telnet.

=back

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 LICENSE

This software is B<Free> software and may be used, copied and redistributed under
the same terms as perl itself.

=cut


# -*- mode: cperl -*-
#

package Tools;
use Moose::Role;


=head2 is_ascii

checks whether the argument is ASCII

returns 0 if it is and 1 if not

=cut


sub is_ascii {
  my ($self, $arg) = @_;
  if ( defined $arg && $arg ne '' &&
       $arg !~ /^[[:ascii:]]+$/ ) {
    return 1;
  } else {
    return 0;
  }
}

=head2 utf2lat

utf8 input (particularly cyrillic) to latin1 transliteration

=cut

sub utf2lat {
  my ($self, $to_translit) = @_;
  use utf8;
  use Text::Unidecode;
  # Catalyst provides utf8::encoded data! here we need them to
  # utf8::decode to make them suitable for unidecode, since it expects
  # utf8::decode input
  utf8::decode( $to_translit );
  my $a = unidecode( $to_translit );
  # remove non-alphas (like ' and `)
  $a =~ tr/a-zA-Z//cds;
  return $a;
}

sub is_int {
  my ($self, $arg) = @_;
  return $arg !~ /^\d+$/ ? 1 : 0;
}


=head2 pwdgen

Prepares with Digest::SHA1, password provided or autogenerated, to be
used as userPassword attribute value

Password generated (with Crypt::GeneratePassword) is a random
pronounceable word. The length of the returned word is 12 chars. It is
up to 3 numbers and special characters will occur in the password. It
is up to 4 characters will be upper case.

If no password provided, then it will be automatically generated.

Method returns hash with cleartext and ssha coded password.

=cut


sub pwdgen {
  my ( $self, $args ) = @_;
  my $pwdgen = {
		pwd => $args->{'pwd'},
		len => $args->{'len'} || 12,
		num => $args->{'num'} || 3,
		cap => $args->{'cap'} || 4,
		cnt => $args->{'cnt'} || 1,
		salt => $args->{'salt'} || '123456789',
		pronounceable => $args->{'pronounceable'} || 1,
	       };

  use Crypt::GeneratePassword qw(word word3 chars);

  if ( ! defined $pwdgen->{'pwd'} && defined $pwdgen->{'pronounceable'} ) {
    $pwdgen->{'pwd'} = word3( $pwdgen->{'len'},
			    $pwdgen->{'len'},
			    'en',
			    $pwdgen->{'num'},
			    $pwdgen->{'cap'}
			  );
  } elsif ( ! defined $pwdgen->{'pwd'} ) {
    $pwdgen->{'pwd'} = chars( $pwdgen->{'len'}, $pwdgen->{'len'} );
  }

  use Digest::SHA1;
  use MIME::Base64;
  my $sha1 = Digest::SHA1->new;
  $sha1->add( $pwdgen->{'pwd'}, $pwdgen->{'salt'} );

  return {
	  clear => $pwdgen->{'pwd'},
	  ssha => '{SSHA}' . encode_base64( $sha1->digest . $pwdgen->{'salt'}, '' )
	 };
}


=head2 file2var

read input file into the returned variable and set final message on results

=cut


sub file2var {
  my  ( $self, $file, $final_message ) = @_;
  local $/ = undef;
  open FILE, $file || do { push @{$final_message->{error}}, "Can not open $file: $!"; exit 1; };
  binmode FILE;
  my $file_in_var = <FILE>;
  close FILE || do { push @{$final_message->{error}}, "$!"; exit 1; };
  return $file_in_var;
}


=head2 cert_info

data taken, generally, from

openssl x509 -in target.crt -text -noout

=cut


sub cert_info {
  my ( $self, $args ) = @_;
  my $arg = {
	     cert => $args->{'cert'},
	    };

  use Crypt::X509;
  my $x509 = Crypt::X509->new( cert => join('', $arg->{cert}) );
  use POSIX qw(strftime);
  return {
	  'Subject' => join(',',@{$x509->Subject}),
	  'Issuer' => join(',',@{$x509->Issuer}),
	  'S/N' => $x509->serial,
	  'Not Before' => strftime ("%a %b %e %H:%M:%S %Y", localtime($x509->not_before)),
	  'Not  After' => strftime ("%a %b %e %H:%M:%S %Y", localtime( $x509->not_after)),
	  'error' => $x509->error ? sprintf('Error on parsing Certificate: %s', $x509->error) : undef,
	 };
}



=head2 fnorm

HFH field value normalizator. Input is casted to ARRAY if it is
SCALAR.

=cut


sub fnorm {
  my ( $self, $field ) = @_;
  my $field_arr;
  if ( ref( $field ) ne 'ARRAY' ) {
    push $field_arr, $field;
    return $field_arr;
  } else {
    return $field;
  }
}


=head2 macnorm

MAC address field value normalizator.

The standard (IEEE 802) format for printing MAC-48 addresses in
human-friendly form is six groups of two hexadecimal digits, separated
by hyphens (-) or colons (:), in transmission order
(e.g. 01-23-45-67-89-ab or 01:23:45:67:89:ab ) is casted to the twelve
hexadecimal digits without delimiter. For the examples above it will
look: 0123456789ab

=over

=item mac

MAC address to process

=item oct

regex pattern for group of two hexadecimal digits [0-9a-f]{2}

=item sep

pattern for acceptable separator [.:-]

=item dlm

delimiter for concatenation after splitting

=back

=cut


sub macnorm {
  my ( $self, $args ) = @_;
  my $arg = {
	     mac => lc($args->{mac}),
	     oct => $args->{oct} || '[0-9a-f]{2}',
	     sep => $args->{sep} || '[.:-]',
	     dlm => $args->{dlm} || '',
	    };
  if (( $arg->{mac} =~ /^$arg->{oct}($arg->{sep})$arg->{oct}($arg->{sep})$arg->{oct}($arg->{sep})$arg->{oct}($arg->{sep})$arg->{oct}($arg->{sep})$arg->{oct}$/ ) &&
      ($1 x 4 eq "$2$3$4$5$6")) {
    return join( $arg->{dlm}, split(/$arg->{sep}/, $arg->{mac}) );
  } elsif (( $arg->{mac} =~ /^$arg->{oct}$arg->{oct}$arg->{oct}$arg->{oct}$arg->{oct}$arg->{oct}$/ ) &&
	   ($1 x 4 eq "$2$3$4$5")) {
    my @mac_arr = split('', $arg->{mac});
    return join( $arg->{dlm},
		 "$mac_arr[0]$mac_arr[1]",
		 "$mac_arr[2]$mac_arr[3]",
		 "$mac_arr[4]$mac_arr[5]",
		 "$mac_arr[6]$mac_arr[7]",
		 "$mac_arr[8]$mac_arr[9]",
		 "$mac_arr[10]$mac_arr[11]" );
  } else {
    return 0;
  }
}


######################################################################

1;

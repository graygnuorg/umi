# -*- mode: cperl; mode: follow; -*-
#

package UMI::Controller::Onboarding;
use Moose;
use namespace::autoclean;

use Logger;
use Data::Printer;

BEGIN { extends 'Catalyst::Controller'; with 'Tools'; }

use UMI::Form::Onboarding;
has 'form' => (
	       isa => 'UMI::Form::Onboarding', is => 'rw',
	       lazy => 1, documentation => q{Form to onboard newbe (generate GPG and SSH key)},
	       default => sub { UMI::Form::Onboarding->new },
	      );


=head1 NAME

UMI::Controller::Onboarding - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut



=head2 index



=cut


sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  if ( defined $c->user_exists && $c->user_exists == 1 ) {

    my $ldap_crud = $c->model('LDAP_CRUD');
    my $params = $c->req->parameters;

    $c->stash( template => 'tool/onboarding.tt',
	       form     => $self->form );

    return unless
      $self->form->process(
			   posted => ($c->req->method eq 'POST'),
			   params => $params,
			  );

    my ($err, $key);
    $key->{name} = { real  => $c->user->gecos // 'N/A',
		     email => $c->user->has_attribute('mail')  // 'N/A', };

    $key->{ssh} = $self->keygen_ssh({ type => $ldap_crud->cfg->{defaults}->{key}->{ssh}->{type},
				      bits => $ldap_crud->cfg->{defaults}->{key}->{ssh}->{bits},
				      name => $key->{name}             });
    push @{$key->{html}->{error}}, @{$key->{ssh}->{error}}
      if exists $key->{ssh}->{error};

    $key->{gpg} = $self->keygen_gpg({ bits => $ldap_crud->cfg->{defaults}->{key}->{gpg}->{bits},
				      name => $key->{name}, });
    push @{$key->{html}->{error}}, @{$key->{gpg}->{error}}
      if exists $key->{gpg}->{error};

    #
    ## SSH
    #

    ### delete objects authorizedService=ssh-acc@
    my $mesg = $ldap_crud->search( { base => $c->user->dn, filter => 'objectClass=ldapPublicKey', } );
    push @{$key->{html}->{error}}, $ldap_crud->err($mesg)->{caller} . $ldap_crud->err($mesg)->{html}
      if $mesg->code ne '0';

    foreach ( $mesg->entries ) {
      $err = $ldap_crud->del($_->dn)
	if $_->get_value( 'sshPublicKey' ) =~ /.* $self->{a}->{re}->{sshpubkey}->{comment} .*/;
      push @{$key->{html}->{error}}, $err if $err;
    }

    $mesg =
      $ldap_crud->search({ base => sprintf('authorizedService=ssh-acc@%s',
					   $ldap_crud->cfg->{defaults}->{ldap}->{associatedDomain}) });
    push @{$key->{html}->{error}}, $ldap_crud->err($mesg)->{caller} . $ldap_crud->err($mesg)->{html}
      if $mesg->code ne '0' && $mesg->code ne '32';

    if ( $mesg->code == 32 ) {
      my $branch = $ldap_crud->
	create_account_branch ({
				authorizedservice => 'ssh-acc',
				associateddomain  => $ldap_crud->cfg->{defaults}->{ldap}->{associatedDomain},
				objectclass       => [],
				requestttl        => '',
				uid               => $c->user->uid,
			       });

      push @{$key->{html}->{success}}, $branch->{success} if defined $branch->{success};
      push @{$key->{html}->{warning}}, $branch->{warning} if defined $branch->{warning};
      push @{$key->{html}->{error}},   $branch->{error}   if defined $branch->{error};
    }

    my $leaf = $ldap_crud->
      create_account_branch_leaf (
				  {
				   associateddomain    => $ldap_crud->cfg->{defaults}->{ldap}->{associatedDomain},
				   authorizedservice   => "ssh-acc",
				   basedn              => sprintf('authorizedService=ssh-acc@%s,%s',
								  $ldap_crud->cfg->{defaults}->{ldap}->{associatedDomain},
								  $c->user->dn),
				   description         => undef,
				   gecos               => $c->user->gecos,
				   givenName           => $c->user->givenname,
				   mail                => undef,
				   objectclass         => $ldap_crud->cfg->{objectClass}->{acc_svc_ssh},
				   password            => { 'ssh-acc' => $self->pwdgen },
				   requestttl          => '',
				   sn                  => $c->user->sn,
				   sshgid              => undef,
				   sshhome             => undef,
				   sshkey              => $key->{ssh}->{public},
				   sshkeyfile          => undef,
				   sshshell            => undef,
				   telephoneNumber     => undef,
				   uidNumber           => $ldap_crud->last_uidNumber_ssh + 1,
				   uid                 => $c->user->uid,
				   login               => $c->user->uid,
				  }
				 );

    push @{$key->{html}->{success}}, @{$leaf->{success}} if defined $leaf->{success};
    push @{$key->{html}->{warning}}, @{$leaf->{warning}} if defined $leaf->{warning};
    push @{$key->{html}->{error}},   @{$leaf->{error}}   if defined $leaf->{error};

    #
    ## GPG
    #

    ### DELETE
    $mesg =
      $ldap_crud->search( { base   => $ldap_crud->cfg->{base}->{pgp},
			    filter => sprintf('pgpUserID=*%s*', $self->{a}->{re}->{gpgpubkey}->{comment}),
			    attrs  => ['pgpUserID'], } );
    push @{$key->{html}->{error}}, $ldap_crud->err($mesg)->{caller} . $ldap_crud->err($mesg)->{html}
      if $mesg->code ne '0';

    my ($keys_gpg, $qr);
    foreach ( @{[$mesg->entries]} ) {
      $err = $ldap_crud->del($_->dn)
	if $_->get_value( 'pgpUserId' ) =~ /.*$self->{a}->{re}->{gpgpubkey}->{comment} .*/;

      push @{$key->{html}->{error}}, $err if $err;
    }

    ### ADD
    my ($add_dn, $add_attrs);
    $add_dn = sprintf("pgpCertID=%s,%s",
			 $key->{gpg}->{send_key}->{pgpCertID},
			 $ldap_crud->cfg->{base}->{pgp});
    @{$add_attrs} = map { $_ => $key->{gpg}->{send_key}->{$_} } keys %{$key->{gpg}->{send_key}};
    $mesg = $ldap_crud->add( $add_dn, $add_attrs );

    push @{$key->{html}->{error}}, $mesg->{html} if $mesg;

    #
    ## PWD
    #

    if ( defined $c->session->{auth_uid} ) {
      my $pwd =
	$self->pwdgen({ len => undef, num => undef, cap => undef,
			pronounceable => 0,
			pwd_alg => 'XKCD',
			xk  => {
				allow_accents               => 0,
				case_transform              => "RANDOM",
				num_words                   => 5,
				padding_characters_after    => 0,
				padding_characters_before   => 0,
				padding_digits_after        => 0,
				padding_digits_before       => 0,
				padding_type                => "NONE",
				separator_character         => "-",
				word_length_max             => 8,
				word_length_min             => 4
			       }
		      });
      $key->{pwd} = $pwd;
      for ( my $i = 0; $i < 41; $i++ ) {
	$qr = $self->qrcode({ txt => $pwd->{clear}, ver => $i, mod => 5 });
	last if ! exists $qr->{error};
      }

      $key->{html}->{error} = $qr->{error} if $qr->{error};
      $key->{pwd}->{qr} = sprintf('<img class="img-responsive img-thumbnail table-success" alt="password QR" src="data:image/jpg;base64,%s" title="password QR"/>',
				  $qr->{qr} );

      $mesg = $ldap_crud->modify( $c->user->dn,
				  [ replace => [ userPassword => $pwd->{ssha} ] ]);
      if ( $mesg ne '0' ) {
	push @{$key->{html}->{error}}, $mesg->{html};
      } else {
	$c->session->{auth_pwd} = $pwd->{clear};
      }
    }

    # log_debug { np($key->{html}) };
    delete $key->{html}->{success};
    delete $key->{html}->{warning}
      if $key->{html}->{warning}->[0] =~ /branch DN: .* was not created since .* I will use it further./;
    $c->stash( final_message => $key->{html},
	       key           => $key
	     );
  } else {
    $c->stash( template => 'signin.tt', );
  }
}

=head1 AUTHOR

Charlie &

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;

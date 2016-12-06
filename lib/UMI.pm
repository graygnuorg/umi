#-*- cperl -*-
#

package UMI;
use Moose;
use namespace::autoclean;

use Data::Printer  colored => 1;
use Data::Dumper;

use Catalyst::Runtime 5.8;

use Catalyst qw/
    -Debug
    ConfigLoader
    Static::Simple

    StackTrace

    Cache

    Authentication
    Authorization::Roles
    Authorization::ACL

    Session
    Session::Store::FastMmap
    Session::State::Cookie

    StatusMessage
/;

extends 'Catalyst';

our $VERSION = '0.91';

__PACKAGE__
  ->config(
	   'Plugin::Cache' => { backend => { class => "Cache::Memory", }, },
	   name => 'UMI',
	   # Disable deprecated behavior needed by old applications
	   disable_component_resolution_regex_fallback => 1,
	   enable_catalyst_header => 1, # Send X-Catalyst header
	   default_view => "Web",
	   session => { storage => "/tmp/umi/sess-$^T-$>",
			flash_to_stash => 1,
			cache_size => '10m',
			# expire_time => '1d',
			## init_file => 1, # causes need for re-login if PSGI reloaded during the form filling
			unlink_on_exit => 1,
		      },
	   authentication =>
	   {
	    default_realm => "ldap",
	    realms => { ldap =>
			{ credential => { class => "Password",
					  password_field => "password",
					  password_type => "self_check", },
			  store => { binddn              => 'uid=binddn,ou=system,dc=foo,dc=bar',
				     bindpw              => 'secret password',
				     class               => 'LDAP',
				     ldap_server         => 'ldap.host.org',
				     ldap_server_options => { timeout => 30 },
				     use_roles           => 1,
				     role_basedn         => "ou=group,ou=system,dc=foo,dc=bar",
				     role_field          => "cn",
				     role_filter         => "(memberUid=%s)",
				     role_scope          => "sub",
				     # role_search_options => { deref => "always" },
				     role_value          => "uid",
				     # role_search_as_user => 0,
				     start_tls           => 0,
				     start_tls_options   => { verify => "none" },
				     # entry_class         => "MyApp::LDAP::Entry",
				     user_basedn         => 'ou=People,dc=foo,dc=bar',
				     user_field          => "uid",
				     user_filter         => "(uid=%s)",
				     user_scope          => "one", # or "sub" for Active Directory
				     # user_search_options => { deref => "never" },
				     user_results_filter => sub { return shift->pop_entry },
				   },
			},
		      },
	   },
	  );


# Start the application
__PACKAGE__->setup();

# __PACKAGE__->allow_access_if( "/", [ qw/admin/ ]);

__PACKAGE__->deny_access_unless_any( "/dhcp",                [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/dhcp_root",           [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/gitacl",              [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/gitacl_root",         [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/group",               [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/group_root",          [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/org",                 [ qw/admin coadmin acl-w-organizations/ ]);
__PACKAGE__->deny_access_unless_any( "/inventory",           [ qw/admin coadmin acl-w-inventory/ ]);
__PACKAGE__->deny_access_unless_any( "/nisnetgroup",         [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/org_root",            [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/stat_acc",            [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/stat_monitor",        [ qw/admin coadmin/ ]);

# here we allow search to all members of admin, coadmin and operator groups, while the very permition to
# search some LDAP filter or not is controlled by Tools::is_searchable method in Controller::SearchBy::index
__PACKAGE__->deny_access_unless_any( "/searchadvanced",      [ qw/admin coadmin operator/ ]);
__PACKAGE__->deny_access_unless_any( "/searchby",            [ qw/admin coadmin operator/ ]);

__PACKAGE__->deny_access_unless_any( "/searchby/ldif_gen",   [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/searchby/ldif_gen2f", [ qw/admin coadmin/ ]);
__PACKAGE__->deny_access_unless_any( "/sysinfo",             [ qw/admin/ ]);

__PACKAGE__->deny_access_unless_any( "/toolpwdgen",          [ qw/admin coadmin operator employee/ ]);
__PACKAGE__->deny_access_unless_any( "/toolqr",              [ qw/admin coadmin operator employee/ ]);
__PACKAGE__->deny_access_unless_any( "/tooltranslit",        [ qw/admin coadmin operator employee/ ]);

__PACKAGE__->deny_access_unless_any( "/toolimportldif",      [ qw/admin/ ]);
__PACKAGE__->deny_access_unless_any( "/user",                [ qw/admin coadmin acl-w-people/ ]);
__PACKAGE__->deny_access_unless_any( "/userall",             [ qw/admin coadmin acl-w-people/ ]);

__PACKAGE__
  ->allow_access_if( "/user/modpwd",
		     sub {
		       my ( $c, $action ) = @_;
		       if ( $c->user_exists ) {
			 die $Catalyst::Plugin::Authorization::ACL::Engine::ALLOWED;
		       } else {
			 die $Catalyst::Plugin::Authorization::ACL::Engine::DENIED;
		       }
		     } );

__PACKAGE__->allow_access("/searchby/modify_userpassword");

__PACKAGE__->acl_allow_root_internals;


=head1 NAME

UMI - Catalyst based application

=head1 SYNOPSIS

    script/umi_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<UMI::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Zeus Panchenko

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

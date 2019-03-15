# -*- mode: cperl; mode: follow; -*-
#

package UMI::Form::ToolPwdgen;

use HTML::FormHandler::Moose;
BEGIN { extends 'UMI::Form::LDAP'; with 'Tools'; }

use Data::Printer;
use Logger;

use HTML::FormHandler::Types ('NoSpaces', 'WordChars', 'NotAllDigits', 'Printable', 'PositiveNum' );

has '+item_class' => ( default =>'ToolPwdgen' );
has '+action' => ( default => '/toolpwdgen' );

sub build_form_element_class { [ 'form-horizontal formajaxer' ] }

has_field 'pronounceable'
  => (
      type                  => 'Checkbox',
      label                 => 'Pronounceable',
      element_wrapper_class => [ 'offset-md-2', 'col-10', ],
      element_class         => [ qw( disabler-checkbox
				     disableable
				     disabled-if-pwdcheckonly
				     disabled-if-pwddefault ) ],
      element_attr          => { title => 'Completely random word if unchecked, othervise max lengh is ' .
				 UMI->config->{pwd}->{lenp} },
      wrapper_class         => [ 'row', 'deactivate-top', 'mt-5', ],
     );

has_field 'pwd_len'
  => (
      type                  => 'Integer',
      apply                 => [ NoSpaces, PositiveNum ],
      label                 => 'Password Length',
      label_class           => [ 'col', 'text-right', 'font-weight-bold', ],
      element_wrapper_class => [ 'input-sm', 'col-10', ],
      element_class         => [ qw( disabler-input
				     disableable
				     disabled-if-pwdcheckonly
				     disabled-if-pwddefault ) ],
      element_attr => { placeholder => sprintf("min: %s; default common: %s; max common: %s; max pronouceable: %s",
					       UMI->config->{pwd}->{len_min},
					       UMI->config->{pwd}->{len},
					       UMI->config->{pwd}->{len_max},
					       UMI->config->{pwd}->{lenp} ),
			title       => sprintf("min: %s; default common: %s; max common: %s; max pronouceable: %s",
					       UMI->config->{pwd}->{len_min},
					       UMI->config->{pwd}->{len},
					       UMI->config->{pwd}->{len_max},
					       UMI->config->{pwd}->{lenp} ), },
      wrapper_class         => [ 'row', 'deactivate-top', ],
     );

has_field 'pwd_cap'
  => (
      type                  => 'Integer',
      apply                 => [ NoSpaces, PositiveNum ],
      label                 => 'Capital Characters',
      label_class           => [ 'col', 'text-right', 'font-weight-bold', ],
      element_wrapper_class => [ 'input-sm', 'col-10', ],
      element_attr          => { placeholder => 'max ' . UMI->config->{pwd}->{cap},
				 title       => 'up to this many characters will be upper case', },
      wrapper_class         => [ 'row', 'deactivate-top', ],
     );

has_field 'pwd_num'
  => (
      type                  => 'Integer',
      apply                 => [ NoSpaces, PositiveNum ],
      label                 => 'Numbers And Spec. Characters',
      label_class           => [ 'col', 'text-right', 'font-weight-bold', ],
      element_wrapper_class => [ 'input-sm', 'col-10', ],
      element_attr          => { placeholder => 'max ' . UMI->config->{pwd}->{num},
				 title       => 'up to that many, numbers and special characters will occur in the password',
				 'data-mode' => "pwdpronounceable", },
      wrapper_class         => [ 'row', 'deactivate-top', ],
     );

has_field 'aux_reset'
  => ( type          => 'Reset',
       element_class => [ qw( btn
			      btn-danger
			      btn-block
			      font-weight-bold
			      text-uppercase) ],
       wrapper_class => [ 'col-4' ],
       value         => 'Reset' );

has_field 'aux_submit'
  => ( type          => 'Submit',
       element_class => [ qw( btn
			      btn-success
			      btn-block
			      font-weight-bold
			      text-uppercase) ],
       wrapper_class => [ 'col-8', ],
       value         => 'Submit' );

has_block 'aux_submitit'
  => ( tag => 'div',
       render_list => [ 'aux_reset', 'aux_submit'],
       class => [ 'row', ]
     );

sub build_render_list {[ 'pronounceable', 'pwd_len', 'pwd_cap', 'pwd_num', 'aux_submitit' ]}

sub html_attributes {
  my ( $self, $field, $type, $attr ) = @_;
  push @{$attr->{class}}, 'required'
    if ( $type eq 'label' && $field->required );
}

sub validate {
  my $self = shift;

  # log_debug { np($self->field('pronounceable')->value) };
  
  if ( ! $self->field('pronounceable')->value && defined $self->field('pwd_len')->value &&
       $self->field('pwd_len')->value ne '' &&
       ( $self->field('pwd_len')->value < UMI->config->{pwd}->{len_min} ||
	 $self->field('pwd_len')->value > UMI->config->{pwd}->{len_max} )
     ) {
    $self->field('pwd_len')
      ->add_error('Incorrect password length! It can be greater than ' .
		  UMI->config->{pwd}->{len_min} . ' and less than ' . UMI->config->{pwd}->{len_max} . ' characters long.');
  }

  if ( $self->field('pronounceable')->value &&
       $self->field('pwd_len')->value > UMI->config->{pwd}->{lenp} ) {
    $self->field('pwd_len')
      ->add_error('Pronounceable max length ' . UMI->config->{pwd}->{lenp});
  }

  if ( $self->field('pwd_cap')->value > UMI->config->{pwd}->{cap} ) {
    $self->field('pwd_cap')
      ->add_error('Incorrect capital characters number! It can be 0 to ' . UMI->config->{pwd}->{cap});
  }

  if ( $self->field('pwd_num')->value > UMI->config->{pwd}->{num} ) {
    $self->field('pwd_num')
      ->add_error('Numbers and special characters can occure only 0 to ' . UMI->config->{pwd}->{num} . ' times!');
  }


}

######################################################################

no HTML::FormHandler::Moose;

__PACKAGE__->meta->make_immutable;

1;

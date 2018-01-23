# -*- mode: cperl -*-
#

package Logger;

use utf8;
use Data::Printer;
use Try::Tiny;
use POSIX qw(strftime);

use Log::Log4perl qw(:levels :easy);
use base qw(Log::Dispatch::Output);
use base 'Log::Contextual';

#  log4perl.appender.LogFileDebug.layout.ConversionPattern = %d{yyyy.MM.DD HH:mm:ss} %p: %F{2}:%L %M:%n%m%n

my $appender_file = q(
  log4perl.logger                       = INFO, appndr_s
  log4perl.logger.transcript            = TRACE, appndr_f

  log4perl.appender.appndr_f            = Log::Log4perl::Appender::File
  log4perl.appender.appndr_f.layout     = PatternLayout
  log4perl.appender.appndr_f.layout.ConversionPattern = %d{yyyy.MM.DD HH:mm:ss} [%p]: %F{2}:%L %m%n
  log4perl.appender.appndr_f.recreate   = 1
  log4perl.appender.appndr_f.mkpath     = 1
  log4perl.appender.appndr_f.filename   = /tmp/umi/umi.log
  log4perl.appender.appndr_f.mode       = append
  log4perl.appender.appndr_f.utf8       = 1

  log4perl.appender.appndr_s            = Log::Dispatch::Syslog
  log4perl.appender.appndr_s.ident      = UMI
  log4perl.appender.appndr_s.facility   = local2
  log4perl.appender.appndr_s.layout     = PatternLayout
  log4perl.appender.appndr_s.layout.ConversionPattern = %p: %F{2} @ %L: %m
);

# my $appender_file = q(
#   log4perl.logger                           = TRACE, LogFileDebug
#   log4perl.appender.LogFileDebug            = Log::Log4perl::Appender::File
#   log4perl.appender.LogFileDebug.layout     = SimpleLayout
#   log4perl.appender.LogFileDebug.recreate   = 1
#   log4perl.appender.LogFileDebug.mkpath     = 1
#   log4perl.appender.LogFileDebug.filename   = /tmp/umi/umi.log
#   log4perl.appender.LogFileDebug.mode       = append
#   log4perl.appender.LogFileDebug.utf8       = 1
# );

Log::Log4perl::init( \$appender_file );




sub arg_default_logger { $_[1] || Log::Log4perl->get_logger }

sub arg_levels { [qw(debug trace warn info error fatal)] }

sub default_import { ':log' }

# or maybe instead of default_logger
sub arg_package_logger { $_[1] }

# and almost definitely not this, which is only here for completeness
sub arg_logger { $_[1] }


sub TIEHANDLE {
  my $class = shift;
  bless [], $class;
}

sub PRINT {
  my $self = shift;
  $Log::Log4perl::caller_depth++;
  TRACE @_;
  # @_;
  $Log::Log4perl::caller_depth--;
}

sub PRINTF {
  my $self = shift;
  $Log::Log4perl::caller_depth++;
  TRACE @_;
  # @_;
  $Log::Log4perl::caller_depth--;
}

sub BINMODE {
  my $self = shift;
  $Log::Log4perl::caller_depth++;
  TRACE @_;
  # @_;
  $Log::Log4perl::caller_depth--;
}
















# use base 'Log::Contextual';
# # use Log::Contextual;
# use Log::Log4perl qw(:levels :easy);

# my $appender_file =
#   Log::Log4perl::Appender->new(
# 			       "Log::Log4perl::Appender::File",
# 			       name       => "umi_log",
# 			       filename   => '/tmp/umi/umi.log',
# 			       mode       => 'append',
# 			       additivity => 0,
# 			       utf8       => 1,
# 			      );

# Log::Log4perl::init( \$appender_file );


# sub arg_default_logger { $_[1] || Log::Log4perl->get_logger }

# sub arg_levels { [qw(debug trace warn info error fatal custom_level)] }

# sub default_import { ':log' }

# # or maybe instead of default_logger
# sub arg_package_logger { $_[1] }

# # and almost definitely not this, which is only here for completeness
# sub arg_logger { $_[1] }


=head1 AUTHOR

Zeus

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

######################################################################

1;

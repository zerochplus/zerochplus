#============================================================= -*-perl-*-
#
# Template
#
# DESCRIPTION
#   Module implementing a simple, user-oriented front-end to the Template
#   Toolkit.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2012 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#========================================================================
package Template;use strict;use warnings;use 5.006;use base 'Template::Base';use Template::Config;use Template::Constants;use Template::Provider;use Template::Service;use File::Basename;use File::Path;use Scalar::Util qw(blessed);our$VERSION='2.24';our$ERROR='';our$DEBUG=0;our$BINMODE=0 unless defined$BINMODE;our$AUTOLOAD;Template::Config->preload()if$ENV{MOD_PERL};sub process{my($self,$template,$vars,$outstream,@opts)=@_;my($output,$error);my$options=(@opts==1)&&ref($opts[0])eq 'HASH'?shift(@opts):{@opts};$options->{binmode}=$BINMODE unless defined$options->{binmode};$self->DEBUG("set binmode\n")if$DEBUG&&$options->{binmode};$output=$self->{SERVICE}->process($template,$vars);if(defined$output){$outstream||=$self->{OUTPUT};unless(ref$outstream){my$outpath=$self->{OUTPUT_PATH};$outstream="$outpath/$outstream"if$outpath;}return($self->error($error))if($error=&_output($outstream,\$output,$options));return 1;}else{return$self->error($self->{SERVICE}->error);}}sub service{my$self=shift;return$self->{SERVICE};}sub context{my$self=shift;return$self->{SERVICE}->{CONTEXT};}sub template{shift->context->template(@_);}sub _init{my($self,$config)=@_;my$debug=$config->{DEBUG};$config->{DEBUG}=Template::Constants::debug_flags($self,$debug)||return if defined$debug&&$debug!~/^\d+$/;if(my$constants=$config->{CONSTANTS}){my$ns=$config->{NAMESPACE}||={};my$cns=$config->{CONSTANTS_NAMESPACE}||'constants';$constants=Template::Config->constants($constants)||return$self->error(Template::Config->error);$ns->{$cns}=$constants;}$self->{SERVICE}=$config->{SERVICE}||Template::Config->service($config)||return$self->error(Template::Config->error);$self->{OUTPUT}=$config->{OUTPUT}||\*STDOUT;$self->{OUTPUT_PATH}=$config->{OUTPUT_PATH};return$self;}sub _output{my($where,$textref,$options)=@_;my$reftype;my$error=0;if(($reftype=ref($where))eq 'CODE'){&$where($$textref);}elsif($reftype eq 'GLOB'){print$where $$textref;}elsif($reftype eq 'SCALAR'){$$where.=$$textref;}elsif($reftype eq 'ARRAY'){push@$where,$$textref;}elsif(blessed($where)&&$where->can('print')){$where->print($$textref);}elsif(!$reftype){local*FP;my$dir=dirname($where);eval{mkpath($dir)unless-d$dir;};if($@){($error=$@)=~s/ at \S+ line \d+\n?$//;}elsif(open(FP,">$where")){my$bm=$options->{binmode};if($bm&&$bm eq 1){binmode FP;}elsif($bm){binmode FP,$bm;}print FP$$textref;close FP;}else{$error="$where: $!";}}else{$error="output_handler() cannot determine target type ($where)\n";}return$error;}1;__END__

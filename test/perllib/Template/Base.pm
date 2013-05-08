#============================================================= -*-perl-*-
#
# Template::Base
#
# DESCRIPTION
#   Base class module implementing common functionality for various other
#   Template Toolkit modules.
#
# AUTHOR
#   Andy Wardley   <abw@wardley.org>
#
# COPYRIGHT
#   Copyright (C) 1996-2007 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#========================================================================
package Template::Base;use strict;use warnings;use Template::Constants;our$VERSION=2.78;sub new{my$class=shift;my($argnames,@args,$arg,$cfg);{no strict 'refs';no warnings 'once';$argnames=\@{"$class\::BASEARGS"}||[];}foreach$arg(@$argnames){return$class->error("no $arg specified")unless($cfg=shift);push(@args,$cfg);}$cfg=defined$_[0]&&ref($_[0])eq 'HASH'?shift :{@_};my$self=bless{(map{($_=>shift@args)}@$argnames),_ERROR=>'',DEBUG=>0,},$class;return$self->_init($cfg)?$self:$class->error($self->error);}sub error{my$self=shift;my$errvar;{no strict qw(refs);$errvar=ref$self?\$self->{_ERROR}:\${"$self\::ERROR"};}if(@_){$$errvar=ref($_[0])?shift :join('',@_);return undef;}else{return$$errvar;}}sub _init{my($self,$config)=@_;return$self;}sub debug{my$self=shift;my$msg=join('',@_);my($pkg,$file,$line)=caller();unless($msg=~/\n$/){$msg.=($self->{DEBUG}&Template::Constants::DEBUG_CALLER)?" at $file line $line\n":"\n";}print STDERR"[$pkg] $msg";}sub module_version{my$self=shift;my$class=ref$self||$self;no strict 'refs';return${"${class}::VERSION"};}1;__END__

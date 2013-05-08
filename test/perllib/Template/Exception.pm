#============================================================= -*-Perl-*-
#
# Template::Exception
#
# DESCRIPTION
#   Module implementing a generic exception class used for error handling
#   in the Template Toolkit.
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
package Template::Exception;use strict;use warnings;use constant TYPE=>0;use constant INFO=>1;use constant TEXT=>2;use overload q|""|=>"as_string",fallback=>1;our$VERSION=2.70;sub new{my($class,$type,$info,$textref)=@_;bless[$type,$info,$textref],$class;}sub type{$_[0]->[TYPE];}sub info{$_[0]->[INFO];}sub type_info{my$self=shift;@$self[TYPE,INFO];}sub text{my($self,$newtextref)=@_;my$textref=$self->[TEXT];if($newtextref){$$newtextref.=$$textref if$textref&&$textref ne$newtextref;$self->[TEXT]=$newtextref;return '';}elsif($textref){return$$textref;}else{return '';}}sub as_string{my$self=shift;return$self->[TYPE].' error - '.$self->[INFO];}sub select_handler{my($self,@options)=@_;my$type=$self->[TYPE];my%hlut;@hlut{@options}=(1)x@options;while($type){return$type if$hlut{$type};$type=~s/\.?[^\.]*$//;}return undef;}1;__END__

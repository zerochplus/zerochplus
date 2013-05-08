#============================================================= -*-Perl-*-
#
# Template::Iterator
#
# DESCRIPTION
#
#   Module defining an iterator class which is used by the FOREACH
#   directive for iterating through data sets.  This may be
#   sub-classed to define more specific iterator types.
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
#============================================================================
package Template::Iterator;use strict;use warnings;use base 'Template::Base';use Template::Constants;use Template::Exception;use Scalar::Util qw(blessed);use constant ODD=>'odd';use constant EVEN=>'even';our$VERSION=2.68;our$DEBUG=0 unless defined$DEBUG;our$AUTOLOAD;sub new{my$class=shift;my$data=shift||[];my$params=shift||{};if(ref$data eq 'HASH'){$data=[map{{key=>$_,value=>$data->{$_}}}sort keys%$data];}elsif(blessed($data)&&$data->can('as_list')){$data=$data->as_list();}elsif(ref$data ne 'ARRAY'){$data=[$data];}bless{_DATA=>$data,_ERROR=>'',},$class;}sub get_first{my$self=shift;my$data=$self->{_DATA};$self->{_DATASET}=$self->{_DATA};my$size=scalar@$data;my$index=0;return(undef,Template::Constants::STATUS_DONE)unless$size;@$self{qw(SIZE MAX INDEX COUNT FIRST LAST)}=($size,$size-1,$index,1,1,$size>1?0:1,undef);@$self{qw(PREV NEXT)}=(undef,$self->{_DATASET}->[$index+1]);return$self->{_DATASET}->[$index];}sub get_next{my$self=shift;my($max,$index)=@$self{qw(MAX INDEX)};my$data=$self->{_DATASET};unless(defined$index){my($pack,$file,$line)=caller();warn("iterator get_next() called before get_first() at $file line $line\n");return(undef,Template::Constants::STATUS_DONE);}if($index<$max){$index++;@$self{qw(INDEX COUNT FIRST LAST)}=($index,$index+1,0,$index==$max?1:0);@$self{qw(PREV NEXT)}=@$data[$index-1,$index+1];return$data->[$index];}else{return(undef,Template::Constants::STATUS_DONE);}}sub get_all{my$self=shift;my($max,$index)=@$self{qw(MAX INDEX)};my@data;unless(defined$index){my($first,$status)=$self->get_first;($max,$index)=@$self{qw(MAX INDEX)};if($status&&$status==Template::Constants::STATUS_DONE){return(undef,Template::Constants::STATUS_DONE);}push@data,$first;unless($index<$max){return\@data;}}if($index<$max){$index++;push@data,@{$self->{_DATASET}}[$index..$max];@$self{qw(INDEX COUNT FIRST LAST)}=($max,$max+1,0,1);return\@data;}else{return(undef,Template::Constants::STATUS_DONE);}}sub odd{shift->{COUNT}%2?1:0}sub even{shift->{COUNT}%2?0:1}sub parity{shift->{COUNT}%2?ODD :EVEN;}sub AUTOLOAD{my$self=shift;my$item=$AUTOLOAD;$item=~s/.*:://;return if$item eq 'DESTROY';$item='COUNT'if$item=~/NUMBER/i;return$self->{uc$item};}sub _dump{my$self=shift;join('',"  Data: ",$self->{_DATA},"\n"," Index: ",$self->{INDEX},"\n","Number: ",$self->{NUMBER},"\n","   Max: ",$self->{MAX},"\n","  Size: ",$self->{SIZE},"\n"," First: ",$self->{FIRST},"\n","  Last: ",$self->{LAST},"\n","\n");}1;__END__

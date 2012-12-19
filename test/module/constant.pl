#============================================================================================================
#
#	定数モジュール(ZP)
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#============================================================================================================
package	ZP;

use strict;
use warnings;
#use bigint;

# CLIENT
#  M: Mobile Browser, F: Full Browser
our $C_PC				= 0x00000001;
our $C_P2				= 0x00000002;
our $C_DOCOMO_M			= 0x00000004;
our $C_DOCOMO_F			= 0x00000008;
our $C_DOCOMO			= $C_DOCOMO_M | $C_DOCOMO_F;
our $C_AU_M				= 0x00000010;
our $C_AU_F				= 0x00000020;
our $C_AU				= $C_AU_M | $C_AU_F;
our $C_SOFTBANK_M		= 0x00000040;
our $C_SOFTBANK_F		= 0x00000080;
our $C_SOFTBANK			= $C_SOFTBANK_M | $C_SOFTBANK_F;
our $C_WILLCOM_M		= 0x00000100;
our $C_WILLCOM_F		= 0x00000200;
our $C_WILLCOM			= $C_WILLCOM_M | $C_WILLCOM_F;
our $C_EMOBILE_M		= 0x00000400;
our $C_EMOBILE_F		= 0x00000800;
our $C_EMOBILE			= $C_EMOBILE_M | $C_EMOBILE_F;
our $C_IBIS				= 0x00001000;
our $C_JIG				= 0x00002000;
our $C_OPERAMINI		= 0x00004000;
our $C_IPHONE_F			= 0x00008000;
our $C_IPHONEWIFI		= 0x00010000;
our $C_IPHONE			= $C_IPHONE_F | $C_IPHONEWIFI;
our $C_FBSERVICE		= $C_IBIS | $C_JIG | $C_OPERAMINI;
our $C_MOBILEBROWSER	= $C_DOCOMO_M | $C_AU_M | $C_SOFTBANK_M | $C_WILLCOM_M | $C_EMOBILE_M;
our $C_FULLBROWSER		= $C_DOCOMO_F | $C_AU_F | $C_SOFTBANK_F | $C_WILLCOM_F | $C_EMOBILE_F | $C_FBSERVICE;
our $C_MOBILE			= $C_MOBILEBROWSER | $C_FULLBROWSER;
our $C_MOBILE_IDGET		= $C_DOCOMO_M | $C_AU_M | $C_SOFTBANK_M | $C_EMOBILE_M | $C_P2;


# ERRORNUM
our $E_SUCCESS				= 0; # must FALSE
#  入力内容に関するエラー
our $E_FORM_LONGSUBJECT		= 100;
our $E_FORM_LONGNAME		= 101;
our $E_FORM_LONGMAIL		= 102;
our $E_FORM_LONGTEXT		= 103;
our $E_FORM_LONGLINE		= 104;
our $E_FORM_MANYLINE		= 105;
our $E_FORM_MANYANCHOR		= 106;
our $E_FORM_NOSUBJECT		= 150;
our $E_FORM_NOTEXT			= 151;
our $E_FORM_NONAME			= 152;
#  制限に関するエラー
our $E_LIMIT_STOPPEDTHREAD	= 200;
our $E_LIMIT_OVERMAXRES		= 201;
our $E_LIMIT_MOVEDTHREAD	= 202;
our $E_LIMIT_READONLY		= 203;
our $E_LIMIT_MOBILETHREAD	= 204;
our $E_LIMIT_FORBIDDENCGI	= 205;
our $E_LIMIT_OVERDATSIZE	= 206;
our $E_LIMIT_THREADCAPONLY	= 504;
#  規制に関するエラー
our $E_REG_MANYTHREAD		= 500;
our $E_REG_NOBREAKPOST		= 501;
our $E_REG_DOUBLEPOST		= 502;
our $E_REG_NOTIMEPOST		= 503;
our $E_REG_SAMBA_CAUTION	= 505;
our $E_REG_SAMBA_WARNING	= 506;
our $E_REG_SAMBA_LISTED		= 507;
our $E_REG_SAMBA_STILL		= 508;
our $E_REG_NGWORD			= 600;
our $E_REG_NGUSER			= 601;
our $E_REG_NOTJPHOST		= 207;
our $E_REG_DNSBL			= 997;
#  BEに関するエラー
our $E_BE_GETFAILED			= 890;
our $E_BE_CONNECTFAILED		= 891;
our $E_BE_LOGINFAILED		= 892;
our $E_BE_MUSTLOGIN			= 893;
our $E_BE_MUSTLOGIN2		= 894;
#  リクエストエラー
our $E_THREAD_INVALIDKEY	= 900;
our $E_THREAD_WRONGLENGTH	= 901;
our $E_THREAD_NOTEXIST		= 902;
our $E_POST_NOPRODUCT		= 950;
our $E_POST_INVALIDREFERER	= 998;
our $E_POST_INVALIDFORM		= 999;
our $E_POST_NOTEXISTBBS		= $E_POST_INVALIDFORM;
our $E_POST_NOTEXISTDAT		= $E_POST_INVALIDFORM;
#  read.cgi用エラー
our $E_READ_R_INVALIDBBS	= 1001;
our $E_READ_R_INVALIDKEY	= 1002;
our $E_READ_FAILEDLOADDAT	= 1003;
our $E_READ_FAILEDLOADSET	= 1004;
our $E_READ_INVALIDBBS		= 2011;
our $E_READ_INVALIDKEY		= 3001;
#  システム・その他のエラー
our $E_SYSTEM_ERROR			= 990;
#  ページ表示用番号
our $E_PAGE_FINDTHREAD		= $E_READ_FAILEDLOADDAT;
our $E_PAGE_THREAD			= 9000;
our $E_PAGE_COOKIE			= 9001;
our $E_PAGE_WRITE			= 9002;
our $E_PAGE_THREADMOBILE	= 9003;


# REGEXP
our $RE_SJIS	= '(?:[\x00-\x7f\xa1-\xdf]|[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc])';


#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

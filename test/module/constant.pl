#============================================================================================================
#
#	定数モジュール(ZP)
#	constant.pl
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#	---------------------------------------------
#
#	2011.01.02 start
#	2011.12.03 iPhoneがフルブラウザになっていたのを修正
#	           固有IDが取れそうなC_MOBILE_IDGETを新規設定
#
#============================================================================================================
package	ZP;

use strict;
use warnings;
use bigint;

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


our $RE_SJIS			= '(?:[\x00-\x7f\xa1-\xdf]|[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc])';

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

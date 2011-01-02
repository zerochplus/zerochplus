#============================================================================================================
#
#	定数モジュール(ZP)
#	constant.pl
#	---------------------------------------------
#	2011.01.02 start
#
#============================================================================================================
package	ZP;

use strict;
use warnings;

# CLIENT
#  M: Mobile Browser, F: Full Browser
our $C_PC				= 0x0001;
our $C_P2				= 0x0002;
our $C_DOCOMO_M			= 0x0004;
our $C_DOCOMO_F			= 0x0008;
our $C_DOCOMO			= $C_DOCOMO_M | $C_DOCOMO_F;
our $C_AU_M				= 0x0010;
our $C_AU_F				= 0x0020;
our $C_AU				= $C_AU_M | $C_AU_F;
our $C_SOFTBANK_M		= 0x0040;
our $C_SOFTBANK_F		= 0x0080;
our $C_SOFTBANK			= $C_SOFTBANK_M | $C_SOFTBANK_F;
our $C_WILLCOM_M		= 0x0100;
our $C_WILLCOM_F		= 0x0200;
our $C_WILLCOM			= $C_WILLCOM_M | $C_WILLCOM_F;
our $C_EMOBILE_M		= 0x0400; # UAに 'emobile/1.0.0' を含む
our $C_EMOBILE_F		= 0x0800;
our $C_EMOBILE			= $C_EMOBILE_M | $C_EMOBILE_F;
our $C_IBIS				= 0x1000;
our $C_JIG				= 0x2000;
our $C_FBSERVICE		= $C_IBIS | $C_JIG;
our $C_MOBILEBROWSER	= $C_DOCOMO_M | $C_AU_M | $C_SOFTBANK_M | $C_WILLCOM_M | $C_EMOBILE_M;
our $C_FULLBROWSER		= $C_DOCOMO_F | $C_AU_F | $C_SOFTBANK_F | $C_WILLCOM_F | $C_EMOBILE_F | $C_FBSERVICE;
our $C_MOBILE			= $C_MOBILEBROWSER | $C_FULLBROWSER;


#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

#============================================================================================================
#
#	�萔���W���[��(ZP)
#
#	by ���낿���˂�v���X
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
#  ���͓��e�Ɋւ���G���[
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
#  �����Ɋւ���G���[
our $E_LIMIT_STOPPEDTHREAD	= 200;
our $E_LIMIT_OVERMAXRES		= 201;
our $E_LIMIT_MOVEDTHREAD	= 202;
our $E_LIMIT_READONLY		= 203;
our $E_LIMIT_MOBILETHREAD	= 204;
our $E_LIMIT_FORBIDDENCGI	= 205;
our $E_LIMIT_OVERDATSIZE	= 206;
our $E_LIMIT_THREADCAPONLY	= 504;
#  �K���Ɋւ���G���[
our $E_REG_MANYTHREAD		= 500;
our $E_REG_NOBREAKPOST		= 501;
our $E_REG_DOUBLEPOST		= 502;
our $E_REG_NOTIMEPOST		= 503;
our $E_REG_SAMBA_CAUTION	= 505; # continuously
our $E_REG_SAMBA_WARNING	= 506; # 505+1
our $E_REG_SAMBA_LISTED		= 507; # 505+2
our $E_REG_SAMBA_STILL		= 508; # 505+3
our $E_REG_SAMBA_2CH1		= 593; # 2ch errnum
our $E_REG_SAMBA_2CH2		= 599; # 2ch errnum
our $E_REG_SAMBA_2CH3		= 594; # 2ch errnum
our $E_REG_NGWORD			= 600;
our $E_REG_NGUSER			= 601;
our $E_REG_NOTJPHOST		= 207;
our $E_REG_DNSBL			= 997;
#  BE�Ɋւ���G���[
our $E_BE_GETFAILED			= 890;
our $E_BE_CONNECTFAILED		= 891;
our $E_BE_LOGINFAILED		= 892;
our $E_BE_MUSTLOGIN			= 893;
our $E_BE_MUSTLOGIN2		= 894;
#  ���N�G�X�g�G���[
our $E_THREAD_INVALIDKEY	= 900;
our $E_THREAD_WRONGLENGTH	= 901;
our $E_THREAD_NOTEXIST		= 902;
our $E_POST_NOPRODUCT		= 950;
our $E_POST_INVALIDREFERER	= 998;
our $E_POST_INVALIDFORM		= 999;
our $E_POST_NOTEXISTBBS		= $E_POST_INVALIDFORM;
our $E_POST_NOTEXISTDAT		= $E_POST_INVALIDFORM;
#  read.cgi�p�G���[
our $E_READ_R_INVALIDBBS	= 1001; # 2ch errnum
our $E_READ_R_INVALIDKEY	= 1002; # 2ch errnum
our $E_READ_FAILEDLOADDAT	= 1003; # 2ch errnum
our $E_READ_FAILEDLOADSET	= 1004; # 2ch errnum
our $E_READ_INVALIDBBS		= 2011; # 2ch errnum
our $E_READ_INVALIDKEY		= 3001; # 2ch errnum
#  �V�X�e���E���̑��̃G���[
our $E_SYSTEM_ERROR			= 990;
#  �y�[�W�\���p�ԍ�
our $E_PAGE_FINDTHREAD		= $E_READ_FAILEDLOADDAT;
our $E_PAGE_THREAD			= 9000;
our $E_PAGE_COOKIE			= 9001;
our $E_PAGE_WRITE			= 9002;
our $E_PAGE_THREADMOBILE	= 9003;


# CAP PERMISSION
our $CAP_FORM_LONGSUBJECT		=  1; # �^�C�g�������� ��������
our $CAP_FORM_LONGNAME			=  2; # ���O������ ��������
our $CAP_FORM_LONGMAIL			=  3; # ���[�������� ��������
our $CAP_FORM_LONGTEXT			=  4; # �{�������� ��������
our $CAP_FORM_MANYLINE			=  5; # �{���s�� ��������
our $CAP_FORM_LONGLINE			=  6; # �{��1�s������ ��������
our $CAP_FORM_NONAME			=  7; # ������ ��������
our $CAP_REG_MANYTHREAD			=  8; # �X���b�h�쐬 �K������
our $CAP_LIMIT_THREADCAPONLY	=  9; # �X���b�h�쐬�\
our $CAP_REG_NOBREAKPOST		= 10; # �A�����e �K������
our $CAP_REG_DOUBLEPOST			= 11; # ��d�������� �K������
our $CAP_REG_NOTIMEPOST			= 12; # �Z���ԓ��e �K������
our $CAP_LIMIT_READONLY			= 13; # �ǎ��p ��������
our $CAP_DISP_NOID				= 14; # ID��\��
our $CAP_DISP_NOHOST			= 15; # �{���z�X�g��\��
our $CAP_LIMIT_MOBILETHREAD		= 16; # �g�т���̃X���b�h�쐬 ��������
our $CAP_DISP_HANLDLE			= 17; # �R�e�n�����\��
our $CAP_REG_SAMBA				= 18; # Samba �K������
our $CAP_REG_DNSBL				= 19; # �v���L�V �K������
our $CAP_REG_NOTJPHOST			= 20; # �C�O�z�X�g �K������
our $CAP_REG_NGUSER				= 21; # ���[�U�[ �K������
our $CAP_REG_NGWORD				= 22; # NG���[�h �K������
our $CAP_DISP_NOSLIP			= 23; # �[�����ʎq��\��
our $CAP_MAXNUM					= 23;
# USER AUTHORITY
our $AUTH_SYSADMIN		=  0; # �V�X�e���Ǘ�����(�`���I��)
our $AUTH_USERGROUP		=  1; # �Ǘ��O���[�v�ݒ�
our $AUTH_CAPGROUP		=  2; # �L���b�v�O���[�v�ݒ�
our $AUTH_THREADSTOP	=  3; # �X���b�h��~�E�ĊJ
our $AUTH_THREADPOOL	=  4; # �X���b�hdat�����E����
our $AUTH_TREADDELETE	=  5; # �X���b�h�폜
our $AUTH_THREADINFO	=  6; # �X���b�h���X�V
our $AUTH_KAKOCREATE	=  7; # �ߋ����O����
our $AUTH_KAKODELETE	=  8; # �ߋ����O�폜
our $AUTH_BBSSETTING	=  9; # �f���ݒ�
our $AUTH_NGWORDS		= 10; # NG���[�h�ҏW
our $AUTH_ACCESUSER		= 11; # �A�N�Z�X�����ҏW
our $AUTH_RESDELETE		= 12; # ���X���ځ[��
our $AUTH_RESEDIT		= 13; # ���X�ҏW
our $AUTH_BBSEDIT		= 14; # �e��ҏW
our $AUTH_LOGVIEW		= 15; # ���O�̉{���E�폜
our $AUTH_MAXNUM		= 15;


# REGEXP
our $RE_SJIS	= '(?:[\x00-\x7f\xa1-\xdf]|[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc])';


#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

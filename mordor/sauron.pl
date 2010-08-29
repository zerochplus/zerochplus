#============================================================================================================
#
#	�Ǘ�CGI�x�[�X���W���[��
#	sauron.pl
#	---------------------------------------------------------------------------
#	2003.10.12 start
#
#============================================================================================================
package	SAURON;

use strict;
use warnings;

require './module/thorin.pl';

#------------------------------------------------------------------------------------------------------------
#
#	���W���[���R���X�g���N�^ - new
#	-------------------------------------------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, @MnuStr, @MnuUrl);
	
	$obj = {
		'SYS'		=> undef,														# MELKOR�ێ�
		'FORM'		=> undef,														# SAMWISE�ێ�
		'INN'		=> undef,														# THORIN�ێ�
		'MNUSTR'	=> \@MnuStr,													# �@�\���X�g������
		'MNUURL'	=> \@MnuUrl,													# �@�\���X�gURL
		'MNUNUM'	=> 0															# �@�\���X�g��
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�I�u�W�F�N�g���� - Create
#	-------------------------------------------------------------------------------------
#	���@���F$M : MELKOR���W���[��
#			$S : SAMWISE���W���[��
#	�߂�l�FTHORIN���W���[��
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($Sys, $Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= THORIN->new;
	$this->{'MNUNUM'}	= 0;
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[�̐ݒ� - SetMenu
#	-------------------------------------------------------------------------------------
#	���@���F$str : �\��������
#			$url : �W�����vURL
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my $this = shift;
	my ($str, $url) = @_;
	
	push @{$this->{'MNUSTR'}}, $str;
	push @{$this->{'MNUURL'}}, $url;
	
	$this->{'MNUNUM'} ++;
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�o�� - Print
#	-------------------------------------------------------------------------------------
#	���@���F$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($ttl, $mode) = @_;
	my ($Tad, $Tin, $TPlus);
	
	$Tad	= THORIN->new;
	$Tin	= $this->{'INN'};
	
	PrintHTML($Tad, $ttl);																# HTML�w�b�_�o��
	PrintCSS($Tad, $this->{'SYS'});														# CSS�o��
	PrintHead($Tad, $ttl, $mode);														# �w�b�_�o��
	PrintList($Tad, $this->{'MNUNUM'}, $this->{'MNUSTR'}, $this->{'MNUURL'});			# �@�\���X�g�o��
	PrintInner($Tad, $Tin, $ttl);														# �@�\���e�o��
	PrintCommonInfo($Tad, $this->{'FORM'});
	PrintFoot($Tad, $this->{'FORM'}->Get('UserName'), $this->{'SYS'}->Get('VERSION'));	# �t�b�^�o��
	
	$Tad->Flush(0, 0, '');																# ��ʏo��
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�o��(���j���[���X�g�Ȃ�) - PrintNoList
#	-------------------------------------------------------------------------------------
#	���@���F$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoList
{
	my $this = shift;
	my ($ttl, $mode) = @_;
	my ($Tad, $Tin);
	
	$Tad = THORIN->new;
	$Tin = $this->{'INN'};
	
	PrintHTML($Tad, $ttl);															# HTML�w�b�_�o��
	PrintCSS($Tad, $this->{'SYS'}, $ttl);											# CSS�o��
	PrintHead($Tad, $ttl, $mode);													# �w�b�_�o��
	PrintInner($Tad, $Tin, $ttl);													# �@�\���e�o��
	PrintFoot($Tad, 'NONE', $this->{'SYS'}->Get('VERSION'));						# �t�b�^�o��
	
	$Tad->Flush(0, 0, '');															# ��ʏo��
}

#------------------------------------------------------------------------------------------------------------
#
#	HTML�w�b�_�o�� - PrintHTML
#	-------------------------------------------
#	���@���F$T   : THORIN���W���[��
#			$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHTML
{
	my ($Page, $ttl) = @_;
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <title>���낿���˂�Ǘ� - [ $ttl ]</title>
 
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�X�^�C���V�[�g�o�� - PrintCSS
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCSS
{
	my ($Page, $Sys, $ttl) = @_;
	my ($data);
	
	$data = $Sys->Get('DATA');
	
$Page->Print(<<HTML);
 <meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
 
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 <meta http-equiv="Content-Style-Type" content="text/css">
 
 <meta name="robots" content="noindex,nofollow">
 
 <link rel="stylesheet" href=".$data/admin.css" type="text/css">
 <script language="javascript" src=".$data/admin.js"></script>
 
</head>
<!--nobanner-->
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�w�b�_�o�� - PrintHead
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#			$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my ($Page, $ttl, $mode) = @_;
	my ($common);
	
	$common = '<a href="javascript:DoSubmit';
	
$Page->Print(<<HTML);
<body>

<form name="ADMIN" action="./admin.cgi" method="POST">

<div class="MainMenu" align="right">
HTML
	
	# �V�X�e���Ǘ����j���[
	if ($mode == 1) {
		
$Page->Print(<<HTML);
 <a href="javascript:DoSubmit('sys.top','DISP','NOTICE');">�g�b�v</a> |
 <a href="javascript:DoSubmit('sys.bbs','DISP','LIST');">�f����</a> |
 <a href="javascript:DoSubmit('sys.user','DISP','LIST');">���[�U�[</a> |
 <a href="javascript:DoSubmit('sys.cap','DISP','LIST');">�L���b�v</a> |
 <a href="javascript:DoSubmit('sys.setting','DISP','INFO');">�V�X�e���ݒ�</a> |
 <a href="javascript:DoSubmit('sys.edit','DISP','BANNER_PC');">�e��ҏW</a> |
HTML
		
	}
	# �f���Ǘ����j���[
	elsif ($mode == 2) {
		
$Page->Print(<<HTML);
 <a href="javascript:DoSubmit('bbs.thread','DISP','LIST');">�X���b�h</a> |
 <a href="javascript:DoSubmit('bbs.pool','DISP','LIST');">�v�[��</a> |
 <a href="javascript:DoSubmit('bbs.kako','DISP','LIST');">�ߋ����O</a> |
 <a href="javascript:DoSubmit('bbs.setting','DISP','SETINFO');">�f���ݒ�</a> |
 <a href="javascript:DoSubmit('bbs.edit','DISP','HEAD');">�e��ҏW</a> |
 <a href="javascript:DoSubmit('bbs.user','DISP','LIST');">�Ǘ��O���[�v</a> |
 <a href="javascript:DoSubmit('bbs.cap','DISP','LIST');">�L���b�v�O���[�v</a> |
 <a href="javascript:DoSubmit('bbs.log','DISP','INFO');">���O�{��</a> |
HTML
		
	}
	# �X���b�h�Ǘ����j���[
	elsif ($mode == 3) {
		
$Page->Print(<<HTML);
 <a href="javascript:DoSubmit('thread.res','DISP','LIST');">���X�ꗗ</a> |
 <a href="javascript:DoSubmit('thread.del','DISP','LIST');">�폜���X�ꗗ</a> |
HTML
		
	}
	
$Page->Print(<<HTML);
 <a href="javascript:DoSubmit('login','','');">���O�I�t</a>
</div>
 
<div class="MainHead" align="right">0ch+ BBS System Manager</div>

<table cellspacing="0" width="100%">
 <tr style="height:400px">
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���X�g�o�� - PrintList
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#			$str : �@�\�^�C�g���z��
#			$url : �@�\URL�z��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintList
{
	my ($Page, $n, $str, $url) = @_;
	my ($i, $strURL, $strTXT);
	
$Page->Print(<<HTML);
  <td align="center" valign="top" class="Content">
  <table width="95%" cellspacing="0">
   <tr>
    <td class="FunctionList">
HTML
	
	for ($i = 0 ; $i < $n ; $i++) {
		$strURL = $$url[$i];
		$strTXT = $$str[$i];
		if ($strURL eq '') {
			$Page->Print("    <font color=\"gray\">$strTXT</font>\n");
			if ($strTXT ne '<hr>') {
				$Page->Print('    <br>'."\n");
			}
		}
		else {
			$Page->Print("    <a href=\"javascript:DoSubmit($$url[$i]);\">");
			$Page->Print("$$str[$i]</a><br>\n");
		}
	}
	
$Page->Print(<<HTML);
    </td>
   </tr>
  </table>
  </td>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���e�o�� - PrintInner
#	-------------------------------------------
#	���@���F$Page1 : THORIN���W���[��(MAIN)
#			$Page2 : THORIN���W���[��(���e)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintInner
{
	my ($Page1, $Page2, $ttl) = @_;
	
$Page1->Print(<<HTML);
  <td width="80%" valign="top" class="Function">
  <div class="FuncTitle">$ttl</div>
HTML
	
	$Page1->Merge($Page2);
	
	$Page1->Print("  </td>\n");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	���ʏ��o�� - PrintCommonInfo
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCommonInfo
{
	my ($Page, $Form) = @_;
	my ($user, $pass);
	
	$user = $Form->Get('UserName');
	$pass = $Form->Get('PassWord');
	
$Page->Print(<<HTML);
  <!-- ������ȂƂ���ɒn���v��(ry -->
   <input type="hidden" name="MODULE" value="">
   <input type="hidden" name="MODE" value="">
   <input type="hidden" name="MODE_SUB" value="">
   <input type="hidden" name="UserName" value="$user">
   <input type="hidden" name="PassWord" value="$pass">
  <!-- ������ȂƂ���ɒn���v��(ry -->
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�o�� - PrintFoot
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my ($Page, $user, $ver) = @_;
	
$Page->Print(<<HTML);
 </tr>
</table>

<div class="MainFoot">
 Copyright 2001 - 2010 0ch BBS : Loggin User - <b>$user</b><br>
 Build Version:<b>$ver</b>
</div>

</form>

</body>
</html>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	������ʂ̏o��
#	-------------------------------------------------------------------------------------
#	@param	$processName	������
#	@param	$pLog	�������O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintComplete
{
	my $this = shift;
	my ($processName, $pLog) = @_;
	my ($Page, $text);
	
	$Page = $this->{'INN'};
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="oExcuted">
     $processName�𐳏�Ɋ������܂����B
    </div>
   
    <div class="LogExport">�������O</div>
    <hr>
    <blockquote class="LogExport">
HTML
	
	# ���O�̕\��
	foreach $text (@$pLog) {
		$Page->Print("     $text<br>\n");
	}
	
$Page->Print(<<HTML);
    </blockquote>
    <hr>
    </td>
   </tr>
  </table>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$pLog	���O�p
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintError
{
	my $this = shift;
	my ($pLog) = @_;
	my ($Page, $ecode);
	
	$Page = $this->{'INN'};
	
	# �G���[�R�[�h�̒��o
	$ecode = pop @$pLog;
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="xExcuted">
HTML
	
	if ($ecode == 1000) {
		$Page->Print("     ERROR:$ecode - �{�@�\\�̏��������s���錠��������܂���B\n");
	}
	elsif ($ecode == 1001) {
		$Page->Print("     ERROR:$ecode - ���͕K�{���ڂ��󗓂ɂȂ��Ă��܂��B\n");
	}
	elsif ($ecode == 1002) {
		$Page->Print("     ERROR:$ecode - �ݒ荀�ڂɋK��O�̕������g�p����Ă��܂��B\n");
	}
	elsif ($ecode == 2000) {
		$Page->Print("     ERROR:$ecode - �f���f�B���N�g���̍쐬�Ɏ��s���܂����B<br>\n");
		$Page->Print("     �p�[�~�b�V�����A�܂��͊��ɓ����̌f�����쐬����Ă��Ȃ������m�F���Ă��������B\n");
	}
	elsif ($ecode == 2001) {
		$Page->Print("     ERROR:$ecode - SETTING.TXT�̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2002) {
		$Page->Print("     ERROR:$ecode - �f���\\���v�f�̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2003) {
		$Page->Print("     ERROR:$ecode - �ߋ����O�������̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2004) {
		$Page->Print("     ERROR:$ecode - �f�����̍X�V�Ɏ��s���܂����B\n");
	}
	else {
		$Page->Print("     ERROR:$ecode - �s���ȃG���[���������܂����B\n");
	}
	
$Page->Print(<<HTML);
    </div>
    
HTML

	# �G���[���O������Ώo�͂���
	if (@$pLog) {
		$Page->Print('<hr>');
		$Page->Print("    <blockquote>");
		foreach (@$pLog) {
			$Page->Print("    $_<br>\n");
		}
		$Page->Print("    </blockquote>");
		$Page->Print('<hr>');
	}
	
$Page->Print(<<HTML);
    </td>
   </tr>
  </table>
HTML
	
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

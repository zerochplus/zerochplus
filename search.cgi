#!/usr/bin/perl
#============================================================================================================
#
#	�����pCGI(�܂������Ă��݂܂���)
#	search.cgi
#	-----------------------------------------------------
#	2003.11.22 star
#	2004.09.16 �V�X�e�����ςɔ����ύX
#	2009.06.19 HTML�����̑啝�ȏ�������
#
#============================================================================================================

use strict;
use warnings;

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(SearchCGI());

#------------------------------------------------------------------------------------------------------------
#
#	CGI���C������ - SearchCGI
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SearchCGI
{
	my ($Sys, $Page, $Form, $BBS);
	
	require './module/melkor.pl';
	require './module/thorin.pl';
	require './module/samwise.pl';
	require './module/nazguls.pl';
	$Sys	= new MELKOR;
	$Page	= new THORIN;
	$Form	= new SAMWISE;
	$BBS	= new NAZGUL;
	
	$Form->DecodeForm(1);
	$Sys->Init();
	$BBS->Load($Sys);
	PrintHead($Sys, $Page, $BBS, $Form);
	
	# �������[�h������ꍇ�͌��������s����
	if ($Form->Get('WORD', '') ne '') {
		Search($Sys, $Form, $Page, $BBS);
	}
	PrintFoot($Sys, $Page);
	$Page->Flush(0, 0, '');
}

#------------------------------------------------------------------------------------------------------------
#
#	�w�b�_�o�� - PrintHead
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my ($Sys, $Page, $BBS, $Form) = @_;
	my ($pBBS, $bbs, $name, $dir, $Banner);
	my ($sMODE, $sBBS, $sKEY, $sWORD, @sTYPE, @cTYPE, $types, @bbsSet, $id);
	
	$sMODE	= $Form->Get('MODE', '');
	$sBBS	= $Form->Get('BBS', '');
	$sKEY	= $Form->Get('KEY', '');
	$sWORD	= $Form->Get('WORD');
	@sTYPE	= $Form->GetAtArray('TYPE', 0);
	
	$types = ($sTYPE[0] || 0) | ($sTYPE[1] || 0) | ($sTYPE[2] || 0);
	$cTYPE[0] = ($types & 1 ? 'checked' : '');
	$cTYPE[1] = ($types & 2 ? 'checked' : '');
	$cTYPE[2] = ($types & 4 ? 'checked' : '');
	
	# �o�i�[�̓ǂݍ���
	require './module/denethor.pl';
	$Banner = new DENETHOR;
	$Banner->Load($Sys);

	$Page->Print("Content-type: text/html;charset=Shift_JIS\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Script-Type" content="text/css">

 <title>������0chPlus</title>

 <link rel="stylesheet" type="text/css" href="./datas/search.css">

</head>
<!--nobanner-->
<body>

<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#ccffcc" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <font size="+1"><b>������0chPlus</b></font>
  
  <div align="center" style="margin:1.2em 0;">
  <form action="./search.cgi" method="POST">
  <table border="0">
   <tr>
    <td>�������[�h</td>
    <td>
    <select name="MODE">
HTML

	if ($sMODE eq 'ALL') {
		$Page->Print(<<HTML);
     <option value="ALL" selected>�I���S����</option>
     <option value="BBS">BBS�w��S����</option>
     <option value="THREAD">�X���b�h�w��S����</option>
HTML
	}
	elsif ($sMODE eq 'BBS' || $sMODE eq '') {
		$Page->Print(<<HTML);
     <option value="ALL">�I���S����</option>
     <option value="BBS" selected>BBS�w��S����</option>
     <option value="THREAD">�X���b�h�w��S����</option>
HTML
	}
	elsif ($sMODE eq 'THREAD') {
		$Page->Print(<<HTML);
     <option value="ALL">�I���S����</option>
     <option value="BBS">BBS�w��S����</option>
     <option value="THREAD" selected>�X���b�h�w��S����</option>
HTML
	}
	$Page->Print(<<HTML);
    </select>
    </td>
   </tr>
   <tr>
    <td>�w��BBS</td>
    <td>
    <select name="BBS">
HTML

	# BBS�Z�b�g�̎擾
	$BBS->GetKeySet('ALL', '', \@bbsSet);
	
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$dir = $BBS->Get('DIR', $id);
		if ($sBBS eq $dir) {
			$Page->Print("     <option value=\"$dir\" selected>$name</option>\n");
		}
		else {
			$Page->Print("     <option value=\"$dir\">$name</option>\n");
		}
	}
	$Page->Print(<<HTML);
    </select>
    </td>
   </tr>
   <tr>
    <td>�w��X���b�h�L�[</td>
    <td>
    <input type="text" size="20" name="KEY" value="$sKEY">
    </td>
   </tr>
   <tr>
    <td>�������[�h</td>
    <td><input type="text" size="40" name="WORD" value="$sWORD"></td>
   </tr>
   <tr>
    <td>�������</td>
    <td>
    <input type="checkbox" name="TYPE" value="1" $cTYPE[0]>���O����<br>
    <input type="checkbox" name="TYPE" value="4" $cTYPE[2]>ID�E���t����<br>
    <input type="checkbox" name="TYPE" value="2" $cTYPE[1]>�{������<br>
    </td>
   </tr>
   <tr>
    <td colspan="2" align="right">
    <hr>
    <input type="submit" value="����" style="width:150px;">
    </td>
   </tr>
  </table>
  </form>
  </div>
  </td>
 </tr>
</table>

HTML

	$Banner->Print($Page, 95, 0, 0) if($Sys->Get('BANNER'));
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�o�� - PrintHead
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my ($Sys, $Page) = @_;
	my ($ver, $cgipath);
	
	$ver = $Sys->Get('VERSION');
	$cgipath	= $Sys->Get('CGIPATH');
	
	$Page->Print(<<HTML);

<div class="foot">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">���낿���˂�</a> <a href="http://zerochplus.sourceforge.jp/">�v���X</a>
SEARCH.CGI - $ver
</div>

HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʏo�� - Search
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my ($Sys, $Form, $Page, $BBS) = @_;;
	my ($Search, $Mode, $Result, @elem, $n, $base, $word);
	my (@types, $Type);
	
	require './module/balrogs.pl';
	$Search = new BALROGS;
	
	$Mode = 0 if ($Form->Equal('MODE', 'ALL'));
	$Mode = 1 if ($Form->Equal('MODE', 'BBS'));
	$Mode = 2 if ($Form->Equal('MODE', 'THREAD'));
	
	@types = $Form->GetAtArray('TYPE', 0);
	$Type = ($types[0] || 0) | ($types[1] || 0) | ($types[2] || 0);
	
	# �����I�u�W�F�N�g�̐ݒ�ƌ����̎��s
#	eval
	{
		$Search->Create($Sys, $Mode, $Type, $Form->Get('BBS', ''), $Form->Get('KEY', ''));
		$Search->Run($Form->Get('WORD'));
	};
	if ($@ ne '') {
		PrintSystemError($Page, $@);
		return;
	}
	
	# �������ʃZ�b�g�擾
	$Result = $Search->GetResultSet();
	$n		= $Result ? @$Result : 0;
	$base	= $Sys->Get('BBSPATH');
	$word	= $Form->Get('WORD');
	
	PrintResultHead($Page, $n);
	
	# �����q�b�g��1���ȏ゠��
	if ($n > 0) {
		require './module/galadriel.pl';
		my $Conv = new GALADRIEL;
		$n = 1;
		foreach (@$Result) {
			@elem = split(/<>/);
			PrintResult($Page, $BBS, $Conv, $n, $base, \@elem);
			$n++;
		}
	}
	# �����q�b�g����
	else {
		PrintNoHit($Page);
	}
	
	PrintResultFoot($Page);
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʃw�b�_�o�� - PrintResultHead
#	------------------------------------------------
#	���@���FPage : �o�̓��W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultHead
{
	my ($Page, $n) = @_;
	
	$Page->Print(<<HTML);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#efefef" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <div class="hit" style="margin-top:1.2em;">
   <b>
   �y�q�b�g���F$n�z
   <font size="+2" color="red">��������</font>
   </b>
  </div>
  <dl>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʓ��e�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResult
{
	my ($Page, $BBS, $Conv, $n, $base, $pResult) = @_;
	my ($name, @bbsSet);
	
	$BBS->GetKeySet('DIR', $$pResult[0], \@bbsSet);
	
	if (@bbsSet > 0) {
		$name = $BBS->Get('NAME', $bbsSet[0]);
		
		$Page->Print("   <dt>$n ���O�F<b>");
		if ($$pResult[4] eq '') {
			$Page->Print("<font color=\"green\">$$pResult[3]</font>");
		}
		else {
			$Page->Print("<a href=\"mailto:$$pResult[4]\">$$pResult[3]</a>");
		}
		
	$Page->Print(<<HTML);
 </b>�F$$pResult[5]</dt>
    <dd>
    $$pResult[6]
    <br>
    <hr>
    <a target="_blank" href="$base/$$pResult[0]/">�y$name�z</a>
    <a target="_blank" href="./read.cgi/$$pResult[0]/$$pResult[1]/">�y�X���b�h�z</a>
    <a target="_blank" href="./read.cgi/$$pResult[0]/$$pResult[1]/$$pResult[2]">�y���X�z</a>
    <br>
    <br>
    </dd>
    
HTML
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʃt�b�^�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultFoot
{
	my ($Page) = @_;
	
	$Page->Print("  </dl>\n  </td>\n </tr>\n</table>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	NoHit�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoHit
{
	my ($Page) = @_;
	
	$Page->Print(<<HTML);
<dt>
 0 ���O�F<font color="forestgreen"><b>�����G���W�\\�����낿���˂�v���X</b></font>�FNo Hit
</dt>
<dd>
 <br>
 <br>
 �Q|�P|���@�ꌏ���q�b�g���܂���ł����B�B<br>
 <br>
</dd>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e���G���[�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$msg	�G���[���b�Z�[�W
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemError
{
	my ($Page, $msg) = @_;
	
	$Page->Print(<<HTML);
<br>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#efefef" align="center">
 <tr>
  <td>
  <dl>
  <div class="title">
  <small><b>�y�q�b�g���F0�z</b></small><font size="+2" color="red">�V�X�e���G���[</font>
  </div>
   <dt>0 ���O�F<font color="forestgreen"><b>�����G���W�\\�����낿���˂�v���X</b></font>�FSystem Error</dt>
    <dd>
    <br>
    <br>
    $msg<br>
    <br>
    <br>
    </dd>
  </dl>
  </td>
 </tr>
</table>
HTML
}

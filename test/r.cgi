#!/usr/bin/perl
#============================================================================================================
#
#	�ǂݏo����pCGI
#	r.cgi
#	-------------------------------------------------------------------------------------
#	2004.04.08 �V�X�e�����ςɔ����V�K�쐬
#
#============================================================================================================

use lib './perllib';

use strict;
use warnings;
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
no warnings 'once';


# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(ReadCGI());

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ReadCGI
{
	my (%SYS, $Page, $err);
	
	require './module/constant.pl';
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# �������E�����ɐ�����������e�\��
	if (($err = Initialize(\%SYS, $Page)) == $ZP::E_SUCCESS) {
		# �w�b�_�\��
		PrintReadHead(\%SYS, $Page);
		
		# ���j���[�\��
		PrintReadMenu(\%SYS, $Page);
		
		# ���e�\��
		PrintReadContents(\%SYS, $Page);
		
		# �t�b�^�\��
		PrintReadFoot(\%SYS, $Page);
	}
	# �������Ɏ��s������G���[�\��
	else {
		# �ΏۃX���b�h��������Ȃ������ꍇ�͒T����ʂ�\������
		if ($err == $ZP::E_PAGE_FINDTHREAD) {
			PrintReadSearch(\%SYS, $Page, $err);
		}
		# ����ȊO�͒ʏ�G���[
		else {
			PrintReadError(\%SYS, $Page, $err);
		}
	}
	
	# �\�����ʂ��o��
	$Page->Flush(0, 0, '');
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi�������E�O����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($pSYS, $Page) = @_;
	my (@elem, @regs, $path);
	my ($oSYS, $oSET, $oCONV, $oDAT);
	
	# �e�g�p���W���[���̐����Ə�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/gondor.pl';
	require './module/galadriel.pl';
	
	$oSYS	= new MELKOR;
	$oSET	= new ISILDUR;
	$oCONV	= new GALADRIEL;
	$oDAT	= new ARAGORN;
	
	%$pSYS = (
		'SYS'	=> $oSYS,
		'SET'	=> $oSET,
		'CONV'	=> $oCONV,
		'DAT'	=> $oDAT,
		'PAGE'	=> $Page,
		'CODE'	=> 'sjis'
	);
	
	# �V�X�e��������
	$oSYS->Init();
	
	# �����L�����
	$oSYS->{'MainCGI'} = $pSYS;
	
	# �N���p�����[�^�̉��
	@elem = $oCONV->GetArgument(\%ENV);
	
	# BBS�w�肪��������
	if (! defined $elem[0] || $elem[0] eq '') {
		return $ZP::E_READ_R_INVALIDBBS;
	}
	# �X���b�h�L�[�w�肪��������
	elsif (! defined $elem[1] || $elem[1] eq '' || ($elem[1] =~ /[^0-9]/) ||
			(length($elem[1]) != 10 && length($elem[1]) != 9)) {
		return $ZP::E_READ_R_INVALIDKEY;
	}
	
	# �V�X�e���ϐ��ݒ�
	$oSYS->Set('MODE', 0);
	$oSYS->Set('BBS', $elem[0]);
	$oSYS->Set('KEY', $elem[1]);
	$oSYS->Set('CLIENT', $oCONV->GetClient());
	$oSYS->Set('AGENT', $oCONV->GetAgentMode($oSYS->Get('CLIENT')));
	$oSYS->Set('BBSPATH_ABS', $oCONV->MakePath($oSYS->Get('CGIPATH'), $oSYS->Get('BBSPATH')));
	$oSYS->Set('BBS_ABS', $oCONV->MakePath($oSYS->Get('BBSPATH_ABS'), $oSYS->Get('BBS')));
	$oSYS->Set('BBS_REL', $oCONV->MakePath($oSYS->Get('BBSPATH'), $oSYS->Get('BBS')));
	
	$path = $oCONV->MakePath($oSYS->Get('BBSPATH')."/$elem[0]/dat/$elem[1].dat");
	
	# dat�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($oDAT->Load($oSYS, $path, 1) == 0) {
		return $ZP::E_READ_FAILEDLOADDAT;
	}
	$oDAT->Close();
	
	# �ݒ�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($oSET->Load($oSYS) == 0) {
		return $ZP::E_READ_FAILEDLOADSET;
	}
	
	# �\���J�n�I���ʒu�̐ݒ�
	@regs = $oCONV->RegularDispNum(
				$oSYS, $oDAT, $elem[2], $elem[3], $elem[4]);
	$oSYS->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi�w�b�_�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadHead
{
	my ($Sys, $Page) = @_;
	my ($Caption, $Banner, $code, $title);
	
	require './module/denethor.pl';
	$Banner = new DENETHOR;
	$Banner->Load($Sys->{'SYS'});
	
	require './module/legolas.pl';
	$Caption = new LEGOLAS;
	$Caption->Load($Sys->{'SYS'}, 'META');
	
	$code	= $Sys->{'CODE'};
	$title	= $Sys->{'DAT'}->GetSubject();
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="ja">
<head>
<meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
<meta http-equiv="Cache-Control" content="no-cache">
HTML
	
	$Caption->Print($Page, undef);
	
$Page->Print(<<HTML);
<title>$title</title>
</head>
<!--nobanner-->
HTML
	
	# <body>�^�O�o��
	{
		$Page->Print('<body>'."\n");
	}
	
	# �o�i�[�o��
	$Banner->Print($Page, 100, 2, 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi���j���[�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadMenu
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $bbs, $key, $baseBBS, $resNum);
#	my ($pathBBS, $pathAll, $pathLast, $pathMenu, $pathNext, $pathPrev);
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	
$Page->Print(<<HTML);
�O4)<a href="#down" accesskey="8">��</a>8)��6) ��1)�V3)<a href="#res" accesskey="7">��</a>7) ��5)
HTML

	# �X���b�h�^�C�g���\��
	{
		my $title	= $Sys->{'DAT'}->GetSubject();
		my $ttlCol	= $Sys->{'SET'}->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr>\n");
		$Page->Print("<font color=\"$ttlCol\" size=\"+1\">$title</font>\n");
		$Page->Print("<a name=\"top\"></a>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi���e�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadContents
{
	my ($Sys, $Page) = @_;
	my ($work, @elem, $i);
	
	$work = $Sys->{'SYS'}->Get('OPTION');
	@elem = split(/\,/, $work);
	
	# 1�\���t���O��TRUE�ŊJ�n��1�łȂ����1��\������
	if ($elem[3] == 0 && $elem[1] != 1) {
		PrintResponse($Sys, $Page, 1, 0);
	}
	# �c��̃��X��\������
	for ($i = $elem[1] ; $i <= $elem[2] ; $i++) {
		PrintResponse($Sys, $Page, $i, $elem[2]);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi�t�b�^�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadFoot
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $Conv, $bbs, $key, $ver, $rmax, $pathNext, $pathPrev);
	my ($baseBBS, $pathBBS, $pathAll, $pathLast, $resNum, $cgipath);
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$Conv		= $Sys->{'CONV'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$ver		= $oSYS->Get('VERSION');
	$rmax		= $oSYS->Get('RESMAX');
	
	$cgipath	= $oSYS->Get('CGIPATH');
	$baseBBS	= $oSYS->Get('BBS_ABS');
	$pathBBS	= $Conv->MakePath("$baseBBS/i/index.html");
	$pathAll	= $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, '1-10n');
	$pathLast	= $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, 'l10');
	$resNum		= $Sys->{'DAT'}->Size();
	
	# �O�A���ԍ��̎擾
	{
		my ($st, $ed, $b1, $b2, $f1, $f2);
		
		$st = $oSYS->GetOption(2);
		$ed = $oSYS->GetOption(3);
		$b1 = ($st - 11 > 0) ? ($st - 11) : 1;
		$b2 = ($b1 == 1) ? 10 : ($b1 + 10);
		$f1 = ($ed + 1 < $rmax) ? ($ed + 1) : $rmax;
		$f2 = ($ed + 10 < $rmax) ? ($ed + 10) : $rmax;
		
		$pathNext = $Conv->CreatePath($oSYS, 1, $bbs, $key, "${f1}-${f2}n");
		$pathPrev = $Conv->CreatePath($oSYS, 1, $bbs, $key, "${b1}-${b2}n");
	}
	$Page->Print('<hr>');
	
	# ���j���[�̕\��
	$Page->Print("<a href=\"#top\" accesskey=\"2\">��</a>");
	$Page->Print("<a href=\"$pathPrev\" accesskey=\"4\">�O</a>");
	$Page->Print("<a href=\"$pathNext\" accesskey=\"6\">��</a>");
	$Page->Print("<a href=\"$pathLast?guid=ON\" accesskey=\"3\">�V</a>");
	$Page->Print("<a href=\"$pathAll\" accesskey=\"1\">1-</a>");
	$Page->Print("<a href=\"$pathBBS\" accesskey=\"5\">��</a>");
	
	# ���e�t�H�[���̕\��
	# ���X�ő吔�𒴂��Ă���ꍇ�̓t�H�[���\�����Ȃ�
	if ($rmax > $Sys->{'DAT'}->Size()) {
$Page->Print(<<HTML);
<hr>
<a name=res></a>
<form method="POST" action="$cgipath/bbs.cgi?guid=ON">
<input type="hidden" name="bbs" value="$bbs">
<input type="hidden" name="key" value="$key">
<input type="hidden" name="mb" value="on">
���O<br><input type="text" name="FROM"><br>
E-mail<br><input type="text" name="mail"><br>
<textarea rows="3" wrap="off" name="MESSAGE"></textarea>
<br><input type="submit" value="��������"><br>
HTML
	}
	$Page->Print("<small>$ver</small></form></body></html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi���X�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($Sys, $Page, $n, $last) = @_;
	my ($oSYS, $oConv, $pDat, @elem, $maxLen, $len, $resNum);
	
	$oSYS	= $Sys->{'SYS'};
	$oConv	= $Sys->{'CONV'};
	$pDat	= $Sys->{'DAT'}->Get($n -1);
	@elem	= split(/<>/, $$pDat);
	$len	= length $elem[3];
	$maxLen	= $Sys->{'SET'}->Get('BBS_LINE_NUMBER');
	$maxLen	= int($maxLen * 5);
	$resNum	= $Sys->{'DAT'}->Size();
	
	# �\���͈͓����w��\���Ȃ炷�ׂĕ\������
	if ($oSYS->GetOption(5) == 1 || $len <= $maxLen) {
		$oConv->ConvertURL($oSYS, $Sys->{'SET'}, 1, \$elem[3]);
		$oConv->ConvertQuotation($oSYS, \$elem[3], 1);
	}
	# �\���͈͂𒴂��Ă�����ȗ��\��������
	else {
		my ($bbs, $key, $path);
		
		$bbs		= $oSYS->Get('BBS');
		$key		= $oSYS->Get('KEY');
		$elem[3]	= $oConv->DeleteText(\$elem[3], $maxLen);
		$maxLen		= (($_ = $len - length($elem[3])) + 20 - ($_ % 20 || 20)) / 20;
		$path		= $oConv->CreatePath($oSYS, 1, $bbs, $key, "${n}n");
		
		$oConv->ConvertURL($oSYS, $Sys->{'SET'}, 1, \$elem[3]);
		$oConv->ConvertQuotation($oSYS, \$elem[3], 1);
		
		#if ($maxLen) {
			$elem[3] .= " <a href=\"$path\">��$maxLen</a>";
		#}
	}
	
	# AAS�����N�擾
	my ( $server, $path, $obama );
	
	$server	= $oSYS->Get('SERVER') || $ENV{'SERVER_NAME'};
	$server	=~ s|http://||i;
	$path	= $oConv->MakePath($server.$oSYS->Get('BBSPATH_ABS'));
	$path	=~ s|/|+|gi;
	$path	= $oConv->MakePath($path, $oSYS->Get('BBS'));
	$obama	= 'http://example.ddo.jp' . $oConv->MakePath("/aas/a.i/$path/".$oSYS->Get('KEY')."/$n?guid=ON");
		
	$Page->Print("<a name=\"down\"></a>") if ( $n == $last );
	$Page->Print("<hr>[$n]$elem[0]</b>�F$elem[2]<br><a href=\"$obama\">AAS</a><br>$elem[3]<br>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi�T����ʕ\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadSearch
{
	my ($Sys, $Page, $err) = @_;
	
	# ���݂��Ȃ��̂�404��Ԃ��B
	$Page->Print("Status: 404 Not Found\n");
	
	# ���G���[�y�[�W
	PrintReadError(\%SYS, $Page, $err);
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi�G���[�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadError
{
	my ($Sys, $Page, $err) = @_;
	my $code;
	
	$code = 'Shift_JIS';
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>�d�q�q�n�q�I�I</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}


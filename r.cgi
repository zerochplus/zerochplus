#!/usr/bin/perl
#============================================================================================================
#
#	�ǂݏo����pCGI
#	r.cgi
#	-------------------------------------------------------------------------------------
#	2004.04.08 �V�X�e�����ςɔ����V�K�쐬
#
#============================================================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);

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
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# �������E�����ɐ�����������e�\��
	if (($err = Initialize(\%SYS, $Page)) == 0) {
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
		if ($err == 1003) {
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
	
	# �e�g�p���W���[���̐����Ə�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/gondor.pl';
	require './module/galadriel.pl';
	
	my ($oSYS, $oSET, $oCONV, $oDAT);
	
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
	$pSYS->{'SYS'}->Init();
	
	# �����L�����
	$pSYS->{'SYS'}->{'MainCGI'} = $pSYS;
	
	# �N���p�����[�^�̉��
	@elem = $pSYS->{'CONV'}->GetArgument(\%ENV);
	
	# BBS�w�肪��������
	if ($elem[0] eq '') {
		return 1001;
	}
	# �X���b�h�L�[�w�肪��������
	elsif ($elem[1] eq '' || $elem[1] =~ /[^0-9]/ || length($elem[1]) != 10) {
		return 1002;
	}
	
	# �V�X�e���ϐ��ݒ�
	$pSYS->{'SYS'}->Set('MODE', 0);
	$pSYS->{'SYS'}->Set('BBS', $elem[0]);
	$pSYS->{'SYS'}->Set('KEY', $elem[1]);
	$pSYS->{'SYS'}->Set('AGENT', $elem[7]);
	
	$path = $pSYS->{'SYS'}->Get('BBSPATH') . "/$elem[0]/dat/$elem[1].dat";
	
	# dat�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($pSYS->{'DAT'}->Load($pSYS->{'SYS'}, $path, 1) == 0) {
		return 1003;
	}
	$pSYS->{'DAT'}->Close();
	
	# �ݒ�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($pSYS->{'SET'}->Load($pSYS->{'SYS'}) == 0) {
		return 1004;
	}
	
	# �\���J�n�I���ʒu�̐ݒ�
	@regs = $pSYS->{'CONV'}->RegularDispNum(
				$pSYS->{'SYS'}, $pSYS->{'DAT'}, $elem[2], $elem[3], $elem[4]);
	$pSYS->{'SYS'}->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);
	
	return 0;
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
	my ($pathBBS, $pathAll, $pathLast, $pathMenu, $pathNext, $pathPrev);
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$baseBBS	= $oSYS->Get('SERVER') . '/' . $bbs;
	$pathBBS	= $baseBBS . '/i/index.html';
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
		$f1 = ($ed + 1 < $resNum) ? ($ed + 1) : $resNum;
		$f2 = ($ed + 10 < $resNum) ? ($ed + 10) : $resNum;
		
		$pathNext = $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, "${f1}-${f2}n");
		$pathPrev = $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, "${b1}-${b2}n");
	}
	
	# ���j���[�̕\��
	$Page->Print("<a href=\"$pathBBS\" accesskey=\"5\">��</a>");
	$Page->Print("<a href=\"$pathAll\" accesskey=\"1\">1-</a>");
	$Page->Print("<a href=\"$pathPrev\" accesskey=\"4\">�O</a>");
	$Page->Print("<a href=\"$pathNext\" accesskey=\"6\">��</a>");
	$Page->Print("<a href=\"$pathLast?guid=ON\" accesskey=\"3\">�V</a>");
	$Page->Print("<a href=\"#res\" accesskey=\"7\">ڽ</a>\n");
	
	# �X���b�h�^�C�g���\��
	{
		my $title	= $Sys->{'DAT'}->GetSubject();
		my $ttlCol	= $Sys->{'SET'}->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr>\n<font color=$ttlCol size=+1>$title</font><br>\n");
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
		PrintResponse($Sys, $Page, 1);
	}
	# �c��̃��X��\������
	for ($i = $elem[1] ; $i <= $elem[2] ; $i++) {
		PrintResponse($Sys, $Page, $i);
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
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$Conv		= $Sys->{'CONV'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$ver		= $oSYS->Get('VERSION');
	$rmax		= $oSYS->Get('RESMAX');
	
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
	$Page->Print("<a href=\"$pathPrev\">�O</a> ");
	$Page->Print("<a href=\"$pathNext\">��</a><hr><a name=res></a>");
	
	# ���e�t�H�[���̕\��
	# ���X�ő吔�𒴂��Ă���ꍇ�̓t�H�[���\�����Ȃ�
	if ($rmax > $Sys->{'DAT'}->Size()) {
		my ($tm, $cgiPath);
		
		$tm			= time;
		$cgiPath	= $oSYS->Get('SERVER') . $oSYS->Get('CGIPATH');
		
		$Page->Print("<form method=\"POST\" action=\"$cgiPath/bbs.cgi?guid=ON\" utn>\n");
		$Page->Print("<input type=hidden name=bbs value=$bbs>");
		$Page->Print("<input type=hidden name=key value=$key>");
		$Page->Print("<input type=hidden name=time value=$tm>");
		$Page->Print("\n���O<br><input type=text name=\"FROM\"><br>");
		$Page->Print('E-mail<br><input type=text name="mail"><br>');
		$Page->Print('<textarea rows=3 wrap=off name="MESSAGE"></textarea>');
		$Page->Print('<br><input type=submit value="��������"><br>');
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
	my ($Sys, $Page, $n) = @_;
	my ($oSYS, $oConv, $pDat, @elem, $maxLen, $len);
	
	$oSYS	= $Sys->{'SYS'};
	$oConv	= $Sys->{'CONV'};
	$pDat	= $Sys->{'DAT'}->Get($n -1);
	@elem	= split(/<>/, $$pDat);
	$len	= length $elem[3];
	$maxLen	= $Sys->{'SET'}->Get('BBS_LINE_NUMBER');
	$maxLen	= int($maxLen * 5);
	
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
	$Page->Print("<hr>[$n]$elem[0]</b>�F$elem[2]<br>$elem[3]<br>\n");
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
	my ($Sys, $Page) = @_;
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


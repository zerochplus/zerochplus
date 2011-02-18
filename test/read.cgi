#!/usr/bin/perl
#============================================================================================================
#
#	�ǂݏo����pCGI
#	read.cgi
#	-------------------------------------------------------------------------------------
#	2002.12.04 start
#	2004.04.04 �V�X�e�����ςɔ����ύX
#
#	���낿���˂�v���X
#	2010.08.12 �V�X�e�����ςɔ����ύX
#
#============================================================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
no warnings 'once';

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(ReadCGI());

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���C��
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
			PrintReadSearch(\%SYS, $Page);
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
#	read.cgi�������E�O����
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
		'CODE'	=> 'Shift_JIS'
	);
	
	# �V�X�e��������
	$oSYS->Init();
	
	# �����L�����
	$oSYS->{'MainCGI'} = $pSYS;
	
	# �N���p�����[�^�̉��
	@elem = $oCONV->GetArgument(\%ENV);
	
	# BBS�w�肪��������
	if (! defined $elem[0] || $elem[0] eq '') {
		return 2011;
	}
	# �X���b�h�L�[�w�肪��������
	elsif (! defined $elem[1] || $elem[1] eq '' || ($elem[1] =~ /[^0-9]/) ||
			(length($elem[1]) != 10 && length($elem[1]) != 9)) {
		return 3001;
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
	
	# �ݒ�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($oSET->Load($oSYS) == 0) {
		return 1004;
	}
	
	$path = $oCONV->MakePath($oSYS->Get('BBSPATH')."/$elem[0]/dat/$elem[1].dat");
	
	# dat�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($oDAT->Load($oSYS, $path, 1) == 0) {
		return 1003;
	}
	$oDAT->Close();
	
	# �\���J�n�I���ʒu�̐ݒ�
	@regs = $oCONV->RegularDispNum(
				$oSYS, $oDAT, $elem[2], $elem[3], $elem[4]);
	$oSYS->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�w�b�_�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> ���m���\�����C�Ӑݒ�ł���悤�ɂȂ����̂ŕύX
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadHead
{
	my ($Sys, $Page, $title) = @_;
	my ($Caption, $Banner, $code);
	
	require './module/legolas.pl';
	require './module/denethor.pl';
	$Caption = new LEGOLAS;
	$Banner = new DENETHOR;
	
	$Caption->Load($Sys->{'SYS'}, 'META');
	$Banner->Load($Sys->{'SYS'});
	
	$code	= $Sys->{'CODE'};
	$title	= $Sys->{'DAT'}->GetSubject() if(! defined $title || $title eq '');
	$title	= '' if(! defined $title);
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Style-Type" content="text/css">

HTML

	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>�^�O�o��
	{
		my @work;
		$work[0] = $Sys->{'SET'}->Get('BBS_THREAD_COLOR');
		$work[1] = $Sys->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $Sys->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $Sys->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $Sys->{'SET'}->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n\n");
	}
	
	# �o�i�[�o��
	$Banner->Print($Page, 100, 2, 0) if ($Sys->{'SYS'}->Get('BANNER'));
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���j���[�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadMenu
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $bbs, $key, $baseBBS, $baseCGI, $st, $ed, $i, $resNum);
	my ($pathBBS, $pathAll, $pathLast, $pathMenu, $account);
	my ($PRtext, $PRlink);
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$baseBBS	= $oSYS->Get('BBS_ABS');
	$baseCGI	= $oSYS->Get('SERVER') . $oSYS->Get('CGIPATH');
	$account	= $oSYS->Get('COUNTER');
	$PRtext		= $oSYS->Get('PRTEXT');
	$PRlink		= $oSYS->Get('PRLINK');
	$pathBBS	= $baseBBS;
	$pathAll	= $Sys->{'CONV'}->CreatePath($oSYS, 0, $bbs, $key, '');
	$pathLast	= $Sys->{'CONV'}->CreatePath($oSYS, 0, $bbs, $key, 'l50');
	$resNum		= $Sys->{'DAT'}->Size();
	
	# �J�E���^�[�\��
	$Page->Print("<div style=\"margin:0px;\">\n");
	$Page->Print('<a href="http://ofuda.cc/"><img width="400" height="15" border="0" src="http://e.ofuda.cc/');
	$Page->Print("disp/$account/00813400.gif\" alt=\"�����A�N�Z�X�J�E���^�[ofuda.cc�u�S���E�J�E���g�v��v\"></a>\n");
	
	$Page->Print("<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <span style=\"float:left;\">\n");
	$Page->Print(" <a href=\"$pathBBS/\">���f���ɖ߂遡</a>\n");
	$Page->Print(" <a href=\"$pathAll\">�S��</a>\n");
	
	# �X���b�h���j���[��\��
	for ($i = 0 ; $i < 10 ; $i++) {
		if ($resNum > $i * 100) {
			$st = $i * 100 + 1;
			$ed = ($i + 1) * 100;
			$pathMenu = $Sys->{'CONV'}->CreatePath($oSYS, 0, $bbs, $key, "$st-$ed");
			$Page->Print(" <a href=\"$pathMenu\">$st-</a>\n");
		}
		else {
			last;
		}
	}
	$Page->Print(" <a href=\"$pathLast\">�ŐV50</a>\n");
	$Page->Print(" </span>\n");
	$Page->Print(" <span style=\"float:right;\">\n [PR]");
	$Page->Print("<a href=\"$PRlink\" target=\"_blank\">$PRtext</a>");
	$Page->Print("[PR]\n </span>&nbsp;\n");
	$Page->Print("</div>\n");
	$Page->Print("</div>\n\n");
	
	# ���X�����E�x���\��
	{
		my $rmax = $oSYS->Get('RESMAX');
		
		if ($resNum >= $rmax) {
			$Page->Print('<div style="background-color:red;color:white;line-height:3em;margin:1px;padding:1px;">'."\n");
			$Page->Print("���X����$rmax�𒴂��Ă��܂��B�c�O�Ȃ���S���͕\\�����܂���B\n");
			$Page->Print('</div>'."\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 20)) {
			$Page->Print('<div style="background-color:red;color:white;margin:1px;padding:1px;">'."\n");
			$Page->Print("���X����".($rmax-int($rmax/20))."�𒴂��Ă��܂��B$rmax�𒴂���ƕ\\���ł��Ȃ��Ȃ��B\n");
			$Page->Print('</div>'."\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 10)) {
			$Page->Print('<div style="background-color:yellow;margin:1px;padding:1px;">'."\n");
			$Page->Print("���X����".($rmax-int($rmax/10))."�𒴂��Ă��܂��B$rmax�𒴂���ƕ\\���ł��Ȃ��Ȃ��B\n");
			$Page->Print('</div>'."\n\n");
		}
	}
	
	# �X���b�h�^�C�g���\��
	{
		my $title	= $Sys->{'DAT'}->GetSubject();
		my $ttlCol	= $Sys->{'SET'}->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:$ttlCol;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("<dl class=\"thread\">\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���e�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadContents
{
	my ($Sys, $Page) = @_;
	my ($work, @elem, $i, $Plugin);
	
	# �g���@�\���[�h
	require './module/athelas.pl';
	$Plugin = new ATHELAS;
	$Plugin->Load($Sys->{'SYS'});
	
	# �L���Ȋg���@�\�ꗗ���擾
	my (@pluginSet, @commands, $id, $count);
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	$count = 0;
	foreach $id (@pluginSet) {
		# �^�C�v��read.cgi�̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & 4) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = new PLUGINCONF($Plugin, $id);
				$commands[$count] = $className->new($Config);
				$count++;
			}
		}
	}
	
	$work	= $Sys->{'SYS'}->Get('OPTION');
	@elem	= split(/\,/, $work);
	
	# 1�\���t���O��TRUE�ŊJ�n��1�łȂ����1��\������
	if ($elem[3] == 0 && $elem[1] != 1) {
		PrintResponse($Sys, $Page, \@commands, 1);
	}
	# �c��̃��X��\������
	for ($i = $elem[1] ; $i <= $elem[2] ; $i++) {
		PrintResponse($Sys, $Page, \@commands, $i);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�t�b�^�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadFoot
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $Conv, $bbs, $key, $ver, $rmax, $datPath, $datSize, $Cookie, $server, $cgipath);
	
	# �O����
	$oSYS		= $Sys->{'SYS'};
	$Conv		= $Sys->{'CONV'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$ver		= $oSYS->Get('VERSION');
	$rmax		= $oSYS->Get('RESMAX');
	$datPath	= $Conv->MakePath($oSYS->Get('BBS_REL')."/dat/$key.dat");
	$datSize	= int((stat $datPath)[7] / 1024);
	$cgipath	= $oSYS->Get('CGIPATH');
	
	# dat�t�@�C���̃T�C�Y�\��
	$Page->Print("</dl>\n\n<font color=\"red\" face=\"Arial\"><b>${datSize}KB</b></font>\n\n");
	
	# ���Ԑ���������ꍇ�͐����\��
	if ($oSYS->Get('LIMTIME')) {
		$Page->Print('�@(08:00PM - 02:00AM �̊Ԉ�C�ɑS���͓ǂ߂܂���)');
	}
	$Page->Print('<hr>'."\n");
	
	# �t�b�^���j���[�̕\��
	{
		my ($pathBBS, $pathAll, $pathPrev, $pathNext, $pathLast);
		my (@elem, $nxt, $nxs, $prv, $prs);
		
		# ���j���[�����N�̍��ڐݒ�
		@elem	= split(/\,/, $oSYS->Get('OPTION'));
		$nxt	= ($elem[2] + 100 > $rmax ? $rmax : $elem[2] + 100);
		$nxs	= $elem[2];
		$prv	= ($elem[1] - 100 < 1 ? 1 : $elem[1] - 100);
		$prs	= $prv + 100;
		
		# �V���̕\��
		if ($rmax > $Sys->{'DAT'}->Size()) {
			my $dispStr = ($Sys->{'DAT'}->Size() == $elem[2] ? '�V�����X�̕\\��' : '������ǂ�');
			my $pathNew = $Conv->CreatePath($oSYS, 0, $bbs, $key, "$elem[2]-");
			$Page->Print("<center><a href=\"$pathNew\">$dispStr</a></center>\n");
			$Page->Print("<hr>\n\n");
		}
		
		# �p�X�̐ݒ�
		$pathBBS	= $oSYS->Get('BBS_ABS');
		$pathAll	= $Conv->CreatePath($oSYS, 0, $bbs, $key, '');
		$pathPrev	= $Conv->CreatePath($oSYS, 0, $bbs, $key, "$prv-$prs");
		$pathNext	= $Conv->CreatePath($oSYS, 0, $bbs, $key, "$nxs-$nxt");
		$pathLast	= $Conv->CreatePath($oSYS, 0, $bbs, $key, 'l50');
		
		$Page->Print("<div class=\"links\">\n");
		$Page->Print("<a href=\"$pathBBS/\">�f���ɖ߂�</a>\n");
		$Page->Print("<a href=\"$pathAll\">�S��</a>\n");
		$Page->Print("<a href=\"$pathPrev\">�O100</a>\n");
		$Page->Print("<a href=\"$pathNext\">��100</a>\n");
		$Page->Print("<a href=\"$pathLast\">�ŐV50</a>\n");
		$Page->Print("</div>\n");
	}
	
	# ���e�t�H�[���̕\��
	# ���X�ő吔�𒴂��Ă���ꍇ�̓t�H�[���\�����Ȃ�
	if ($rmax > $Sys->{'DAT'}->Size()) {
		my ($tm, $cookName, $cookMail);
		
		$cookName = '';
		$cookMail = '';
		
		# cookie�ݒ�ON����cookie���擾����
		if (($oSYS->Get('CLIENT') & $ZP::C_PC) && $Sys->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
			require './module/radagast.pl';
			$Cookie = new RADAGAST;
			$Cookie->Init();
			$cookName = $Cookie->Get('NAME', '');
			$cookMail = $Cookie->Get('MAIL', '');
		}
		$tm			= time;
		
		$Page->Print(<<HTML);
<form method="POST" action="$cgipath/bbs.cgi">
<input type="hidden" name="bbs" value="$bbs"><input type="hidden" name="key" value="$key"><input type="hidden" name="time" value="$tm">
<input type="submit" value="��������">
���O�F<input type="text" name="FROM" value="$cookName" size="19">
E-mail<font size="1">�i�ȗ��j</font>�F<input type="text" name="mail" value="$cookMail" size="19"><br>
<textarea rows="5" cols="70" name="MESSAGE"></textarea>
</form>
HTML
		
	}
	
$Page->Print(<<HTML);
<div style="margin-top:4em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
READ.CGI - $ver<br>
<a href="http://0ch.mine.nu/">���낿���˂�</a> :: <a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���X�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($Sys, $Page, $commands, $n) = @_;
	my ($oConv, @elem, $nameCol, $pDat, $command);
	
	$oConv		= $Sys->{'CONV'};
	$pDat		= $Sys->{'DAT'}->Get($n - 1);
	@elem		= split(/<>/, $$pDat);
	$nameCol	= $Sys->{'SET'}->Get('BBS_NAME_COLOR');
	
	# URL�ƈ��p���̓K��
	$oConv->ConvertURL($Sys->{'SYS'}, $Sys->{'SET'}, 0, \$elem[3]);
	$oConv->ConvertQuotation($Sys->{'SYS'}, \$elem[3], 0);
	
	# �g���@�\�����s
	$Sys->{'SYS'}->Set('_DAT_', \@elem);
	$Sys->{'SYS'}->Set('_NUM_', $n);
	foreach $command (@$commands) {
		$command->execute($Sys->{'SYS'}, undef, 4);
	}
	
	$Page->Print(" <dt>$n �F");
	
	# ���[�����L��
	if ($elem[1] eq "") {
		$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
	}
	# ���[��������
	else {
		$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
	}
	$Page->Print("�F$elem[2]</dt>\n");
	$Page->Print("  <dd>$elem[3]<br><br></dd>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�T����ʕ\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadSearch
{
	my ($Sys, $Page) = @_;
	if (PrintDiscovery($Sys, $Page)) { return; }
	my ($oSys, $oDat, $oConv, $size, $i, $nameCol);
	my (@elem, $pDat, $var, $cgipath, $bbs, $server);
	
	$oSys		= $Sys->{'SYS'};
	$oDat		= $Sys->{'DAT'};
	$oConv		= $Sys->{'CONV'};
	$nameCol	= $Sys->{'SET'}->Get('BBS_NAME_COLOR');
	$var		= $oSys->Get('VERSION');
	$cgipath	= $oSys->Get('CGIPATH');
	$bbs		= $oSys->Get('BBS_ABS') . '/';
	$server		= $oSys->Get('SERVER');
	
	# �G���[�pdat�̓ǂݍ���
	$oDat->Load($oSys, $oConv->MakePath('.'.$oSys->Get('DATA').'/2000000000.dat'), 1);
	$size = $oDat->Size();
	
	# ���݂��Ȃ��̂�404��Ԃ��B
	$Page->Print("Status: 404 Not Found\n");
	
	PrintReadHead($Sys, $Page);
	
	$Page->Print("\n<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <a href=\"$bbs\">���f���ɖ߂遡</a>\n");
	$Page->Print("</div>\n");
	
	$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
	$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">�w�肳�ꂽ�X���b�h�͑��݂��܂���</h1>\n\n");
	
	$Page->Print("\n<dl class=\"thread\">\n");
	
	for ($i = 0 ; $i < $size ; $i++) {
		$pDat = $oDat->Get($i);
		@elem = split(/<>/, $$pDat);
		$Page->Print(' <dt>' . ($i + 1) . ' �F');
		
		# ���[�����L��
		if ($elem[1] eq '') {
			$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
		}
		# ���[��������
		else {
			$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
		}
		$Page->Print("�F$elem[2]</dt>\n  <dd>$elem[3]<br><br></dd>\n");
	}
	$Page->Print("</dl>\n\n");
	$Page->Print("<hr>\n\n");
	
	$Page->Print(<<HTML);
<div style="margin-top:4em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
READ.CGI - $var<br>
<a href="http://0ch.mine.nu/">���낿���˂�</a> :: <a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�G���[�\��
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

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�ߋ����O�q�ɒT��
#	--------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���O���ǂ��ɂ�������Ȃ���� 0 ��Ԃ�
#			���O������Ȃ� 1 ��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintDiscovery
{
	my ($Sys, $Page) = @_;
	my ($spath, $lpath, $key, $kh, $pathBBS, $ver, $server, $title, $cgipath, $Conv);
	
	$Conv		= $Sys->{'CONV'};
	$cgipath	= $Sys->{'SYS'}->Get('CGIPATH');
	$spath		= $Sys->{'SYS'}->Get('BBS_REL');
	$lpath		= $Sys->{'SYS'}->Get('BBS_ABS');
	$key		= $Sys->{'SYS'}->Get('KEY');
	$kh			= substr($key, 0, 4) . '/' . substr($key, 0, 5);
	$ver		= $Sys->{'SYS'}->Get('VERSION');
	$server		= $Sys->{'SYS'}->Get('SERVER');
	
	if (-e $Conv->MakePath("$spath/kako/$kh/$key.html")) {
		my $path = $Conv->MakePath("$lpath/kako/$kh/$key");
		
		# �ߋ����O�ɂ���
		$title = "�����I�ߋ����O�q�ɂ�";
		PrintReadHead($Sys, $Page, $title);
		$Page->Print("\n<div style=\"margin-top:1em;\">\n");
		$Page->Print(" <a href=\"$lpath/\">���f���ɖ߂遡</a>\n");
		$Page->Print("</div>\n\n");
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("\n<blockquote>\n");
		$Page->Print("����! �ߋ����O�q�ɂŁA�X���b�h <a href=\"$path.html\">$server$path.html</a>");
		$Page->Print(" <a href=\"$path.dat\">.dat</a> �𔭌����܂����B");
		$Page->Print("</blockquote>\n");
		
	}
	elsif (-e $Conv->MakePath("$spath/pool/$key.cgi")) {
		
		# pool�ɂ���
		$title = "html���҂��ł��c";
		PrintReadHead($Sys, $Page, $title);
		$Page->Print("\n<div style=\"margin-top:1em;\">\n");
		$Page->Print(" <a href=\"$lpath/\">���f���ɖ߂遡</a>\n");
		$Page->Print("</div>\n\n");
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("\n<blockquote>\n");
		$Page->Print("$key.dat��html����҂��Ă��܂��B");
		$Page->Print('�����͑҂����Ȃ��E�E�E�B<br>'."\n");
		$Page->Print("</blockquote>\n");
		
	}
	else {
		
		# �ǂ��ɂ��Ȃ�
		return 0;
		
	}
	
	$Page->Print(<<HTML);

<hr>

<div style="margin-top:4em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
READ.CGI - $ver<br>
<a href="http://0ch.mine.nu/">���낿���˂�</a> :: <a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
	
	return 1;
	
}

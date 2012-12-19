#!/usr/bin/perl
#============================================================================================================
#
#	�ǂݏo����pCGI
#
#============================================================================================================

use lib './perllib';

use strict;
use warnings;
no warnings 'once';
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


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
	require './module/constant.pl';
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	my $CGI = {};
	my $err = Initialize($CGI, $Page);
	
	# �������E�����ɐ�����������e�\��
	if ($err == $ZP::E_SUCCESS) {
		# �w�b�_�\��
		PrintReadHead($CGI, $Page);
		
		# ���j���[�\��
		PrintReadMenu($CGI, $Page);
		
		# ���e�\��
		PrintReadContents($CGI, $Page);
		
		# �t�b�^�\��
		PrintReadFoot($CGI, $Page);
	}
	# �������Ɏ��s������G���[�\��
	else {
		# �ΏۃX���b�h��������Ȃ������ꍇ�͒T����ʂ�\������
		if ($err == $ZP::E_PAGE_FINDTHREAD) {
			PrintReadSearch($CGI, $Page);
		}
		# ����ȊO�͒ʏ�G���[
		else {
			PrintReadError($CGI, $Page, $err);
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
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($CGI, $Page) = @_;
	
	# �e�g�p���W���[���̐����Ə�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/gondor.pl';
	require './module/galadriel.pl';
	
	my $Sys = MELKOR->new;
	my $Conv = GALADRIEL->new;
	my $Set = ISILDUR->new;
	my $Dat = ARAGORN->new;
	
	%$CGI = (
		'SYS'		=> $Sys,
		'SET'		=> $Set,
		'CONV'		=> $Conv,
		'DAT'		=> $Dat,
		'PAGE'		=> $Page,
		'CODE'		=> 'Shift_JIS',
	);
	
	# �V�X�e��������
	$Sys->Init();
	
	# �����L�����
	$Sys->Set('MainCGI', $CGI);
	
	# �N���p�����[�^�̉��
	my @elem = $Conv->GetArgument(\%ENV);
	
	# BBS�w�肪��������
	if (!defined $elem[0] || $elem[0] eq '') {
		return $ZP::E_READ_INVALIDBBS;
	}
	# �X���b�h�L�[�w�肪��������
	elsif (!defined $elem[1] || $elem[1] eq '' || ($elem[1] =~ /[^0-9]/) ||
			(length($elem[1]) != 10 && length($elem[1]) != 9)) {
		return $ZP::E_READ_INVALIDKEY;
	}
	
	# �V�X�e���ϐ��ݒ�
	$Sys->Set('MODE', 0);
	$Sys->Set('BBS', $elem[0]);
	$Sys->Set('KEY', $elem[1]);
	$Sys->Set('CLIENT', $Conv->GetClient());
	$Sys->Set('AGENT', $Conv->GetAgentMode($Sys->Get('CLIENT')));
	$Sys->Set('BBSPATH_ABS', $Conv->MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH')));
	$Sys->Set('BBS_ABS', $Conv->MakePath($Sys->Get('BBSPATH_ABS'), $Sys->Get('BBS')));
	$Sys->Set('BBS_REL', $Conv->MakePath($Sys->Get('BBSPATH'), $Sys->Get('BBS')));
	
	# �ݒ�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($Set->Load($Sys) == 0) {
		return $ZP::E_READ_FAILEDLOADSET;
	}
	
	my $path = $Conv->MakePath($Sys->Get('BBSPATH')."/$elem[0]/dat/$elem[1].dat");
	
	# dat�t�@�C���̓ǂݍ��݂Ɏ��s
	if ($Dat->Load($Sys, $path, 1) == 0) {
		return $ZP::E_READ_FAILEDLOADDAT;
	}
	$Dat->Close();
	
	# �\���J�n�I���ʒu�̐ݒ�
	my @regs = $Conv->RegularDispNum(
				$Sys, $Dat, $elem[2], $elem[3], $elem[4]);
	$Sys->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�w�b�_�o��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$title
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadHead
{
	my ($CGI, $Page, $title) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Dat = $CGI->{'DAT'};
	
	require './module/legolas.pl';
	require './module/denethor.pl';
	my $Caption = LEGOLAS->new;
	my $Banner = DENETHOR->new;
	
	$Caption->Load($Sys, 'META');
	$Banner->Load($Sys);
	
	my $code = $CGI->{'CODE'};
	$title = $Dat->GetSubject() if(!defined $title);
	$title = '' if(!defined $title);
	
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
		$work[0] = $Set->Get('BBS_THREAD_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n\n");
	}
	
	# �o�i�[�o��
	$Banner->Print($Page, 100, 2, 0) if ($Sys->Get('BANNER'));
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���j���[�o��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadMenu
{
	my ($CGI, $Page) = @_;
	
	# �O����
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Dat = $CGI->{'DAT'};
	my $Conv = $CGI->{'CONV'};
	
	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $baseBBS = $Sys->Get('BBS_ABS');
	my $baseCGI = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	my $account = $Sys->Get('COUNTER');
	my $PRtext = $Sys->Get('PRTEXT');
	my $PRlink = $Sys->Get('PRLINK');
	my $pathBBS = $baseBBS;
	my $pathAll = $Conv->CreatePath($Sys, 0, $bbs, $key, '');
	my $pathLast = $Conv->CreatePath($Sys, 0, $bbs, $key, 'l50');
	my $resNum = $Dat->Size();
	
	$Page->Print("<div style=\"margin:0px;\">\n");
	
	# �J�E���^�[�\��
	if ($account ne '') {
		$Page->Print('<a href="http://ofuda.cc/"><img width="400" height="15" border="0" src="http://e.ofuda.cc/');
		$Page->Print("disp/$account/00813400.gif\" alt=\"�����A�N�Z�X�J�E���^�[ofuda.cc�u�S���E�J�E���g�v��v\"></a>\n");
	}
	
	$Page->Print("<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <span style=\"float:left;\">\n");
	$Page->Print(" <a href=\"$pathBBS/\">���f���ɖ߂遡</a>\n");
	$Page->Print(" <a href=\"$pathAll\">�S��</a>\n");
	
	# �X���b�h���j���[��\��
	for my $i (0 .. 9) {
		last if ($resNum <= $i * 100);
		
		my $st = $i * 100 + 1;
		my $ed = ($i + 1) * 100;
		my $pathMenu = $Conv->CreatePath($Sys, 0, $bbs, $key, "$st-$ed");
		$Page->Print(" <a href=\"$pathMenu\">$st-</a>\n");
	}
	$Page->Print(" <a href=\"$pathLast\">�ŐV50</a>\n");
	$Page->Print(" </span>\n");
	$Page->Print(" <span style=\"float:right;\">\n");
	if ($PRtext ne '') {
		$Page->Print(" [PR]<a href=\"$PRlink\" target=\"_blank\">$PRtext</a>[PR]\n");
	}
	else {
		$Page->Print(" &nbsp;\n");
	}
	$Page->Print(" </span>&nbsp;\n");
	$Page->Print("</div>\n");
	$Page->Print("</div>\n\n");
	
	# ���X�����E�x���\��
	{
		my $rmax = $Sys->Get('RESMAX');
		
		if ($resNum >= $rmax) {
			$Page->Print("<div style=\"background-color:red;color:white;line-height:3em;margin:1px;padding:1px;\">\n");
			$Page->Print("���X����$rmax�𒴂��Ă��܂��B�c�O�Ȃ���S���͕\\�����܂���B\n");
			$Page->Print("</div>\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 20)) {
			$Page->Print("<div style=\"background-color:red;color:white;margin:1px;padding:1px;\">\n");
			$Page->Print("���X����".($rmax-int($rmax/20))."�𒴂��Ă��܂��B$rmax�𒴂���ƕ\\���ł��Ȃ��Ȃ��B\n");
			$Page->Print("</div>\n\n");
		}
		elsif ($resNum >= $rmax - int($rmax / 10)) {
			$Page->Print("<div style=\"background-color:yellow;margin:1px;padding:1px;\">\n");
			$Page->Print("���X����".($rmax-int($rmax/10))."�𒴂��Ă��܂��B$rmax�𒴂���ƕ\\���ł��Ȃ��Ȃ��B\n");
			$Page->Print("</div>\n\n");
		}
	}
	
	# �X���b�h�^�C�g���\��
	{
		my $title = $Dat->GetSubject();
		my $ttlCol = $Set->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
		$Page->Print("<h1 style=\"color:$ttlCol;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">$title</h1>\n\n");
		$Page->Print("<dl class=\"thread\">\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���e�o��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadContents
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	
	# �g���@�\���[�h
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	# �L���Ȋg���@�\�ꗗ���擾
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	
	my $count = 0;
	my @commands = ();
	foreach my $id (@pluginSet) {
		# �^�C�v��read.cgi�̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & 4) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			
			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = PLUGINCONF->new($Plugin, $id);
				$commands[$count] = $className->new($Config);
				$count++;
			}
		}
	}
	
	my $work = $Sys->Get('OPTION');
	my @elem = split(/\,/, $work);
	
	# 1�\���t���O��TRUE�ŊJ�n��1�łȂ����1��\������
	if ($elem[3] == 0 && $elem[1] != 1) {
		PrintResponse($CGI, $Page, \@commands, 1);
	}
	# �c��̃��X��\������
	for my $i ($elem[1] .. $elem[2]) {
		PrintResponse($CGI, $Page, \@commands, $i);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�t�b�^�o��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadFoot
{
	my ($CGI, $Page) = @_;
	
	# �O����
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};
	
	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $ver = $Sys->Get('VERSION');
	my $rmax = $Sys->Get('RESMAX');
	my $datPath = $Conv->MakePath($Sys->Get('BBS_REL')."/dat/$key.dat");
	my $datSize = int((stat $datPath)[7] / 1024);
	my $cgipath = $Sys->Get('CGIPATH');
	
	# dat�t�@�C���̃T�C�Y�\��
	$Page->Print("</dl>\n\n<font color=\"red\" face=\"Arial\"><b>${datSize}KB</b></font>\n\n");
	
	# ���Ԑ���������ꍇ�͐����\��
	if ($Sys->Get('LIMTIME')) {
		$Page->Print('�@(08:00PM - 02:00AM �̊Ԉ�C�ɑS���͓ǂ߂܂���)');
	}
	$Page->Print("<hr>\n");
	
	# �t�b�^���j���[�̕\��
	{
		# ���j���[�����N�̍��ڐݒ�
		my @elem = split(/\,/, $Sys->Get('OPTION'));
		my $nxt = ($elem[2] + 100 > $rmax ? $rmax : $elem[2] + 100);
		my $nxs = $elem[2];
		my $prv = ($elem[1] - 100 < 1 ? 1 : $elem[1] - 100);
		my $prs = $prv + 100;
		
		# �V���̕\��
		if ($rmax > $Dat->Size()) {
			my $dispStr = ($Dat->Size() == $elem[2] ? '�V�����X�̕\\��' : '������ǂ�');
			my $pathNew = $Conv->CreatePath($Sys, 0, $bbs, $key, "$elem[2]-");
			$Page->Print("<center><a href=\"$pathNew\">$dispStr</a></center>\n");
			$Page->Print("<hr>\n\n");
		}
		
		# �p�X�̐ݒ�
		my $pathBBS = $Sys->Get('BBS_ABS');
		my $pathAll = $Conv->CreatePath($Sys, 0, $bbs, $key, '');
		my $pathPrev = $Conv->CreatePath($Sys, 0, $bbs, $key, "$prv-$prs");
		my $pathNext = $Conv->CreatePath($Sys, 0, $bbs, $key, "$nxs-$nxt");
		my $pathLast = $Conv->CreatePath($Sys, 0, $bbs, $key, 'l50');
		
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
	if ($rmax > $Dat->Size()) {
		my $cookName = '';
		my $cookMail = '';
		my $tm = time;
		
		# cookie�ݒ�ON����cookie���擾����
		if (($Sys->Get('CLIENT') & $ZP::C_PC) && $Set->Equal('SUBBBS_CGI_ON', 1)) {
			require './module/radagast.pl';
			my $Cookie = RADAGAST->new;
			$Cookie->Init();
			$cookName = $Cookie->Get('NAME', '');
			$cookMail = $Cookie->Get('MAIL', '');
		}
		
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
READ.CGI - $ver<br>
<a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi���X�\��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$commands
#	@param	$n
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($CGI, $Page, $commands, $n) = @_;
	
	# �O����
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};
	
	my $pDat = $Dat->Get($n - 1);
	my @elem = split(/<>/, $$pDat);
	my $nameCol	= $Set->Get('BBS_NAME_COLOR');
	
	# URL�ƈ��p���̓K��
	$Conv->ConvertURL($Sys, $Set, 0, \$elem[3]);
	$Conv->ConvertQuotation($Sys, \$elem[3], 0);
	
	# �g���@�\�����s
	$Sys->Set('_DAT_', \@elem);
	$Sys->Set('_NUM_', $n);
	foreach my $command (@$commands) {
		$command->execute($Sys, undef, 4);
	}
	
	$Page->Print(" <dt>$n �F");
	
	# ���[�����L��
	if ($elem[1] eq '') {
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
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadSearch
{
	my ($CGI, $Page) = @_;
	
	return if (PrintDiscovery($CGI, $Page));
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Dat = $CGI->{'DAT'};
	
	my $nameCol = $Set->Get('BBS_NAME_COLOR');
	my $var = $Sys->Get('VERSION');
	my $cgipath = $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS_ABS') . '/';
	my $server = $Sys->Get('SERVER');
	
	# �G���[�pdat�̓ǂݍ���
	$Dat->Load($Sys, $Conv->MakePath('.'.$Sys->Get('DATA').'/2000000000.dat'), 1);
	my $size = $Dat->Size();
	
	# ���݂��Ȃ��̂�404��Ԃ��B
	$Page->Print("Status: 404 Not Found\n");
	
	PrintReadHead($CGI, $Page);
	
	$Page->Print("\n<div style=\"margin-top:1em;\">\n");
	$Page->Print(" <a href=\"$bbs\">���f���ɖ߂遡</a>\n");
	$Page->Print("</div>\n");
	
	$Page->Print("<hr style=\"background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;\">\n\n");
	$Page->Print("<h1 style=\"color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;\">�w�肳�ꂽ�X���b�h�͑��݂��܂���</h1>\n\n");
	
	$Page->Print("\n<dl class=\"thread\">\n");
	
	for my $i (0 .. $size - 1) {
		my $pDat = $Dat->Get($i);
		my @elem = split(/<>/, $$pDat);
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
READ.CGI - $var<br>
<a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi�G���[�\��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$err
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadError
{
	my ($CGI, $Page, $err) = @_;
	
	my $code = $CGI->{'CODE'};
	
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
#	@param	$CGI
#	@param	$Page
#	@return	���O���ǂ��ɂ�������Ȃ���� 0 ��Ԃ�
#			���O������Ȃ� 1 ��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintDiscovery
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Conv = $CGI->{'CONV'};
	
	my $cgipath = $Sys->Get('CGIPATH');
	my $spath = $Sys->Get('BBS_REL');
	my $lpath = $Sys->Get('BBS_ABS');
	my $key = $Sys->Get('KEY');
	my $kh = substr($key, 0, 4) . '/' . substr($key, 0, 5);
	my $ver = $Sys->Get('VERSION');
	my $server = $Sys->Get('SERVER');
	
	# �ߋ����O�ɂ���
	if (-e $Conv->MakePath("$spath/kako/$kh/$key.html")) {
		my $path = $Conv->MakePath("$lpath/kako/$kh/$key");
		
		my $title = "�����I�ߋ����O�q�ɂ�";
		PrintReadHead($CGI, $Page, $title);
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
	# pool�ɂ���
	elsif (-e $Conv->MakePath("$spath/pool/$key.cgi")) {
		my $title = "html���҂��ł��c";
		PrintReadHead($CGI, $Page, $title);
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
	# �ǂ��ɂ��Ȃ�
	else {
		return 0;
	}
	
	$Page->Print(<<HTML);

<hr>

<div style="margin-top:4em;">
READ.CGI - $ver<br>
<a href="http://zerochplus.sourceforge.jp/">���낿���˂�v���X</a>
</div>

</body>
</html>
HTML
	
	return 1;
}

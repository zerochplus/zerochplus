#!/usr/bin/perl
#============================================================================================================
#
#	index�X�V�pCGI
#	remake.cgi
#	-------------------------------------------------------------------------------------
#	2006.08.05 bbs.cgi����K�v�ȕ������������o��
#
#============================================================================================================

use strict;
use warnings;

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(REMAKECGI());
#------------------------------------------------------------------------------------------------------------
#
#	remake.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub REMAKECGI
{
	my (%SYS, $Page, $err);
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# �������ɐ���������X�V�������J�n
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		require './module/baggins.pl';
		require './module/varda.pl';
		my $Threads = BILBO->new;
		my $BBSAid = new VARDA;
		my $Sys = $SYS{'SYS'};
		
		# subject.txt
		#$Threads->Load($Sys);
		$Threads->UpdateAll($Sys);
		$Threads->Save($Sys);
		
		# index.html
		$BBSAid->Init($Sys, $SYS{'SET'});
		$BBSAid->CreateIndex();
		$BBSAid->CreateIIndex();
		$BBSAid->CreateSubback();
		
		PrintBBSJump(\%SYS, $Page);
	}
	else {
		PrintBBSError(\%SYS, $Page, $err);
	}
	
	# ���ʂ̕\��
	$Page->Flush('', 0, 0);
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	remake.cgi������
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($Sys, $Page) = @_;
	my ($bbs);
	
	# �g�p���W���[���̏�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/radagast.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	%$Sys = (
		'SYS'		=> new MELKOR,
		'SET'		=> new ISILDUR,
		'COOKIE'	=> new RADAGAST,
		'CONV'		=> new GALADRIEL,
		'FORM'		=> SAMWISE->new(1),
		'PAGE'		=> $Page,
	);
	
	# form���ݒ�
	$Sys->{'FORM'}->DecodeForm(1);
	
	# �V�X�e�����ݒ�
	if ($Sys->{'SYS'}->Init()) {
		return 990;
	}
	
	# �����L�����
	$Sys->{'SYS'}->{'MainCGI'} = $Sys;
	
	$bbs = $Sys->{'FORM'}->Get('bbs', '');
	$Sys->{'SYS'}->Set('BBS', $bbs);
	if ($bbs eq '' || $bbs =~ /[^A-Za-z0-9_\-\.]/ || ! -d $Sys->{'SYS'}->Get('BBSPATH') . "/$bbs") {
		return 999;
	}
	
	$Sys->{'SYS'}->Set('AGENT', $Sys->{'CONV'}->GetAgentMode($ENV{'HTTP_USER_AGENT'}));
	$Sys->{'SYS'}->Set('MODE', 'CREATE');
	
	# SETTING.TXT�̓ǂݍ���
	if (! $Sys->{'SET'}->Load($Sys->{'SYS'})) {
		return 999;
	}
	
	return 0;
}


#------------------------------------------------------------------------------------------------------------
#
#	remake.cgi�W�����v�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($Sys, $Page) = @_;
	my ($SYS, $bbsPath);
	
	$SYS		= $Sys->{'SYS'};
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	
	# �g�їp�\��
	if (!$SYS->Equal('AGENT', 0)) {
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>index���X�V���܂����B<br>');
		$Page->Print("<a href=\"$bbsPath/i/\">������</a>");
		$Page->Print("����f���֖߂��Ă��������B\n");
	}
	# PC�p�\��
	else {
		my $oSET = $Sys->{'SET'};
		
		$Page->Print("Content-type: text/html\n\n<html><head><title>");
		$Page->Print('index���X�V���܂����B</title><!--nobanner-->');
		$Page->Print('<meta http-equiv="Content-Type" content="text/html; ');
		$Page->Print("charset=Shift_JIS\"><meta content=0;URL=$bbsPath/ ");
		$Page->Print('http-equiv=refresh></head><body>index���X�V���܂����B');
		$Page->Print('<br><br>��ʂ�؂�ւ���܂ł��΂炭���҂��������B');
		$Page->Print('<br><br><br><br><br><hr>');
		
	}
	# ���m���\��(�\�����������Ȃ��ꍇ�̓R�����g�A�E�g��������0��)
	if (0) {
		require './module/denethor.pl';
		my $BANNER = new DENETHOR;
		$BANNER->Load($SYS);
		$BANNER->Print($Page, 100, 0, $SYS->Get('AGENT'));
	}
	$Page->Print('</body></html>');
}

#------------------------------------------------------------------------------------------------------------
#
#	remake.cgi�G���[�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($Sys, $Page, $err) = @_;
	my ($ERROR);
	
	require './module/orald.pl';
	$ERROR = new ORALD;
	$ERROR->Load($Sys->{'SYS'});
	
	$ERROR->Print($Sys, $Page, $err, $Sys->{'SYS'}->Get('AGENT'));
}


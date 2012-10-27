#!/usr/bin/perl
#============================================================================================================
#
#	�V�X�e���Ǘ�CGI
#
#============================================================================================================

use lib './perllib';

use strict;
use warnings;
no warnings 'once';
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(AdminCGI());

#------------------------------------------------------------------------------------------------------------
#
#	admin.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�G���[�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub AdminCGI
{
	# �V�X�e�������ݒ�
	my $CGI = {};
	SystemSetting($CGI);
	
	# 0ch�V�X�e�������擾
	require "./module/melkor.pl";
	my $Sys = MELKOR->new;
	$Sys->Init();
	$Sys->Set('BBS', '');
	$CGI->{'SECINFO'}->Init($Sys);
	
	# �����L�����
	$Sys->Set('ADMIN', $CGI);
	$Sys->Set('MainCGI', $CGI);
	
	# �t�H�[�������擾
	require "./module/samwise.pl";
	my $Form = SAMWISE->new(0);
	$Form->DecodeForm(0);
	$Form->Set('FALSE', 0);
	
	# ���O�C�����[�U�ݒ�
	my $name = $Form->Get('UserName', '');
	my $pass = $Form->Get('PassWord', '');
	my $userID = $CGI->{'SECINFO'}->IsLogin($name, $pass);
	$CGI->{'USER'} = $userID;
	
	# �o�[�W�����`�F�b�N
	my $upcheck = $Sys->Get('UPCHECK', 1) - 0;
	$CGI->{'NEWRELEASE'}->Init($Sys);
	if ($upcheck) {
		$CGI->{'NEWRELEASE'}->Set('Interval', 24*60*60*$upcheck);
		$CGI->{'NEWRELEASE'}->Check;
	}
	
	# �������W���[���I�u�W�F�N�g�̐���
	my $modName = $Form->Get('MODULE', 'login');
	$modName = 'login' if (!$userID);
	require "./mordor/$modName.pl";
	my $oModule = MODULE->new;
	
	# �\�����[�h
	if ($Form->Get('MODE', '') eq 'DISP') {
		$oModule->DoPrint($Sys, $Form, $CGI);
	}
	# �@�\���[�h
	elsif ($Form->Get('MODE', '') eq 'FUNC') {
		$oModule->DoFunction($Sys, $Form, $CGI);
	}
	# ���O�C��
	else {
		$oModule->DoPrint($Sys, $Form, $CGI);
	}
	
	$CGI->{'LOGGER'}->Write();
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�Ǘ��V�X�e���ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$pSYS	�V�X�e���Ǘ��n�b�V���̎Q��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SystemSetting
{
	my ($CGI) = @_;
	
	%$CGI = (
		'SECINFO'	=> undef,		# �Z�L�����e�B���
		'LOGGER'	=> undef,		# ���O�I�u�W�F�N�g
		'AD_BBS'	=> undef,		# BBS���I�u�W�F�N�g
		'AD_DAT'	=> undef,		# dat���I�u�W�F�N�g
		'USER'		=> undef,		# ���O�C�����[�UID
		'NEWRELEASE'=> undef,		# �o�[�W�����`�F�b�N
	);
	
	require './module/elves.pl';
	require './module/imrahil.pl';
	require './module/newrelease.pl';
	
	$CGI->{'SECINFO'} = ARWEN->new;
	$CGI->{'LOGGER'} = IMRAHIL->new;
	$CGI->{'LOGGER'}->Open('./info/AdminLog', 100, 2 | 4);
	$CGI->{'NEWRELEASE'} = ZP_NEWRELEASE->new;
}


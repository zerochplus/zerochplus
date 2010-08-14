#!/usr/bin/perl
#============================================================================================================
#
#	�V�X�e���Ǘ�CGI
#	admin.cgi
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(AdminCGI());

#------------------------------------------------------------------------------------------------------------
#
#	admin.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub AdminCGI
{
	my ($Sys, $Form, %SYS);
	my ($oModule, $modName, $userID);
	
	# �V�X�e�������ݒ�
	SystemSetting(\%SYS);
	
	# 0ch�V�X�e�������擾
	require "$SYS{'MAINCGI'}/module/melkor.pl";
	$Sys = new MELKOR;
	$Sys->Init();
	$Sys->Set('ADMIN', \%SYS);
	$SYS{'SECINFO'}->Init($Sys);
	
	# �t�H�[�������擾
	require "$SYS{'MAINCGI'}/module/samwise.pl";
	$Form = new SAMWISE;
	$Form->DecodeForm(0);
	
	# ���O�C�����[�U�ݒ�
	$userID	= $SYS{'SECINFO'}->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
	$SYS{'USER'} = $userID;
	
	# �������W���[�������擾
	$modName = $Form->Get('MODULE') eq '' ? 'login' : $Form->Get('MODULE');
	
	# �������W���[���I�u�W�F�N�g�̐���
	require "./mordor/$modName.pl";
	$oModule = new MODULE;
	
	# �\�����[�h
	if ($Form->Get('MODE') eq 'DISP') {
		$oModule->DoPrint($Sys, $Form, \%SYS);
	}
	# �@�\���[�h
	elsif ($Form->Get('MODE') eq 'FUNC') {
		$oModule->DoFunction($Sys, $Form, \%SYS);
	}
	# ���O�C��
	else {
		$oModule->DoPrint($Sys, $Form, \%SYS);
	}
	$SYS{'LOGGER'}->Write();
	
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
	my ($pSYS) = @_;
	
	%$pSYS = (
		'MAINCGI'	=> '../test',	# cgi�ݒu�p�X(���Ή�)
		'SECINFO'	=> undef,		# �Z�L�����e�B���
		'LOGGER'	=> undef,		# ���O�I�u�W�F�N�g
		'AD_BBS'	=> undef,		# BBS���I�u�W�F�N�g
		'AD_DAT'	=> undef,		# dat���I�u�W�F�N�g
		'USER'		=> undef		# ���O�C�����[�UID
	);
	
	require './module/elves.pl';
	require './module/imrahil.pl';
	
	$pSYS->{'SECINFO'}	= new ARWEN;
	$pSYS->{'LOGGER'}	= new IMRAHIL;
	$pSYS->{'LOGGER'}->Open('./info/AdminLog', 100, 2 | 4);
}


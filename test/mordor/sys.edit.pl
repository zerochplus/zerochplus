#============================================================================================================
#
#	�V�X�e���Ǘ� - �ҏW ���W���[��
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	
	my $obj = {
		'LOG'	=> [],
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	require './mordor/sauron.pl';
	my $Base = SAURON->new;
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# PC�p���m�ҏW���
	if ($subMode eq 'BANNER_PC') {
		$indata = PreparePageBannerForPCEdit($Sys, $Form);
	}
	# �g�їp���m�ҏW���
	elsif ($subMode eq 'BANNER_MOBILE') {
		$indata = PreparePageBannerForMobileEdit($Sys, $Form);
	}
	# �T�u���m�ҏW���
	elsif ($subMode eq 'BANNER_SUB') {
		$indata = PreparePageBannerForSubEdit($Sys, $Form);
	}
	# �V�X�e���ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('�V�X�e���ҏW����', $this->{'LOG'});
	}
	# �V�X�e���ݒ莸�s���
	elsif ($subMode eq 'FALSE') {
		$indata = $Base->PreparePageError($this->{'LOG'});
	}
	
	$Base->Print($Sys->Get('_TITLE'), 1, $indata);
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	my $subMode = $Form->Get('MODE_SUB');
	my $err = 0;
	
	# PC�p���m
	if ($subMode eq 'BANNER_PC') {
		$err = FunctionBannerEdit($Sys, $Form, 1, $this->{'LOG'});
	}
	# �g�їp���m
	elsif ($subMode eq 'BANNER_MOBILE') {
		$err = FunctionBannerEdit($Sys, $Form, 2, $this->{'LOG'});
	}
	# �T�u�o�i�[
	elsif ($subMode eq 'BANNER_SUB') {
		$err = FunctionBannerEdit($Sys, $Form, 3, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_EDIT($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_EDIT($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	$Base->SetMenu('���m�ҏW(PC�p)', "'sys.edit','DISP','BANNER_PC'");
	$Base->SetMenu('���m�ҏW(�g�їp)', "'sys.edit','DISP','BANNER_MOBILE'");
	$Base->SetMenu('���m�ҏW(�T�u)', "'sys.edit','DISP','BANNER_SUB'");
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(PC)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForPCEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $bgColor;
	my $content;
	
	# ���m���v���r���[�\��
	if ($Form->IsExist('PC_CONTENT')) {
		$Banner->Set('COLPC', $Form->Get('PC_BGCOLOR'));
		$Banner->Set('TEXTPC', $Form->Get('PC_CONTENT'));
		$bgColor = $Form->Get('PC_BGCOLOR');
		$content = $Form->Get('PC_CONTENT');
	}
	else {
		$bgColor = $Banner->Get('COLPC');
		$content = $Banner->Get('TEXTPC');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $bdata = $Banner->Prepare(100, 0, 0);
	
	my $indata = {
		'title'		=> 'PC Banner Edit',
		'intmpl'	=> 'sys.edit.bannerpc',
		'banner'	=> $bdata,
		'bgcolor'	=> $bgColor,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(�g��)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForMobileEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $bgColor;
	my $content;
	
	# ���m���v���r���[�\��
	if ($Form->IsExist('MOBILE_CONTENT')) {
		$Banner->Set('COLMB', $Form->Get('MOBILE_BGCOLOR'));
		$Banner->Set('TEXTMB', $Form->Get('MOBILE_CONTENT'));
		$bgColor = $Form->Get('MOBILE_BGCOLOR');
		$content = $Form->Get('MOBILE_CONTENT');
	}
	else {
		$bgColor = $Banner->Get('COLMB');
		$content = $Banner->Get('TEXTMB');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $bdata = $Banner->Prepare(100, 0, 1);
	
	my $indata = {
		'title'		=> 'Mobile Banner Edit',
		'intmpl'	=> 'sys.edit.bannermb',
		'banner'	=> $bdata,
		'bgcolor'	=> $bgColor,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(�T�u)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForSubEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $content;
	
	# ���m���v���r���[�\��
	if ($Form->IsExist('SUB_CONTENT')) {
		$Banner->Set('TEXTSB', $Form->Get('SUB_CONTENT'));
		$content = $Form->Get('SUB_CONTENT');
	}
	else {
		$content = $Banner->Get('TEXTSB');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $bdata = $Banner->PrepareSub();
	
	my $indata = {
		'title'		=> 'Sub Banner Edit',
		'intmpl'	=> 'sys.edit.bannersub',
		'banner'	=> $bdata,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���m���ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBannerEdit
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���̓`�F�b�N
	if ($mode == 1) {
		return 1001 if (!$Form->IsInput([qw(PC_CONTENT PC_BGCOLOR)]));
	} elsif ($mode == 2) {
		return 1001 if (!$Form->IsInput([qw(MOBILE_CONTENT MOBILE_BGCOLOR)]));
	}
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	if ($mode == 1) {
		$Banner->Set('TEXTPC', $Form->Get('PC_CONTENT'));
		$Banner->Set('COLPC', $Form->Get('PC_BGCOLOR'));
		push @$pLog, 'PC�p���m����ݒ肵�܂����B';
	}
	elsif ($mode == 2) {
		$Banner->Set('TEXTMB', $Form->Get('MOBILE_CONTENT'));
		$Banner->Set('COLMB', $Form->Get('MOBILE_BGCOLOR'));
		push @$pLog, '�g�їp���m����ݒ肵�܂����B';
	}
	elsif ($mode == 3) {
		$Banner->Set('TEXTSB', $Form->Get('SUB_CONTENT'));
		push @$pLog, '�T�u�o�i�[��ݒ肵�܂����B';
	}
	
	# �ݒ�̕ۑ�
	$Banner->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

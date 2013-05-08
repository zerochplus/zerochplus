#============================================================================================================
#
#	�V�X�e���Ǘ� - ���[�U ���W���[��
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
	
	# �X���b�h�ꗗ���
	if ($subMode eq 'LIST') {
		$indata = PreparePageUserList($Sys, $Form);
	}
	# ���[�U�쐬���
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageUserSetting($Sys, $Form, 0);
	}
	# ���[�U�ҏW���
	elsif ($subMode eq 'EDIT') {
		$indata = PreparePageUserSetting($Sys, $Form, 1);
	}
	# ���[�U�폜�m�F���
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageUserDelete($Sys, $Form);
	}
	# ���[�U�ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('���[�U�[����', $this->{'LOG'});
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
	
	# ���[�U�쐬
	if ($subMode eq 'CREATE') {
		$err = FuncUserSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# ���[�U�ҏW
	elsif ($subMode eq 'EDIT') {
		$err = FuncUserSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# ���[�U�폜
	elsif ($subMode eq 'DELETE') {
		$err = FuncUserDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "USER($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"USER($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('���[�U�[�ꗗ', "'sys.user','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('���[�U�[�o�^', "'sys.user','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# ���[�U���̓ǂݍ���
	require './module/elves.pl';
	my @userSet = ();
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# �\�����̐ݒ�
	my $listnum = scalar(@userSet);
	my $dispnum = int($Form->Get('DISPNUM', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	# �ʒm�ꗗ���o��
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $userSet[$nextnum++];
		
		push @$displist, {
			'id'	=> $id,
			'name'	=> $User->Get('NAME', $id),
			'full'	=> $User->Get('FULL', $id),
			'expl'	=> $User->Get('EXPL', $id),
		};
		last if (scalar(@$displist) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Users List',
		'intmpl'	=> 'sys.user.userlist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'users'		=> $displist,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# ���[�U���̓ǂݍ���
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	my $user = {
		'name'	=> '',
		'pass'	=> '',
		'expl'	=> '',
		'full'	=> '',
		'sysad'	=> 0,
	};
	
	my $seluser = '';
	
	# �ҏW���[�h�Ȃ烆�[�U�����擾����
	if ($mode) {
		$seluser = $Form->Get('SELECT_USER');
		$user->{'name'} = $User->Get('NAME', $seluser);
		$user->{'pass'} = $User->Get('PASS', $seluser);
		$user->{'expl'} = $User->Get('EXPL', $seluser);
		$user->{'full'} = $User->Get('FULL', $seluser);
		$user->{'sysad'} = $User->Get('SYSAD', $seluser);
	}
	
	my $indata = {
		'title'		=> 'Users '.($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.user.useredit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'seluser'	=> $seluser,
		'user'		=> $user,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserDelete
{
	my ($Sys, $Form) = @_;
	
	# ���[�U���̓ǂݍ���
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# �ʒm�ꗗ���o��
	my $users = [];
	my @userSet = $Form->GetAtArray('USERS');
	foreach my $id (@userSet) {
		next if (!defined $User->Get('NAME', $id));
		push @$users, {
			'id'	=> $id,
			'name'	=> $User->Get('NAME', $id),
			'full'	=> $User->Get('FULL', $id),
			'expl'	=> $User->Get('EXPL', $id),
		};
	}
	
	my $indata = {
		'title'		=> 'User Delete Confirm',
		'intmpl'	=> 'sys.user.userdelete',
		'users'		=> $users,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�쐬/�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�ҏW:1, �쐬:0
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FuncUserSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���̓`�F�b�N
	return 1001 if (!$Form->IsInput([qw(NAME PASS)]));
	return 1002 if (!$Form->IsAlphabet([qw(NAME PASS)]));
	
	# ���[�U���̓ǂݍ���
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# �ݒ���͏����擾
	my $name = $Form->Get('NAME');
	my $pass = $Form->Get('PASS');
	my $expl = $Form->Get('EXPL');
	my $full = $Form->Get('FULL');
	my $sysad = $Form->Equal('SYSAD', 'on') ? 1 : 0;
	my $chg	= 0;
	
	# �ҏW���[�h
	if ($mode) {
		my $id = $Form->Get('SELECT_USER');
		# �p�X���[�h���ύX����Ă�����Đݒ肷��
		if ($pass ne $User->Get('PASS', $id)) {
			$User->Set($id, 'PASS', $pass);
			$chg = 1;
		}
		$User->Set($id, 'NAME', $name);
		$User->Set($id, 'EXPL', $expl);
		$User->Set($id, 'FULL', $full);
		$User->Set($id, 'SYSAD', $sysad);
	}
	# �o�^���[�h
	else {
		$User->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# �ݒ����ۑ�
	$User->Save($Sys);
	
	# ���O�̐ݒ�
	push @$pLog, "�� ���[�U [ $name ] " . ($mode ? '�ݒ�' : '�쐬');
	push @$pLog, '�@�@�@�@�p�X���[�h�F' . ($chg ? '********' : '�ύX�Ȃ�');
	push @$pLog, "�@�@�@�@�t���l�[���F$full";
	push @$pLog, "�@�@�@�@�����F$expl";
	push @$pLog, '�@�@�@�@�V�X�e���Ǘ��F' . ($sysad ? '�L��' : '����');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FuncUserDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���[�U���̓ǂݍ���
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# �I�����[�U��S�폜
	my @userSet = $Form->GetAtArray('USERS');
	foreach my $id (@userSet) {
		my $name = $User->Get('NAME', $id);
		next if (!defined $name);
		
		# Administrator�͍폜�s��
		if ($id eq '0000000001') {
			push @$pLog, "�� ���[�U [ $name ] �͍폜�ł��܂���ł����B";
		}
		# �������g���폜�s��
		elsif ($id eq $cuser) {
			push @$pLog, "�� ���[�U [ $name ] �͎������g�̂��ߍ폜�ł��܂���ł����B";
		}
		# ����ȊO�͍폜��
		else {
			push @$pLog, "�� ���[�U [ $name ] ���폜���܂����B";
			$User->Delete($id);
		}
	}
	
	# �ݒ����ۑ�
	$User->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

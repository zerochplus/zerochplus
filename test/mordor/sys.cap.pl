#============================================================================================================
#
#	�V�X�e���Ǘ� - �L���b�v ���W���[��
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
		$indata = PreparePageCapList($Sys, $Form);
	}
	# �L���b�v�쐬���
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageCapSetting($Sys, $Form, 0);
	}
	# �L���b�v�ҏW���
	elsif ($subMode eq 'EDIT') {
		$indata = PreparePageCapSetting($Sys, $Form, 1);
	}
	# �L���b�v�폜�m�F���
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageCapDelete($Sys, $Form);
	}
	# �L���b�v�ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('�L���b�v����', $this->{'LOG'});
	}
	# �L���b�v�ݒ莸�s���
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
	
	# �L���b�v�쐬
	if ($subMode eq 'CREATE') {
		$err = FuncCapSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# �L���b�v�ҏW
	elsif ($subMode eq 'EDIT') {
		$err = FuncCapSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# �L���b�v�폜
	elsif ($subMode eq 'DELETE') {
		$err = FuncCapDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", 'COMPLETE');
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
	$Base->SetMenu('�L���b�v�ꗗ', "'sys.cap','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('�L���b�v�o�^', "'sys.cap','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# �L���b�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my @capSet;
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	$Cap->GetKeySet('ALL', '', \@capSet);
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# �\�����̐ݒ�
	my $listnum = scalar(@capSet);
	my $dispnum = int($Form->Get('DISPNUM', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	# �L���b�v�ꗗ���o��
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $capSet[$nextnum++];
		
		push @$displist, {
			'id'	=> $id,
			'name'	=> $Cap->Get('NAME', $id),
			'full'	=> $Cap->Get('FULL', $id),
			'expl'	=> $Cap->Get('EXPL', $id),
		};
		last if (scalar(@$displist) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Caps List',
		'intmpl'	=> 'sys.cap.caplist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'caps'		=> $displist,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# �L���b�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	my $cap = {
		'name'	=> '',
		'pass'	=> '',
		'expl'	=> '',
		'full'	=> '',
		'sysad'	=> 0,
	};
	
	my $selcap = '';
	
	# �ҏW���[�h�Ȃ�L���b�v�����擾����
	if ($mode) {
		$selcap = $Form->Get('SELECT_CAP');
		$cap->{'name'} = $Cap->Get('NAME', $selcap);
		$cap->{'pass'} = $Cap->Get('PASS', $selcap);
		$cap->{'expl'} = $Cap->Get('EXPL', $selcap);
		$cap->{'full'} = $Cap->Get('FULL', $selcap);
		$cap->{'sysad'} = $Cap->Get('SYSAD', $selcap);
	}
	
	my $indata = {
		'title'		=> 'Cap ' . ($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.cap.capedit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'selcap'	=> $selcap,
		'cap'		=> $cap,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapDelete
{
	my ($Sys, $Form) = @_;
	
	# �L���b�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# �ʒm�ꗗ���o��
	my $caps = [];
	my @capSet = $Form->GetAtArray('CAPS');
	foreach my $id (@capSet) {
		next if (!defined $Cap->Get('NAME', $id));
		push @$caps, {
			'id'	=> $id,
			'name'	=> $Cap->Get('NAME', $id),
			'full'	=> $Cap->Get('FULL', $id),
			'expl'	=> $Cap->Get('EXPL', $id),
		};
	}
	
	my $indata = {
		'title'		=> 'Cap Delete Confirm',
		'intmpl'	=> 'sys.cap.capdelete',
		'caps'		=> $caps,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�쐬/�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�ҏW:1, �쐬:0
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FuncCapSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���̓`�F�b�N
	return 1001 if (!$Form->IsInput([qw(PASS)]));
	return 1002 if (!$Form->IsCapKey([qw(PASS)]));
	
	# �L���b�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# �ݒ���͏����擾
	my $name = $Form->Get('NAME');
	my $pass = $Form->Get('PASS');
	my $expl = $Form->Get('EXPL');
	my $full = $Form->Get('FULL');
	my $sysad = $Form->Equal('SYSAD', 'on') ? 1 : 0;
	my $chg	= 0;
	
	# �ҏW���[�h
	if ($mode) {
		my $id = $Form->Get('SELECT_CAP');
		# �p�X���[�h���ύX����Ă�����Đݒ肷��
		if ($pass ne $Cap->Get('PASS', $id)){
			$Cap->Set($id, 'PASS', $pass);
			$chg = 1;
		}
		$Cap->Set($id, 'NAME', $name);
		$Cap->Set($id, 'EXPL', $expl);
		$Cap->Set($id, 'FULL', $full);
		$Cap->Set($id, 'SYSAD', $sysad);
	}
	# �o�^���[�h
	else {
		$Cap->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# �ݒ����ۑ�
	$Cap->Save($Sys);
	
	# ���O�̐ݒ�
	push @$pLog, "�� �L���b�v [ $name ] " . ($mode ? '�ݒ�' : '�쐬');
	push @$pLog, '�@�@�@�@�p�X���[�h�F' . ($chg ? '********' : '�ύX�Ȃ�');
	push @$pLog, "�@�@�@�@�t���l�[���F$full";
	push @$pLog, "�@�@�@�@�����F$expl";
	push @$pLog, '�@�@�@�@�V�X�e���Ǘ��F' . ($sysad ? '�L��' : '����');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FuncCapDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# �L���b�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# �I���L���b�v��S�폜
	my @capSet = $Form->GetAtArray('CAPS');
	foreach my $id (@capSet) {
		my $name = $Cap->Get('NAME', $id);
		next if (!defined $name);
		
		my $pass = $Cap->Get('PASS', $id);
		push @$pLog, "�� �L���b�v [ $name ] ���폜���܂����B";
		$Cap->Delete($id);
	}
	
	# �ݒ����ۑ�
	$Cap->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

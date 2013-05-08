#============================================================================================================
#
#	�V�X�e���Ǘ� - �f���� ���W���[��
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
	
	# �f���ꗗ���
	if ($subMode eq 'LIST') {
		$indata = PreparePageBBSList($Sys, $Form);
	}
	# �f���쐬���
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageBBSCreate($Sys, $Form);
	}
	# �f���폜�m�F���
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageBBSDelete($Sys, $Form);
	}
	# �f���J�e�S���ύX���
	elsif ($subMode eq 'CATCHANGE') {
		$indata = PreparePageBBScategoryChange($Sys, $Form);
	}
	# �J�e�S���ꗗ���
	elsif ($subMode eq 'CATEGORY') {
		$indata = PreparePageCategoryList($Sys, $Form);
	}
	# �J�e�S���ǉ����
	elsif ($subMode eq 'CATEGORYADD') {
		$indata = PreparePageCategoryAdd($Sys, $Form);
	}
	# �J�e�S���폜���
	elsif ($subMode eq 'CATEGORYDEL') {
		$indata = PreparePageCategoryDelete($Sys, $Form);
	}
	# �����������
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('�f������', $this->{'LOG'});
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
	
	# �f���쐬
	if ($subMode eq 'CREATE') {
		$err = FunctionBBSCreate($Sys, $Form, $this->{'LOG'});
	}
	# �f���폜
	elsif ($subMode eq 'DELETE') {
		$err = FunctionBBSDelete($Sys, $Form, $this->{'LOG'});
	}
	# �J�e�S���ύX
	elsif ($subMode eq 'CATCHANGE') {
		$err = FunctionCategoryChange($Sys, $Form, $this->{'LOG'});
	}
	# �J�e�S���ǉ�
	elsif ($subMode eq 'CATADD') {
		$err = FunctionCategoryAdd($Sys, $Form, $this->{'LOG'});
	}
	# �J�e�S���폜
	elsif ($subMode eq 'CATDEL') {
		$err = FunctionCategoryDelete($Sys, $Form, $this->{'LOG'});
	}
	# �f�����X�V
	elsif ($subMode eq 'UPDATE') {
		$err = FunctionBBSInfoUpdate($Sys, $Form, $this->{'LOG'});
	}
	# �f���X�V
	elsif ($subMode eq 'UPDATEBBS') {
		$err = FunctionBBSUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('�f���ꗗ', "'sys.bbs','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('�f���쐬', "'sys.bbs','DISP','CREATE'");
		$Base->SetMenu('', '');
		$Base->SetMenu('�f���J�e�S���ꗗ', "'sys.bbs','DISP','CATEGORY'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSList
{
	my ($Sys, $Form) = @_;
	
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# �J�e�S�����X�g���o��
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	# ���[�U������BBS�ꗗ���擾
	my @belongBoard = ();
	$Sec->GetBelongBBSList($cuser, $Boards, \@belongBoard);
	
	# �f�������擾
	my @bbsSet = ();
	my $scat = $Form->Get('BBS_CATEGORY', '');
	my $subtitle = '';
	if ($scat eq '' || $scat eq 'ALL') {
		$Boards->GetKeySet('ALL', '', \@bbsSet);
	}
	else {
		$Boards->GetKeySet('CATEGORY', $scat, \@bbsSet);
		$subtitle = $Category->Get('NAME',$scat);
	}
	
	# �f�����X�g���o��
	my $boards = [];
	foreach my $id (sort @bbsSet) {
		# �����f���̂ݕ\��
		foreach (@belongBoard) {
			next if ($id ne $_);
			push @$boards, {
				'id'		=> $id,
				'name'		=> $Boards->Get('NAME', $id),
				'subject'	=> $Boards->Get('SUBJECT', $id),
				'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
			};
			last;
		}
	}
	
	my $indata = {
		'title'			=> 'BBS List' . ($subtitle ? " - $subtitle" : ''),
		'intmpl'		=> 'sys.bbs.bbslist',
		'scategory'		=> $scat,
		'categories'	=> $categories,
		'boards'		=> $boards,
		'issysad'		=> $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���쐬��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSCreate
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# �J�e�S�����X�g���o��
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	# �f�����X�g���o��
	my $boards = [];
	my @bbsSet = ();
	$Boards->GetKeySet('ALL', '', \@bbsSet);
	foreach my $id (sort @bbsSet) {
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'BBS Create',
		'intmpl'		=> 'sys.bbs.bbscreate',
		'categories'	=> $categories,
		'boards'		=> $boards,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSDelete
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# �f�����X�g���o��
	my $boards = [];
	my @bbsSet = $Form->GetAtArray('BBSS');
	foreach my $id (sort @bbsSet) {
		next if (!defined $Boards->Get('NAME', $id));
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
			'subject'	=> $Boards->Get('SUBJECT', $id),
			'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
		};
	}
	
	my $indata = {
		'title'			=> 'BBS Delete Confirm',
		'intmpl'		=> 'sys.bbs.bbsdelete',
		'boards'		=> $boards,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���J�e�S���ύX��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBScategoryChange
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# �f�����X�g���o��
	my $boards = [];
	my @bbsSet = $Form->GetAtArray('BBSS');
	foreach my $id (sort @bbsSet) {
		next if (!defined $Boards->Get('NAME', $id));
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
			'subject'	=> $Boards->Get('SUBJECT', $id),
			'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
		};
	}
	
	# �J�e�S�����X�g���o��
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'Category Change',
		'intmpl'		=> 'sys.bbs.catchange',
		'boards'		=> $boards,
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���ꗗ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryList
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# �J�e�S�����X�g���o��
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		my @bbsSet = ();
		$Boards->GetKeySet('CATEGORY', $id, \@bbsSet);
		push @$categories, {
			'id'		=> $id,
			'name'		=> $Category->Get('NAME', $id),
			'subject'	=> $Category->Get('SUBJECT', $id),
			'num'		=> scalar(@bbsSet),
		};
	}
	
	my $indata = {
		'title'			=> 'Category List',
		'intmpl'		=> 'sys.bbs.catlist',
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���ǉ���ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryAdd
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'			=> 'Category Add',
		'intmpl'		=> 'sys.bbs.catadd',
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���폜��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryDelete
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Category = ANGMAR->new;
	$Category->Load($Sys);
	
	my @catSet = $Form->GetAtArray('CATS');
	
	# �J�e�S�����X�g���o��
	my $categories = [];
	foreach my $id (sort @catSet) {
		my @bbsSet = ();
		push @$categories, {
			'id'		=> $id,
			'name'		=> $Category->Get('NAME', $id),
			'subject'	=> $Category->Get('SUBJECT', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'Category Delete Confirm',
		'intmpl'		=> 'sys.bbs.catdelete',
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���̐���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSCreate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���̓`�F�b�N
	return 1001 if (!$Form->IsInput([qw(BBS_DIR BBS_NAME BBS_CATEGORY)]));
	return 1002 if (!$Form->IsBBSDir([qw(BBS_DIR)]));
	
	require './module/earendil.pl';
	
	# POST�f�[�^�̎擾
	my $bbsCategory		= $Form->Get('BBS_CATEGORY');
	my $bbsDir			= $Form->Get('BBS_DIR');
	my $bbsName			= $Form->Get('BBS_NAME');
	my $bbsExplanation	= $Form->Get('BBS_EXPLANATION');
	my $bbsInherit		= $Form->Get('BBS_INHERIT');
	
	# �p�X�̐ݒ�
	my $createPath	= $Sys->Get('BBSPATH').'/'.$bbsDir;
	my $dataPath	= '.'.$Sys->Get('DATA');
	
	# �f���f�B���N�g���̍쐬�ɐ���������A���̉��̃f�B���N�g�����쐬����
	if (!EARENDIL::CreateDirectory($createPath, $Sys->Get('PM-BDIR'))) {
		return 2000;
	}
	
	# �T�u�f�B���N�g������
	EARENDIL::CreateDirectory("$createPath/i", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/dat", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/log", $Sys->Get('PM-LDIR'));
	EARENDIL::CreateDirectory("$createPath/kako", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/pool", $Sys->Get('PM-ADIR'));
	EARENDIL::CreateDirectory("$createPath/info", $Sys->Get('PM-ADIR'));
	
	# �f�t�H���g�f�[�^�̃R�s�[
	EARENDIL::Copy("$dataPath/default_img.gif", "$createPath/kanban.gif");
	EARENDIL::Copy("$dataPath/default_bac.gif", "$createPath/ba.gif");
	EARENDIL::Copy("$dataPath/default_hed.txt", "$createPath/head.txt");
	EARENDIL::Copy("$dataPath/default_fot.txt", "$createPath/foot.txt");
	
	push @$pLog, "���f���f�B���N�g����������...[$createPath]";
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	$Boards->Load($Sys);
	
	# �ݒ�p�����̃R�s�[
	if ($bbsInherit ne '') {
		my $inheritPath = $Sys->Get('BBSPATH').'/'.$Boards->Get('DIR', $bbsInherit);
		EARENDIL::Copy("$inheritPath/SETTING.TXT", "$createPath/SETTING.TXT");
		EARENDIL::Copy("$inheritPath/info/groups.cgi", "$createPath/info/groups.cgi");
		EARENDIL::Copy("$inheritPath/info/capgroups.cgi", "$createPath/info/capgroups.cgi");
		
		push @$pLog, "���ݒ�p������...[$inheritPath]";
	}
	
	# �f���ݒ��񐶐�
	require './module/isildur.pl';
	my $bbsSetting = ISILDUR->new;
	
	$Sys->Set('BBS', $bbsDir);
	$bbsSetting->Load($Sys);
	
	require './module/galadriel.pl';
	my $createPath2 = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $createPath);
	my $cookiePath = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH'));
	$bbsSetting->Set('BBS_TITLE', $bbsName);
	$bbsSetting->Set('BBS_SUBTITLE', $bbsExplanation);
	$bbsSetting->Set('BBS_BG_PICTURE', "$createPath2/ba.gif");
	$bbsSetting->Set('BBS_TITLE_PICTURE', "$createPath2/kanban.gif");
	$bbsSetting->Set('BBS_COOKIEPATH', "$cookiePath/");
	
	$bbsSetting->Save($Sys);
	
	push @$pLog, '���f���ݒ芮��...';
	
	# �f���\���v�f����
	my ($BBSAid);
	require './module/varda.pl';
	$BBSAid = VARDA->new;
	
	$Sys->Set('MODE', 'CREATE');
	$BBSAid->Init($Sys, $bbsSetting);
	$BBSAid->CreateIndex();
	$BBSAid->CreateIIndex();
	$BBSAid->CreateSubback();
	
	push @$pLog, '���f���\\���v�f��������...';
	
	# �ߋ����O�C���f�N�X����
	require './module/thorin.pl';
	require './module/celeborn.pl';
	my $PastLog = CELEBORN->new;
	my $Page = THORIN->new;
	$PastLog->Load($Sys);
	$PastLog->UpdateInfo($Sys);
	$PastLog->UpdateIndex($Sys, $Page);
	$PastLog->Save($Sys);
	
	push @$pLog, '���ߋ����O�C���f�N�X��������...';
	
	# �f�����ɒǉ�
	$Boards->Add($bbsName, $bbsDir, $bbsExplanation, $bbsCategory);
	$Boards->Save($Sys);
	
	push @$pLog, '���f�����ǉ�����';
	push @$pLog, "�@�@�@�@���O�F$bbsName";
	push @$pLog, "�@�@�@�@�T�u�W�F�N�g�F$bbsExplanation";
	push @$pLog, "�@�@�@�@�J�e�S���F$bbsCategory";
	push @$pLog, '<hr>�ȉ���URL�Ɍf�����쐬���܂����B';
	push @$pLog, "<a href=\"$createPath/\" target=_blank>$createPath/</a>";
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	require './module/nazguls.pl';
	require './module/varda.pl';
	my $Boards = NAZGUL->new;
	my $BBSAid = VARDA->new;
	
	$Boards->Load($Sys);
	
	my @bbsSet = $Form->GetAtArray('BBSS');
	
	foreach my $id (@bbsSet) {
		my $bbs = $Boards->Get('DIR', $id, '');
		next if ($bbs eq '');
		my $name = $Boards->Get('NAME', $id);
		$Sys->Set('BBS', $bbs);
		$Sys->Set('MODE', 'CREATE');
		$BBSAid->Init($Sys, undef);
		$BBSAid->CreateIndex();
		$BBSAid->CreateIIndex();
		$BBSAid->CreateSubback();
		
		push @$pLog, "���f���u$name�v���X�V���܂����B";
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�����̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSInfoUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	
	$Boards->Load($Sys);
	$Boards->Update($Sys, '');
	$Boards->Save($Sys);
	
	push @$pLog, '���f�����̍X�V������ɏI�����܂����B';
	push @$pLog, '���J�e�S���͑S�āu��ʁv�ɐݒ肳�ꂽ�̂ŁA�Đݒ肵�Ă��������B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���̍폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	require './module/earendil.pl';
	my $Boards = NAZGUL->new;
	$Boards->Load($Sys);
	
	my @bbsSet = $Form->GetAtArray('BBSS');
	
	foreach my $id (@bbsSet) {
		my $dir = $Boards->Get('DIR', $id, '');
		next if ($dir ne '');
		my $name = $Boards->Get('NAME', $id);
		my $path = $Sys->Get('BBSPATH') . "/$dir";
		
		# �f���f�B���N�g���ƌf�����̍폜
		EARENDIL::DeleteDirectory($path);
		$Boards->Delete($id);
		
		push @$pLog, "���f���u$name($dir)�v���폜���܂����B<br>";
	}
	
	$Boards->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���̒ǉ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryAdd
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Category = ANGMAR->new;
	$Category->Load($Sys);
	
	my $name = $Form->Get('NAME');
	my $subj = $Form->Get('SUBJ');
	
	$Category->Add($name, $subj);
	$Category->Save($Sys);
	
	# ���O�̐ݒ�
	push @$pLog, '�� �J�e�S���ǉ�';
	push @$pLog, "�J�e�S�����́F$name";
	push @$pLog, "�J�e�S�������F$subj";
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���̍폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	my @catSet = $Form->GetAtArray('CATS');
	
	foreach my $id (@catSet) {
		if ($id ne '0000000001') {
			my $name = $Category->Get('NAME', $id);
			my @bbsSet = ();
			$Boards->GetKeySet('CATEGORY', $id, \@bbsSet);
			foreach my $bbsid (@bbsSet) {
				$Boards->Set($bbsid, 'CATEGORY', '0000000001');
			}
			$Category->Delete($id);
			push @$pLog, "�J�e�S���u$name�v���폜";
		}
	}
	
	$Boards->Save($Sys);
	$Category->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���̕ύX
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryChange
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	my @bbsSet	= $Form->GetAtArray('BBSS');
	my $catid	= $Form->Get('SEL_CATEGORY');
	my $catname	= $Category->Get('NAME', $catid);
	
	foreach my $id (@bbsSet) {
		$Boards->Set($id, 'CATEGORY', $catid);
		my $bbsname = $Boards->Get('NAME', $id);
		push @$pLog, "�u$bbsname�v�̃J�e�S�����u$catname�v�ɕύX";
	}
	
	$Boards->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

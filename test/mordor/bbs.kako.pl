#============================================================================================================
#
#	�f���Ǘ� - �ߋ����O ���W���[��
#	bbs.kako.pl
#	---------------------------------------------------------------------------
#	2004.08.24 start
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
	my $this = shift;
	my ($obj, @LOG);
	
	$obj = {
		'LOG'	=> \@LOG
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $BASE, $BBS, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	$BBS = $pSys->{'AD_BBS'};
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	if (! defined $BBS){
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE);
	
	if ($subMode eq 'LIST') {													# ���O�ꗗ���
		PrintKakoLogList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �����������
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�ߋ����O����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �������s���
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# �f������ݒ�
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS')), 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $err, $BBS);
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	# �Ǘ�����o�^
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'UPDATEINFO') {												# ���X�V
		$err = FunctionUpdateInfo($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEIDX') {												# index�X�V
		$err = FunctionUpdateIndex($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'REMOVE') {													# �ߋ����O�폜
		$err = FunctionLogDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"KAKO($subMode)", 'ERROR:'.$err);
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"KAKO($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base) = @_;
	
	$Base->SetMenu('�ߋ����O�ꗗ', "'bbs.kako','DISP','LIST'");
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('�V�X�e���Ǘ��֖߂�', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintKakoLogList
{
	my ($Page, $SYS, $Form) = @_;
	my (@logSet, $ThreadNum, $key, $res, $subj, $i);
	my ($dispSt, $dispEd, $dispNum);
	my ($common, $n, $Logs, $logNum, $date);
	
	$SYS->Set('_TITLE', 'LOG List');
	
	require './module/galadriel.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	
	$Logs->Load($SYS);
	$Logs->GetKeySet('ALL', '', \@logSet);
	
	# �\�����̐ݒ�
	$logNum		= @logSet;
	$dispNum	= $Form->Get('DISPNUM_KAKO', 10) || 0;
	$dispSt		= $Form->Get('DISPST_KAKO', 0) || 0;
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $logNum ? $logNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('bbs.kako','DISP','LIST');";
	
	# �\���t�H�[���̕\��
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST_KAKO', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_KAKO', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("�\\����<input type=text name=DISPNUM_KAKO size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Date</td></td>\n");
	
	# �����擾
	my ($isUpdate, $isDelete);
	$isUpdate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 7, $SYS->Get('BBS'));
	$isDelete = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 8, $SYS->Get('BBS'));
	
	# �ߋ����O�ꗗ�̕\��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$n		= $i + 1;
		$key	= $Logs->Get('KEY', $logSet[$i]);
		$subj	= $Logs->Get('SUBJECT', $logSet[$i]);
		$date	= GALADRIEL::GetDateFromSerial(undef, $Logs->Get('DATE', $logSet[$i]), 0);
		
		$Page->Print("<tr><td><input type=checkbox name=LOGS value=$logSet[$i]></td>");
		$Page->Print("<td>$n: $subj</td><td align=center>$key</td>");
		$Page->Print("<td align=center>$date</td></tr>\n");
	}
	$Page->HTMLInput('hidden', 'DISPST_KAKO', '');
	
	$common = "onclick=\"DoSubmit('bbs.kako','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"���X�V\" $common,'UPDATEINFO')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"index�X�V\" $common,'UPDATEIDX')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'REMOVE')\"> ")		if ($isDelete);
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O���X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateInfo
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 7, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	
	$Logs->Load($Sys);
	$Logs->UpdateInfo($Sys);
	$Logs->Save($Sys);
	
	push @$pLog, '�ߋ����O���(kako.idx)���č쐬���܂����B';
	# �C���f�N�X���X�V����
	if (FunctionUpdateIndex($Sys, $Form, $pLog) != 0){
		push @$pLog, '�ߋ����Oindex(index.html)�̍č쐬�Ɏ��s���܂����B�蓮�ōX�V���Ă��������B';
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����Oindex�X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateIndex
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs, $Page);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 7, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/thorin.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	$Page = THORIN->new;
	
	$Logs->Load($Sys);
	$Logs->UpdateIndex($Sys, $Page);
#	$Logs->Save($Sys);
	
	push @$pLog, '�ߋ����Oindex(index.html)���č쐬���܂����B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Logs, @logSet, $id, $base, $removePath, @pathList, $logPath, $logPath2, $removePath2, %Dirs, @DirList);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 8, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	@logSet = $Form->GetAtArray('LOGS');
	$base = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako';
	
	require './module/earendil.pl';
	require './module/celeborn.pl';
	$Logs = CELEBORN->new;
	$Logs->Load($Sys);
	
	foreach $id (@logSet) {
		next if (! defined $Logs->Get('KEY', $id));
		push @$pLog, '�ߋ����O�u' . $Logs->Get('SUBJECT', $id) . '�v���폜���܂����B';
		
		# �ߋ����O�t�@�C���̍폜
		$logPath = $Logs->Get('PATH', $id);
		$removePath = $base . $logPath;
		unlink $removePath . '/' . $Logs->Get('KEY', $id) . '.dat';
		unlink $removePath . '/' . $Logs->Get('KEY', $id) . '.html';
		
		# �ߋ����O���̍폜
		$Logs->Delete($id);
		
		# �O���[�v���̃��O�����ׂč폜���ꂽ�ꍇ�̓f�B���N�g�����폜����
		if ($Logs->GetKeySet('PATH', $logPath, \@pathList) == 1) {
			if ($Logs->Get('PATH', $pathList[0], '') eq '') {
				EARENDIL::DeleteDirectory($removePath);
				$Logs->Delete($pathList[0]);
			}
		}
		
		$logPath2 = $logPath;
		while ($logPath2 =~ m|^(/.+)/.+?$|) {
			$logPath2 = $1;
			$removePath2 = $base . $logPath2;
			
			%Dirs = ();
			@DirList = ();
			EARENDIL::GetFolderHierarchy($removePath2, \%Dirs);
			EARENDIL::GetFolderList(\%Dirs, \@DirList, '');
			
			if ($#DirList == -1) {
				EARENDIL::DeleteDirectory($removePath2);
				$Logs->Delete((grep { $Logs->{'PATH'}->{$_} eq $logPath2 } keys %{$Logs->{'PATH'}})[0]);
			}
			else {
				last;
			}
		}
		
	}
	$Logs->Save($Sys);
	
	# �C���f�N�X���X�V����
	if (FunctionUpdateIndex($Sys, $Form, $pLog) != 0) {
		push @$pLog, '�ߋ����Oindex(index.html)�̍č쐬�Ɏ��s���܂����B�蓮�ōX�V���Ă��������B';
	}
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

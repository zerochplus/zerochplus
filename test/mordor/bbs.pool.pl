#============================================================================================================
#
#	�f���Ǘ� - POOL�X���b�h ���W���[��
#	bbs.pool.pl
#	---------------------------------------------------------------------------
#	2004.02.07 start
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
	require './module/nazguls.pl';
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
	
	if ($subMode eq 'LIST') {														# �X���b�h�ꗗ���
		PrintThreadList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'REPARE') {													# �X���b�h���A�m�F���
		PrintThreadRepare($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'DELETE') {													# �X���b�h�폜�m�F���
		PrintThreadDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �X���b�h�����������
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�ߋ����O����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �X���b�h�������s���
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
	
	if ($subMode eq 'REPARE') {														# ���A
		$err = FunctionThreadRepare($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �폜
		$err = FunctionThreadDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE') {													# ���X�V
		$err = FunctionUpdateSubject($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEALL') {												# �S�X�V
		$err = FunctionUpdateSubjectAll($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CREATE') {													# �ߋ����O����
		$err = FunctionCreateLogs($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"POOL($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"POOL($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('POOL�X���b�h�ꗗ', "'bbs.pool','DISP','LIST'");
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
sub PrintThreadList
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadSet, $ThreadNum, $key, $res, $subj, $i);
	my ($dispSt, $dispEd, $dispNum);
	my ($common, $common2, $n, $Threads, $id);
	
	$SYS->Set('_TITLE', 'Pool Thread List');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	$Threads->GetKeySet('ALL', '', \@threadSet);
	$ThreadNum = $Threads->GetNum();
	
	# �\�����̐ݒ�
	$dispNum	= ($Form->Get('DISPNUM') eq '' ? 10 : $Form->Get('DISPNUM'));
	$dispSt		= ($Form->Get('DISPST') eq '' ? 0 : $Form->Get('DISPST'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $ThreadNum ? $ThreadNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('bbs.pool','DISP','LIST');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("�\\����<input type=text name=DISPNUM size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\">�@</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	# �����擾
	my ($isRepare, $isDelete, $isUpdate, $isCreate);
	
	$isRepare = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 4, $SYS->Get('BBS'));
	$isDelete = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 5, $SYS->Get('BBS'));
	$isUpdate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 6, $SYS->Get('BBS'));
	$isCreate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 7, $SYS->Get('BBS'));
	
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$id		= $threadSet[$i];
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td><input type=checkbox name=THREADS value=$id></td>");
		$Page->Print("<td>$subj</td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
	}
	$common		= "onclick=\"DoSubmit('bbs.pool','DISP'";
	$common2	= "onclick=\"DoSubmit('bbs.pool','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"�@�X�V�@\" $common2,'UPDATE')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\" �S�X�V \" $common2,'UPDATEALL')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"�@���A�@\" $common,'REPARE')\"> ")		if ($isRepare);
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'DELETE')\"> ")		if ($isDelete);
	$Page->Print("<input type=button value=\"�ߋ����O��\" $common2,'CREATE')\"> ")	if ($isCreate);
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	
	$Page->HTMLInput('hidden', 'DISPST', '');
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�hDAT�������A�m�F�\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadRepare
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadList, $Threads, $id, $subj, $res, $common);
	
	$SYS->Set('_TITLE', 'Pool Thread Repare');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ���POOL�X���b�h�𕜋A���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.pool','FUNC','REPARE')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����FDAT���������X���b�h��[DAT�����X���b�h]��ʂŕ��A�ł��܂��B</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=right>");
	$Page->Print("<input type=button value=\"�@���A�@\" onclick=\"$common\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h�폜�m�F�\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadDelete
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadList, $Threads, $id, $subj, $res, $common);
	
	$SYS->Set('_TITLE', 'Pool Thread Delete');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃X���b�h���폜���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.pool','FUNC','DELETE')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����X���b�h�����ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=right>");
	$Page->Print("<input type=button value=\"�@�폜�@\" onclick=\"$common\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�hdat�������A
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadRepare
{
	my ($Sys, $Form, $pLog) = @_;
	my (@threadList, $Threads, $Pools, $path, $bbs, $id);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 4, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	require './module/earendil.pl';
	$Threads = BILBO->new;
	$Pools = FRODO->new;
	
	$Threads->Load($Sys);
	$Pools->Load($Sys);
	
	@threadList = $Form->GetAtArray('THREADS');
	$bbs		= $Sys->Get('BBS');
	$path		= $Sys->Get('BBSPATH') . "/$bbs";
	
	foreach $id (@threadList) {
		next if (! defined $Pools->Get('SUBJECT', $id));
		push @$pLog, '"POOL�X���b�h�u' . $Pools->Get('SUBJECT', $id) . '�v�𕜋A';
		$Threads->Add($id, $Pools->Get('SUBJECT', $id), $Pools->Get('RES', $id));
		$Pools->Delete($id);
		
		EARENDIL::Move("$path/pool/$id.cgi", "$path/dat/$id.dat");
	}
	$Threads->Save($Sys);
	$Pools->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my (@threadList, $Pools, $path, $bbs, $id);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 5, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	
	@threadList = $Form->GetAtArray('THREADS');
	$bbs		= $Sys->Get('BBS');
	$path		= $Sys->Get('BBSPATH') . "/$bbs";
	
	foreach $id (@threadList) {
		next if (! defined $Pools->Get('SUBJECT', $id));
		push @$pLog, 'POOL�X���b�h�u' . $Pools->Get('SUBJECT', $id) . '�v���폜';
		$Pools->Delete($id);
		unlink "$path/pool/$id.cgi";
		unlink "$path/log/$id.cgi";
		unlink "$path/log/del_$id.cgi";
	}
	$Pools->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h���X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateSubject
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Pools);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 6, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	$Pools->Update($Sys);
	$Pools->Save($Sys);
	
	push @$pLog, 'POOL�X���b�h���(subject.cgi)���X�V���܂����B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h���S�X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateSubjectAll
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Pools);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 6, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	$Pools->UpdateAll($Sys);
	$Pools->Save($Sys);
	
	push @$pLog, 'POOL�X���b�h���(subject.cgi)���č쐬���܂����B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O�̐���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCreateLogs
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Page, $Set, $Banner, $Dat, $Conv, $Logs);
	my (@poolSet, $key, $basePath, $bCreate);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 7, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	@poolSet = $Form->GetAtArray('THREADS');
	
	require './module/gondor.pl';
	require './module/thorin.pl';
	require './module/isildur.pl';
	require './module/galadriel.pl';
	require './module/denethor.pl';
	require './module/celeborn.pl';
	$Dat = ARAGORN->new;
	$Set = ISILDUR->new;
	$Banner = DENETHOR->new;
	$Conv = GALADRIEL->new;
	$Page = THORIN->new;
	$Logs = CELEBORN->new;
	
	$Set->Load($Sys);
	$Banner->Load($Sys);
	$Logs->Load($Sys);
	
	$basePath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/pool';
	$bCreate = 0;
	
	foreach $key (@poolSet) {
		if ($Dat->Load($Sys,"$basePath/$key.cgi", 1)) {
			if (CreateKAKOLog($Page, $Sys, $Set, $Banner, $Dat, $Conv, $key)) {
				if ($Logs->Get('KEY', $key, '') eq '') {
					$Logs->Add($key, $Dat->GetSubject(), time, '/' . substr($key, 0, 4) . '/' . substr($key, 0, 5));
				}
				else {
					$Logs->($key, 'SUBJECT', $Dat->GetSubject());
					$Logs->($key, 'DATE', time);
					$Logs->($key, 'PATH', '/' . substr($key, 0, 4) . '/' . substr($key, 0, 5));
				}
				$bCreate = 1;
				push @$pLog, "��$key�F�ߋ����O��������";
			}
		}
		if (! $bCreate){
			push @$pLog, "��$key�F�ߋ����O�������s";
		}
		$bCreate = 0;
	}
	
	$Logs->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O�̐��� - 1�t�@�C���̏o��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub CreateKAKOLog
{
	my ($Page, $Sys, $Set, $Banner, $Dat, $Conv, $key) = @_;
	my ($datPath, $logDir, $logPath, $i, @color, $title, $account, $board, $var);
	my ($Caption, $cgipath);
	
	$cgipath	= $Sys->Get('CGIPATH');
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# �ߋ����O����pooldat�p�X�̐���
	$datPath	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/pool/' . $key . '.cgi';
	$logDir		= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako/' . substr($key, 0, 4) . '/' . substr($key, 0, 5);
	$logPath	= $logDir . '/' . $key . '.html';
	
	$title 		= $Dat->GetSubject();
	$account	= $Sys->Get('COUNTER');
	$board		= $Sys->Get('CGIPATH') . '/' . $Sys->Get('BBSPATH') . '/'. $Sys->Get('BBS');
	$var		= $Sys->Get('VERSION');
	
	# �F���擾
	$color[0]	= $Set->Get('BBS_THREAD_COLOR');
	$color[1]	= $Set->Get('BBS_SUBJECT_COLOR');
	$color[2]	= $Set->Get('BBS_TEXT_COLOR');
	$color[3]	= $Set->Get('BBS_LINK_COLOR');
	$color[4]	= $Set->Get('BBS_ALINK_COLOR');
	$color[5]	= $Set->Get('BBS_VLINK_COLOR');
	
	require './module/earendil.pl';
	
	$Page->Clear();
	
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(<<HTML);
 <title>$title</title>

</head>
<!--nobanner-->
<body bgcolor="$color[0]" text="$color[2]" link="$color[3]" alink="$color[4]" vlink="$color[5]">

HTML

	# ���m���o��
	$Banner->Print($Page, 100, 2, 0) if ($Sys->Get('BANNER'));
	
	$Page->Print(<<HTML);
<div style="margin:0px;">
 <a href="http://ofuda.cc/"><img width="400" height="15" border="0" src="http://e.ofuda.cc/disp/$account/00813400.gif" alt="�����A�N�Z�X�J�E���^�[ofuda.cc�u�S���E�J�E���g�v��v"></a>
 <div style="margin-top:1em;">
  <a href="$board/">���f���ɖ߂遡</a>
  <a href="$board/kako/">���ߋ����O�q�ɂ֖߂遡</a>
 </div>
</div>

<hr style="background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;">

<h1 style="color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;">$title</h1>

HTML
	
	$Page->Print("<dl>\n");
	
	# ���X�̏o��
	for ($i = 0 ; $i < $Dat->Size() ; $i++) {
		PrintResponse($Sys, $Page, $Dat->Get($i), $i + 1, $Conv, $Set);
	}
	
	$Page->Print("</dl>\n");
	
	$Page->Print(<<HTML);

<hr>

<div style="margin-top:1em;">
 <a href="$board/">���f���ɖ߂遡</a>
 <a href="$board/kako/">���ߋ����O�q�ɂ֖߂遡</a>
</div>
<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$var
</div>


HTML
	
	$Page->Print("</body>\n</html>\n");
	$Dat->Close();
	
	# �ߋ����O�̏o��
	EARENDIL::CreateFolderHierarchy($logDir);
	EARENDIL::Copy($datPath, "$logDir/$key.dat");
	$Page->Flush(1, $Sys->Get('PM-TXT'), $logPath);
	
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O�̐��� - 1���X�̏o��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($Sys, $Page, $pDat, $n, $Conv, $Set) = @_;
	my ($oConv, @elem, $nameCol);
	
	$nameCol	= $Set->Get('BBS_NAME_COLOR');
	@elem		= split(/<>/, $$pDat);
	
	# URL�ƈ��p���̓K��
	$Conv->ConvertURL($Sys, $Set, 0, \$elem[3]);
	
	$Page->Print(" <dt><a name=\"$n\">$n</a> �F");
	$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>")	if ($elem[1] eq '');
	$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>")	if ($elem[1] ne '');
	$Page->Print("�F$elem[2]</dt>\n  <dd>$elem[3]<br><br></dd>\n");
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

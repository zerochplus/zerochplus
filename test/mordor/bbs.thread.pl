#============================================================================================================
#
#	�f���Ǘ� - �X���b�h ���W���[��
#	bbs.thread.pl
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
	if (! defined $BBS) {
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
	SetMenuList($BASE, $pSys, $Sys->Get('BBS'));
	
	if ($subMode eq 'LIST') {														# �X���b�h�ꗗ���
		PrintThreadList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'STOP') {													# �X���b�h��~�m�F���
		PrintThreadStop($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'RESTART') {													# �X���b�h��~�����m�F���
		PrintThreadStop($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'FLOAT') {													# �X���b�h����m�F���
		PrintThreadFloat($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'DEFLOAT') {													# �X���b�h��������m�F���
		PrintThreadFloat($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'POOL') {													# �X���b�hDAT�����m�F���
		PrintThreadPooling($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'DELETE') {													# �X���b�h�폜�m�F���
		PrintThreadDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'AUTOPOOL') {												# �ꊇDAT�������
		PrintThreadAutoPooling($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �����������
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�X���b�h����', $this->{'LOG'});
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
	$pSys->{'SECINFO'}->SetGroupInfo($Sys->Get('BBS'));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'STOP') {														# ��~
		$err = FunctionThreadStop($Sys, $Form, $this->{'LOG'}, 1);
	}
	elsif ($subMode eq 'RESTART') {													# �ĊJ
		$err = FunctionThreadStop($Sys, $Form, $this->{'LOG'}, 0);
	}
	elsif ($subMode eq 'FLOAT') {													# ����
		$err = FunctionThreadFloat($Sys, $Form, $this->{'LOG'}, 1);
	}
	elsif ($subMode eq 'DEFLOAT') {													# �������
		$err = FunctionThreadFloat($Sys, $Form, $this->{'LOG'}, 0);
	}
	elsif ($subMode eq 'POOL') {													# DAT����
		$err = FunctionThreadPooling($Sys, $Form, $this->{'LOG'});
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
	elsif ($subMode eq 'AUTOPOOL') {												# �ꊇdat����
		$err = FunctionThreadAutoPooling($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"THREAD($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"THREAD($subMode)", 'COMPLETE');
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
	my ($Base, $pSys, $bbs) = @_;
	
	$Base->SetMenu('�X���b�h�ꗗ', "'bbs.thread','DISP','LIST'");
	
	# �X���b�hdat���������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_THREADPOOL, $bbs)) {
		$Base->SetMenu('�ꊇDAT����', "'bbs.thread','DISP','AUTOPOOL'");
	}
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
	my ($dispSt, $dispEd, $dispNum, $bgColor, $base);
	my ($common, $common2, $n, $Threads, $id);
	
	$SYS->Set('_TITLE', 'Thread List');
	
	require './module/baggins.pl';
	require './module/gondor.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($SYS);
	$Threads->GetKeySet('ALL', '', \@threadSet);
	$ThreadNum = $Threads->GetNum();
	$base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/dat';
	
	# �\�����̐ݒ�
	$dispNum	= $Form->Get('DISPNUM', 10);
	$dispSt		= $Form->Get('DISPST', 0) || 0;
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $ThreadNum ? $ThreadNum : ($dispSt + $dispNum));
	
	# �����擾
	my ($isStop, $isPool, $isDelete, $isUpdate, $isResEdit, $isResAbone);
	$isStop		= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_THREADSTOP, $SYS->Get('BBS'));
	$isPool		= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_THREADPOOL, $SYS->Get('BBS'));
	$isDelete	= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_TREADDELETE, $SYS->Get('BBS'));
	$isUpdate	= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_THREADINFO, $SYS->Get('BBS'));
	$isResEdit	= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_RESEDIT, $SYS->Get('BBS'));
	$isResAbone	= $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_RESDELETE, $SYS->Get('BBS'));
	
	# �w�b�_�����̕\��
	$common = "DoSubmit('bbs.thread','DISP','LIST');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3><b><a href=\"javascript:SetOption('DISPST', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("�\\����<input type=text name=DISPNUM size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30px\"><a href=\"javascript:toggleAll('THREADS')\">�S</a></th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250px\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:30px\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:20px\">Res</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100px\">Attribute</td></tr>\n");
	
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$n		= $i + 1;
		$id		= $threadSet[$i];
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		my $permt = ARAGORN::GetPermission("$base/$id.dat");
		my $perms = $SYS->Get('PM-STOP');
		my $isstop = $permt == $perms;
		
		# �\���w�i�F�ݒ�
		#if ($Threads->GetAttr($id, 'stop')) { # use from 0.8.x
		if ($isstop) {								$bgColor = '#ffcfff'; }	# ��~�X���b�h
		elsif ($res > $SYS->Get('RESMAX')) {		$bgColor = '#cfffff'; }	# �ő吔�X���b�h
		elsif (ARAGORN::IsMoved("$base/$id.dat")) {	$bgColor = '#ffffcf'; }	# �ړ]�X���b�h
		else {										$bgColor = '#ffffff'; }	# �ʏ�X���b�h
		
		$common = "\"javascript:SetOption('TARGET_THREAD','$id');";
		$common .= "DoSubmit('thread.res','DISP','LIST')\"";
		
		$Page->Print("<tr bgcolor=$bgColor>");
		$Page->Print("<td><input type=checkbox name=THREADS value=$id></td>");
		if ($isResEdit || $isResAbone) {
			if (! ($subj =~ /[^\s�@]/) || $subj eq '') {
				$subj = '(�󗓂������͋󔒂̂�)';
			}
			$Page->Print("<td>$n: <a href=$common>$subj</a></td>");
		}
		else {
			$Page->Print("<td>$n: $subj</td>");
		}
		$Page->Print("<td align=center>$id</td><td align=center>$res</td>");
		my @attrstr = ();
		push @attrstr, '��~' if ($isstop);
		push @attrstr, '����' if ($Threads->GetAttr($id, 'float'));
		$Page->Print("<td>@attrstr</td></tr>\n");
	}
	$common		= "onclick=\"DoSubmit('bbs.thread','DISP'";
	$common2	= "onclick=\"DoSubmit('bbs.thread','FUNC'";
	
	$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=5 align=left>");
#	$Page->Print("<input type=button value=\" �R�s�[ \" $common2,'COPY')\"> ");
#	$Page->Print("<input type=button value=\"�@�ړ��@\" $common2,'MOVE')\"> ");
	$Page->Print("<input type=button value=\"subject�X�V\" $common2,'UPDATE')\"> ")			if ($isUpdate);
	$Page->Print("<input type=button value=\"subject�č쐬\" $common2,'UPDATEALL')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"�@��~�@\" $common,'STOP')\"> ")				if ($isStop);
	$Page->Print("<input type=button value=\"�@�ĊJ�@\" $common,'RESTART')\"> ")			if ($isStop);
	$Page->Print("<input type=button value=\"�@����@\" $common,'FLOAT')\"> ")				if ($isStop);
	$Page->Print("<input type=button value=\"�������\" $common,'DEFLOAT')\"> ")			if ($isStop);
	$Page->Print("<input type=button value=\"DAT����\" $common,'POOL')\"> ")				if ($isPool);
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'DELETE')\" class=\"delete\"> ")				if ($isDelete);
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	
	$Page->HTMLInput('hidden', 'DISPST', '');
	$Page->HTMLInput('hidden', 'TARGET_THREAD', '');
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h��~�m�F�\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadStop
{
	my ($Page, $SYS, $Form, $mode) = @_;
	my (@threadList, $Threads, $id, $subj, $res);
	my ($common, $text);
	
	$SYS->Set('_TITLE', ($mode ? 'Thread Stop' : 'Thread Restart'));
	$text = ($mode ? '��~' : '�ĊJ');
	
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃X���b�h��$text���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></td>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.thread','FUNC','" . ($mode ? 'STOP' : 'RESTART') . "')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	
	if ($mode) {
		$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
		$Page->Print("�����F��~�����X���b�h��[�ĊJ]�Œ�~��Ԃ������ł��܂��B</b><br>");
		$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	}
	$Page->Print("<tr><td colspan=3 align=left>");
	$Page->Print('<input type=button value="�@' . $text . "�@\" onclick=\"$common;\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h����m�F�\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadFloat
{
	my ($Page, $SYS, $Form, $mode) = @_;
	my (@threadList, $Threads, $id, $subj, $res);
	my ($common, $text);
	
	$SYS->Set('_TITLE', ($mode ? 'Thread Float' : 'Thread De-float'));
	$text = ($mode ? '����' : '�������');
	
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃X���b�h��$text���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></td>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.thread','FUNC','" . ($mode ? 'FLOAT' : 'DEFLOAT') . "')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	
	$Page->Print("<tr><td colspan=3 align=left>");
	$Page->Print('<input type=button value="�@' . $text . "�@\" onclick=\"$common;\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�hDAT�����m�F�\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadPooling
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadList, $Threads, $id, $subj, $res, $common);
	
	$SYS->Set('_TITLE', 'Thread Pooling');
	
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃X���b�h��DAT�������܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></td>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.thread','FUNC','POOL')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����FDAT���������X���b�h��[DAT�����X���b�h]��ʂŕ��A�ł��܂��B</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=left>");
	$Page->Print("<input type=button value=\"DAT����\" onclick=\"$common\"> ");
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
	
	$SYS->Set('_TITLE', 'Thread Remove');
	
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃X���b�h���폜���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">�X���b�h��</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">�X���b�h�L�[</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">���X��</td></td>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.thread','FUNC','DELETE')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����X���b�h�����ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=left>");
	$Page->Print("<input type=button value=\"�@�폜�@\" onclick=\"$common\" class=\"delete\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h����DAT������ʕ\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadAutoPooling
{
	my ($Page, $SYS, $Form) = @_;
	my ($common);
	
	$SYS->Set('_TITLE', 'Thread Auto Pooling');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�ȉ��̊e�����ɓ��Ă͂܂�X���b�h��dat�������܂��B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">����(OR)</td>");
	$Page->Print("<td class=\"DetailTitle\">�����ݒ�l</td></tr>\n");
	
	$Page->Print("<tr><td><input type=checkbox name=CONDITION_BYDATE value=on>");
	$Page->Print("<b>�ŏI��������</b></td><td>�ŏI�������݂�");
	$Page->Print("<input type=text size=4 name=POOLDATE value=30>���ȑO</td></tr>\n");
	$Page->Print("<tr><td><input type=checkbox name=CONDITION_BYPOS value=on>");
	$Page->Print("<b>�X���b�h�ʒu</b></td><td>�X���b�h�ʒu��");
	$Page->Print("<input type=text size=4 name=POOLPOS value=500>�ȍ~</td></tr>\n");
	$Page->Print("<tr><td><input type=checkbox name=CONDITION_BYRES value=on>");
	$Page->Print("<b>���X��</b></td><td>���X����");
	$Page->Print("<input type=text size=4 name=POOLRES value=1000>�𒴂�������</td></tr>\n");
	$Page->Print("<tr><td><input type=checkbox name=CONDITION_BYTITLE value=on>");
	$Page->Print("<b>�^�C�g��</b></td><td>�^�C�g����");
	$Page->Print("<input type=text size=15 name=POOLTITLE value=>�Ƀ}�b�`�������(���K�\\��)</td></tr>\n");
	$Page->Print("<tr><td><input type=checkbox name=CONDITION_BYSTOP value=on>");
	$Page->Print("<b>��~�X���b�h</b></td><td>�X���b�h����~�E�܂��͈ړ]����Ă������</td></tr>");
	
	$common = "DoSubmit('bbs.thread','FUNC','AUTOPOOL')";
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"�@���s�@\" onclick=\"$common\">");
	$Page->Print("</td></tr></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h��~�^����
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadStop
{
	my ($Sys, $Form, $pLog, $mode) = @_;
	my (@threadList, $Thread, $path, $base, $id, $subj);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADSTOP, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/gondor.pl';
	require './module/baggins.pl'; # use from 0.8.x
	
	$Thread		= ARAGORN->new;
	my $Threads	= BILBO->new; # use from 0.8.x
	@threadList	= $Form->GetAtArray('THREADS');
	$base		= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat';
	$Threads->LoadAttr($Sys);
	
	# �X���b�h�̒�~
	if ($mode) {
		foreach $id (@threadList) {
			$Threads->SetAttr($id, 'stop', 1); # use from 0.8.x
			$path = "$base/$id.dat";
			if ($Thread->Load($Sys, $path, 0)) {
				$subj = $Thread->GetSubject();
				if ($Thread->Stop($Sys)) {
					push @$pLog, "�X���b�h�u$subj�v���~�B";
					next;
				}
			}
			$Thread->Save($Sys);
			$Thread->Close();
			push @$pLog, "�X���b�h�u$subj/$id�v�̒�~�Ɏ��s���܂����B";
		}
	}
	# �X���b�h�̍ĊJ
	else {
		foreach $id (@threadList) {
			$Threads->SetAttr($id, 'stop', ''); # use from 0.8.x
			$path = "$base/$id.dat";
			if ($Thread->Load($Sys, $path, 0)) {
				$subj = $Thread->GetSubject();
				if ($Thread->Start($Sys)) {
					push @$pLog, "�X���b�h�u$subj�v���ĊJ�B";
					next;
				}
			}
			$Thread->Save($Sys);
			$Thread->Close();
			push @$pLog, "�X���b�h�u$subj/$id�v�̍ĊJ�Ɏ��s���܂����B";
		}
	}
	
	$Threads->SaveAttr($Sys); # use from 0.8.x
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h����^����
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadFloat
{
	my ($Sys, $Form, $pLog, $mode) = @_;
	my (@threadList, $Thread, $path, $base, $id, $subj);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADSTOP, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	
	my $Threads	= BILBO->new;
	$Threads->Load($Sys);
	@threadList	= $Form->GetAtArray('THREADS');
	
	# �X���b�h�̕���
	if ($mode) {
		foreach $id (sort { $Threads->GetPosition($b) <=> $Threads->GetPosition($a) } @threadList) {
			$Threads->SetAttr($id, 'float', 1);
			$Threads->AGE($id);
			$subj = $Threads->Get('SUBJECT', $id, '');
			push @$pLog, "�X���b�h�u$subj�v�𕂏�B";
		}
		
	}
	# �X���b�h�̕������
	else {
		foreach $id (@threadList) {
			$Threads->SetAttr($id, 'float', '');
			$subj = $Threads->Get('SUBJECT', $id, '');
			push @$pLog, "�X���b�h�u$subj�v�𕂏�����B";
		}
	}
	
	$Threads->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�hdat����
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadPooling
{
	my ($Sys, $Form, $pLog) = @_;
	my (@threadList, $Threads, $Pools, $path, $bbs, $id);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADPOOL, $Sys->Get('BBS'))) == 0) {
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
		next if (! defined $Threads->Get('RES', $id));
		push @$pLog, '�X���b�h�u' . $Threads->Get('SUBJECT', $id) . '�v��DAT����';
		$Pools->Add($id, $Threads->Get('SUBJECT', $id), $Threads->Get('RES', $id));
		$Threads->Delete($id);
		
		EARENDIL::Copy("$path/dat/$id.dat","$path/pool/$id.cgi");
		unlink "$path/dat/$id.dat";
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
	my (@threadList, $Threads, $path, $bbs, $id);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_TREADDELETE, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($Sys);
	
	@threadList = $Form->GetAtArray('THREADS');
	$bbs		= $Sys->Get('BBS');
	$path		= $Sys->Get('BBSPATH') . "/$bbs";
	
	foreach $id (@threadList) {
		next if (! defined $Threads->Get('SUBJECT', $id));
		push @$pLog, '�X���b�h�u' . $Threads->Get('SUBJECT', $id) . '�v���폜';
		$Threads->Delete($id);
		$Threads->DeleteAttr($id);
		unlink "$path/dat/$id.dat";
		unlink "$path/log/$id.cgi";
		unlink "$path/log/del_$id.cgi";
	}
	$Threads->Save($Sys);
	
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
	my ($Threads);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADINFO, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($Sys);
	$Threads->Update($Sys);
	$Threads->Save($Sys);
	
	push @$pLog, '�X���b�h���(subject.txt)���X�V���܂����B';
	
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
	my ($Threads);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADINFO, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Threads = BILBO->new;
	
	$Threads->Load($Sys);
	$Threads->UpdateAll($Sys);
	$Threads->Save($Sys);
	
	push @$pLog, '�X���b�h���(subject.txt)���č쐬���܂����B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h�ꊇdat����
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadAutoPooling
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Threads, $Pools, @threadList, $base, $id, $bPool);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_THREADPOOL, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/gondor.pl';
	require './module/baggins.pl';
	require './module/earendil.pl';
	$Threads = BILBO->new;
	$Pools = FRODO->new;
	
	$Threads->Load($Sys);
	$Pools->Load($Sys);
	
	$Threads->GetKeySet('ALL', '', \@threadList);
	$base = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	foreach $id (@threadList) {
		$bPool = 0;
		# �ŏI�������ݓ��ɂ�锻��
		if ($Form->Equal('CONDITION_BYDATE', 'on') && $bPool == 0) {
			my ($ntime, $dtime, $ltime);
			$ntime = time;
			$dtime = (stat "$base/dat/$id.dat")[9];
			$ltime = $Form->Get('POOLDATE') * 24 * 3600;
			if (($ntime - $dtime) > $ltime) {
				$bPool = 1;
			}
		}
		# �X���b�h�ʒu�ɂ�锻��
		if ($Form->Equal('CONDITION_BYPOS', 'on') && $bPool == 0) {
			my ($pos) = $Threads->GetPosition($id);
			if (($pos != -1) && ($pos + 1 >= $Form->Get('POOLPOS'))) {
				$bPool = 1;
			}
		}
		# ���X���ɂ�锻��
		if ($Form->Equal('CONDITION_BYRES', 'on') && $bPool == 0) {
			my ($res) = $Threads->Get('RES', $id);
			if ($res > $Form->Get('POOLRES')) {
				$bPool = 1;
			}
		}
		# �^�C�g���ɂ�锻��
		if ($Form->Equal('CONDITION_BYTITLE', 'on') && $bPool == 0) {
			my ($subject) = $Threads->Get('SUBJECT', $id);
			my $reg = $Form->Get('POOLTITLE');
			if ($subject =~ /$reg/) {
				$bPool = 1;
			}
		}
		# ��~�E�ړ��X���b�h
		if ($Form->Equal('CONDITION_BYSTOP', 'on') && $bPool == 0) {
			my ($permt, $perms);
			$permt = ARAGORN::GetPermission("$base/dat/$id.dat");
			$perms = $Sys->Get('PM-STOP');
			if (($permt eq $perms) || (ARAGORN::IsMoved("$base/dat/$id.dat"))) {
				$bPool = 1;
			}
		}
		
		# �t���O����̏�ԂȂ�DAT��������
		if ($bPool) {
			push @$pLog, '�X���b�h�u' . $Threads->Get('SUBJECT', $id) . '�v��DAT����';
			$Pools->Add($id, $Threads->Get('SUBJECT', $id), $Threads->Get('RES', $id));
			$Threads->Delete($id);
			
			EARENDIL::Copy("$base/dat/$id.dat", "$base/pool/$id.cgi");
			unlink "$base/dat/$id.dat";
		}
	}
	$Threads->Save($Sys);
	$Pools->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

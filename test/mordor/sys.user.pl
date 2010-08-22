#============================================================================================================
#
#	�V�X�e���Ǘ� - ���[�U ���W���[��
#	sys.user.pl
#	---------------------------------------------------------------------------
#	2004.06.26 start
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
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'LIST') {														# �X���b�h�ꗗ���
		PrintUserList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CREATE') {													# ���[�U�쐬���
		PrintUserSetting($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'EDIT') {													# ���[�U�ҏW���
		PrintUserSetting($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'DELETE') {													# ���[�U�폜�m�F���
		PrintUserDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# ���[�U�ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('���[�U����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# ���[�U�ݒ莸�s���
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'), 1);
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
	my ($subMode, $err);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'CREATE') {														# ���[�U�쐬
		$err = FuncUserSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	elsif ($subMode eq 'EDIT') {													# ���[�U�ҏW
		$err = FuncUserSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# ���[�U�폜
		$err = FuncUserDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "USER($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"USER($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$Sys	MELKOR
#	@param	$pSys	�Ǘ��V�X�e��
#	@param	$Form	SAMWISE
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('���[�U�[�ꗗ', "'sys.user','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('���[�U�[�o�^', "'sys.user','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintUserList
{
	my ($Page, $Sys, $Form) = @_;
	my ($User, @userSet, $name, $expl, $full, $id, $common);
	my ($dispNum, $i, $dispSt, $dispEd, $userNum, $isAuth);
	
	$Sys->Set('_TITLE', 'Users List');
	
	require './module/elves.pl';
	$User = GLORFINDEL->new;
	
	# ���[�U���̓ǂݍ���
	$User->Load($Sys);
	
	# ���[�U�����擾
	$User->GetKeySet('ALL', '', \@userSet);
	
	# �\�����̐ݒ�
	$userNum	= @userSet;
	$dispNum	= ($Form->Get('DISPNUM') eq '' ? 10 : $Form->Get('DISPNUM'));
	$dispSt		= ($Form->Get('DISPST') eq '' ? 0 : $Form->Get('DISPST'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $userNum ? $userNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('sys.user','DISP','LIST');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("�\\����<input type=text name=DISPNUM size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Full Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Explanation</td></td>\n");
	
	# �����擾
	$isAuth = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 0, '*');
	
	# ���[�U�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$id		= $userSet[$i];
		$name	= $User->Get('NAME', $id);
		$full	= $User->Get('FULL', $id);
		$expl	= $User->Get('EXPL', $id);
		
		$common = "\"javascript:SetOption('SELECT_USER','$id');";
		$common .= "DoSubmit('sys.user','DISP','EDIT')\"";
		
		# �V�X�e�������L���ɂ��\���}��
		if ($isAuth) {
			$Page->Print("<tr><td><input type=checkbox name=USERS value=$id></td>");
			$Page->Print("<td><a href=$common>$name</a></td>");
		}
		else{
			$Page->Print("<tr><td><input type=checkbox></td><td>$name</td>");
		}
		$Page->Print("<td>$full</td><td>$expl</td></tr>\n");
	}
	$common = "onclick=\"DoSubmit('sys.user','DISP'";
	
	$Page->HTMLInput('hidden', 'SELECT_USER', '');
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	# �V�X�e�������L���ɂ��\���}��
	if ($isAuth) {
		$Page->Print("<tr><td colspan=4 align=right>");
		$Page->Print("<input type=button value=\"�@�폜�@\" $common,'DELETE')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table>");
	
	$Page->HTMLInput('hidden', 'DISPST', '');
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintUserSetting
{
	my ($Page, $Sys, $Form, $mode) = @_;
	my ($User, $id, $common, $name, $pass, $expl, $full, $sysad);
	
	$Sys->Set('_TITLE', 'User Edit')	if ($mode == 1);
	$Sys->Set('_TITLE', 'User Create')	if ($mode == 0);
	
	require './module/elves.pl';
	$User = GLORFINDEL->new;
	
	# ���[�U���̓ǂݍ���
	$User->Load($Sys);
	
	# �ҏW���[�h�Ȃ烆�[�U�����擾����
	if ($mode) {
		$name	= $User->Get('NAME', $Form->Get('SELECT_USER'));
		$pass	= $User->Get('PASS', $Form->Get('SELECT_USER'));
		$expl	= $User->Get('EXPL', $Form->Get('SELECT_USER'));
		$full	= $User->Get('FULL', $Form->Get('SELECT_USER'));
		$sysad	= $User->Get('SYSAD', $Form->Get('SELECT_USER')) ? 'checked' : '';
	}
	else {
		$Form->Set('SELECT_USER', '');
		$name	= '';
		$pass	= '';
		$expl	= '';
		$full	= '';
		$sysad	= '';
	}
	
	$Page->Print("<center><table border=0 cellspacing=2>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">���[�U��</td><td>");
	$Page->Print("<input type=text size=30 name=NAME value=\"$name\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�p�X���[�h</td><td>");
	$Page->Print("<input type=password size=30 name=PASS value=\"$pass\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���[�U�t���l�[��</td><td>");
	$Page->Print("<input type=text size=30 name=FULL value=\"$full\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">����</td><td>");
	$Page->Print("<input type=text size=30 name=EXPL value=\"$expl\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2 valign=absmiddle>");
	$Page->Print("<input type=checkbox name=SYSAD $sysad value=on>�V�X�e���Ǘ��Ҍ���</td></tr>");
	
	$Page->HTMLInput('hidden', 'SELECT_USER', $Form->Get('SELECT_USER'));
	
	# submit�ݒ�
	$common = "'" . $Form->Get('MODE_SUB') . "'";
	$common = "onclick=\"DoSubmit('sys.user','FUNC',$common)\"";
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintUserDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($User, $Group, @userSet, $id, $name, $grop, $expl, $full);
	
	$SYS->Set('_TITLE', 'User Delete Confirm');
	
	require './module/elves.pl';
	$User = GLORFINDEL->new;
	
	
	# ���[�U�����擾
	$User->Load($SYS);
	@userSet = $Form->GetAtArray('USERS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃��[�U���폜���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	
	$Page->Print("<tr bgcolor=silver>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Full Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Explanation</td></td>\n");
	
	# ���[�U���X�g���o��
	foreach $id (@userSet) {
		$name = $User->Get('NAME', $id);
		$expl = $User->Get('EXPL', $id);
		$full = $User->Get('FULL', $id);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$full</td>");
		$Page->Print("<td>$expl</td></tr>\n");
		$Page->HTMLInput('hidden', 'USERS', $id);
	}
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�������[�U�����ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("�����FAdministrator�Ǝ������g�͍폜�ł��܂���B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=right><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.user','FUNC','DELETE')\"></td></tr>");
	$Page->Print("</table>");
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
	my ($User, $name, $pass, $expl, $grop, $chg, $full, $sysad);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('NAME', 'PASS');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		if (! $Form->IsAlphabet(\@inList)) {
			return 1002;
		}
	}
	require './module/elves.pl';
	$User = GLORFINDEL->new;
	
	$User->Load($Sys);
	
	# �ݒ���͏����擾
	$name	= $Form->Get('NAME');
	$pass	= $Form->Get('PASS');
	$expl	= $Form->Get('EXPL');
	$full	= $Form->Get('FULL');
	$sysad	= $Form->Equal('SYSAD', 'on') ? 1 : 0;
	$chg	= 0;
	
	if ($mode) {																	# �ҏW���[�h
		# �p�X���[�h���ύX����Ă�����Đݒ肷��
		if ($pass ne $User->Get('PASS', $Form->Get('SELECT_USER'))) {
			$User->Set($Form->Get('SELECT_USER'), 'PASS', $pass);
			$chg = 1;
		}
		$User->Set($Form->Get('SELECT_USER'), 'NAME', $name);
		$User->Set($Form->Get('SELECT_USER'), 'EXPL', $expl);
		$User->Set($Form->Get('SELECT_USER'), 'FULL', $full);
		$User->Set($Form->Get('SELECT_USER'), 'SYSAD', $sysad);
	}
	else {																			# �o�^���[�h
		$User->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# �ݒ����ۑ�
	$User->Save($Sys);
	
	# ���O�̐ݒ�
	{
		push @$pLog, "�� ���[�U [ $name ] " . ($mode ? '�ݒ�' : '�쐬');
		push @$pLog, '�@�@�@�@�p�X���[�h�F' . ($chg ? $pass : '�ύX�Ȃ�');
		push @$pLog, "�@�@�@�@�t���l�[���F$full";
		push @$pLog, "�@�@�@�@�����F$expl";
		push @$pLog, '�@�@�@�@�V�X�e���Ǘ��F' . ($sysad ? '�L��' : '����');
	}
	
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
	my ($User, $Sec, @userSet, $id, $name);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/elves.pl';
	$User = GLORFINDEL->new;
	$Sec = ARWEN->new;
	
	$User->Load($Sys);
	$Sec->Init($Sys);
	
	@userSet = $Form->GetAtArray('USERS');
	$id = $Sec->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
	
	# �I�����[�U��S�폜
	foreach (@userSet) {
		# Administrator�͍폜�s��
		if ($_ eq '0000000001') {
			push @$pLog, '�� ���[�U [ Administrator ] �͍폜�ł��܂���ł����B';
		}
		# �������g���폜�s��
		elsif ($_ eq $id) {
			my $name = $User->Get('NAME', $id);
			push @$pLog, "�� ���[�U [ $name ] �͎������g�̂��ߍ폜�ł��܂���ł����B";
		}
		# ����ȊO�͍폜��
		else {
			my $name = $User->Get('NAME', $_);
			push @$pLog, "�� ���[�U [ $name ] ���폜���܂����B";
			$User->Delete($_);
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

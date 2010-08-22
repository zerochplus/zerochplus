#============================================================================================================
#
#	�V�X�e���Ǘ� - �L���b�v ���W���[��
#	sys.cap.pl
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
		PrintCapList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CREATE') {													# �L���b�v�쐬���
		PrintCapSetting($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'EDIT') {													# �L���b�v�ҏW���
		PrintCapSetting($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'DELETE') {													# �L���b�v�폜�m�F���
		PrintCapDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �L���b�v�ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�L���b�v����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �L���b�v�ݒ莸�s���
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
	
	if ($subMode eq 'CREATE') {														# �L���b�v�쐬
		$err = FuncCapSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	elsif ($subMode eq 'EDIT') {													# �L���b�v�ҏW
		$err = FuncCapSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �L���b�v�폜
		$err = FuncCapDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('�L���b�v�ꗗ', "'sys.cap','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('�L���b�v�o�^', "'sys.cap','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCapList
{
	my ($Page, $Sys, $Form) = @_;
	my ($Cap, @userSet, $name, $expl, $full, $id, $common);
	my ($dispNum, $i, $dispSt, $dispEd, $userNum, $isAuth);
	
	$Sys->Set('_TITLE', 'Caps List');
	
	require './module/ungoliants.pl';
	$Cap = UNGOLIANT->new;
	
	# �L���b�v���̓ǂݍ���
	$Cap->Load($Sys);
	
	# �L���b�v�����擾
	$Cap->GetKeySet('ALL', '', \@userSet);
	
	# �\�����̐ݒ�
	$userNum	= @userSet;
	$dispNum	= ($Form->Get('DISPNUM') eq '' ? 10 : $Form->Get('DISPNUM'));
	$dispSt		= ($Form->Get('DISPST') eq '' ? 0 : $Form->Get('DISPST'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $userNum ? $userNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('sys.cap','DISP','LIST');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("�\\����<input type=text name=DISPNUM size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Cap Display Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Cap Full Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Explanation</td></td>\n");
	
	# �����擾
	$isAuth = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 0, '*');
	
	# �L���b�v�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$id		= $userSet[$i];
		$name	= $Cap->Get('NAME', $id);
		$full	= $Cap->Get('FULL', $id);
		$expl	= $Cap->Get('EXPL', $id);
		
		$common = "\"javascript:SetOption('SELECT_CAP','$id');";
		$common .= "DoSubmit('sys.cap','DISP','EDIT')\"";
		
		# �V�X�e�������L���ɂ��\���}��
		if ($isAuth) {
			$Page->Print("<tr><td><input type=checkbox name=CAPS value=$id></td>");
			$Page->Print("<td><a href=$common>$name</a></td>");
		}
		else{
			$Page->Print("<tr><td><input type=checkbox></td><td>$name</td>");
		}
		$Page->Print("<td>$full</td><td>$expl</td></tr>\n");
	}
	$common = "onclick=\"DoSubmit('sys.cap','DISP'";
	
	$Page->HTMLInput('hidden', 'SELECT_CAP', '');
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
#	�L���b�v�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCapSetting
{
	my ($Page, $Sys, $Form, $mode) = @_;
	my ($User, $id, $common, $name, $pass, $expl, $full, $sysad);
	
	$Sys->Set('_TITLE', 'Cap Edit')		if ($mode == 1);
	$Sys->Set('_TITLE', 'Cap Create')	if ($mode == 0);
	
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	
	# �L���b�v���̓ǂݍ���
	$User->Load($Sys);
	
	# �ҏW���[�h�Ȃ�L���b�v�����擾����
	if ($mode) {
		$name	= $User->Get('NAME', $Form->Get('SELECT_CAP'));
		$pass	= $User->Get('PASS', $Form->Get('SELECT_CAP'));
		$expl	= $User->Get('EXPL', $Form->Get('SELECT_CAP'));
		$full	= $User->Get('FULL', $Form->Get('SELECT_CAP'));
		$sysad	= $User->Get('SYSAD', $Form->Get('SELECT_CAP')) ? 'checked' : '';
	}
	else {
		$Form->Set('SELECT_CAP', '');
		$name	= '';
		$pass	= '';
		$expl	= '';
		$full	= '';
		$sysad	= '';
	}
	
	$Page->Print("<center><table border=0 cellspacing=2>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�L���b�v�\\����</td><td>");
	$Page->Print("<input type=text size=30 name=NAME value=\"$name\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�p�X���[�h</td><td>");
	$Page->Print("<input type=password size=30 name=PASS value=\"$pass\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�L���b�v�t���l�[��</td><td>");
	$Page->Print("<input type=text size=30 name=FULL value=\"$full\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">����</td><td>");
	$Page->Print("<input type=text size=30 name=EXPL value=\"$expl\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2 valign=absmiddle>");
	$Page->Print("<input type=checkbox name=SYSAD $sysad value=on>�V�X�e�����ʌ���</td></tr>");
	
	$Page->HTMLInput('hidden', 'SELECT_CAP', $Form->Get('SELECT_CAP'));
	
	# submit�ݒ�
	$common = "'" . $Form->Get('MODE_SUB') . "'";
	$common = "onclick=\"DoSubmit('sys.cap','FUNC',$common)\"";
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�L���b�v�폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCapDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($Cap, $Group, @userSet, $id, $name, $grop, $expl, $full);
	
	$SYS->Set('_TITLE', 'Cap Delete Confirm');
	
	require './module/ungoliants.pl';
	$Cap = UNGOLIANT->new;
	
	# �L���b�v�����擾
	$Cap->Load($SYS);
	@userSet = $Form->GetAtArray('CAPS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̃L���b�v���폜���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	
	$Page->Print("<tr bgcolor=silver>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">User Full Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Explanation</td></td>\n");
	
	# �L���b�v���X�g���o��
	foreach $id (@userSet) {
		$name = $Cap->Get('NAME', $id);
		$expl = $Cap->Get('EXPL', $id);
		$full = $Cap->Get('FULL', $id);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$full</td>");
		$Page->Print("<td>$expl</td></tr>\n");
		$Page->HTMLInput('hidden', 'CAPS', $id);
	}
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����L���b�v�����ɖ߂����Ƃ͂ł��܂���B</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=right><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.cap','FUNC','DELETE')\"></td></tr>");
	$Page->Print("</table>");
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
	my ($Cap, $name, $pass, $expl, $grop, $chg, $sysad, $full);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('PASS');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		if (! $Form->IsAlphabet(\@inList)) {
			return 1002;
		}
	}
	require './module/ungoliants.pl';
	$Cap = UNGOLIANT->new;
	
	$Cap->Load($Sys);
	
	# �ݒ���͏����擾
	$name	= $Form->Get('NAME');
	$pass	= $Form->Get('PASS');
	$expl	= $Form->Get('EXPL');
	$full	= $Form->Get('FULL');
	$sysad	= $Form->Equal('SYSAD', 'on') ? 1 : 0;
	$chg	= 0;
	
	if ($mode) {																	# �ҏW���[�h
		# �p�X���[�h���ύX����Ă�����Đݒ肷��
		if ($pass ne $Cap->Get('PASS', $Form->Get('SELECT_CAP'))){
			$Cap->Set($Form->Get('SELECT_CAP'), 'PASS', $pass);
			$chg = 1;
		}
		$Cap->Set($Form->Get('SELECT_CAP'), 'NAME', $name);
		$Cap->Set($Form->Get('SELECT_CAP'), 'EXPL', $expl);
		$Cap->Set($Form->Get('SELECT_CAP'), 'FULL', $full);
		$Cap->Set($Form->Get('SELECT_CAP'), 'SYSAD', $sysad);
	}
	else {																			# �o�^���[�h
		$Cap->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# �ݒ����ۑ�
	$Cap->Save($Sys);
	
	# ���O�̐ݒ�
	{
		push @$pLog, "�� �L���b�v [ $name ] " . ($mode ? '�ݒ�' : '�쐬');
		push @$pLog, '�@�@�@�@�p�X���[�h�F' . ($chg ? $pass : '�ύX�Ȃ�');
		push @$pLog, "�@�@�@�@�t���l�[���F$full";
		push @$pLog, "�@�@�@�@�����F$expl";
		push @$pLog, '�@�@�@�@�V�X�e���Ǘ��F' . ($sysad ? '�L��' : '����');
	}
	
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
	my ($Cap, @userSet);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/ungoliants.pl';
	$Cap = UNGOLIANT->new;
	
	$Cap->Load($Sys);
	@userSet = $Form->GetAtArray('CAPS');
	
	# �I���L���b�v��S�폜
	foreach (@userSet) {
		# Administrator�͍폜�s��
		if ($_ eq '0000000001') {
			push @$pLog, '�� �L���b�v [ Administrator ] �͍폜�ł��܂���ł����B';
		}
		# ����ȊO�͍폜��
		else {
			my $name = $Cap->Get('NAME', $_);
			my $pass = $Cap->Get('PASS', $_);
			push @$pLog, "�� �L���b�v [ $name / $pass ] ���폜���܂����B";
			$Cap->Delete($_);
		}
	}
	
	# �ݒ����ۑ�
	$Cap->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

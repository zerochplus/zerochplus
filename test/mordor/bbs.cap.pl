#============================================================================================================
#
#	�f���Ǘ� - �L���b�v�O���[�v ���W���[��
#	bbs.cap.pl
#	---------------------------------------------------------------------------
#	2004.07.17 start
#
#	���낿���˂�v���X
#	2010.08.12 �L���b�v�����ǉ�
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
		'LOG' => \@LOG
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
	SetMenuList($BASE, $pSys, $Sys->Get('BBS'));
	
	if ($subMode eq 'LIST') {													# �O���[�v�ꗗ���
		PrintGroupList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CREATE') {													# �O���[�v�쐬���
		PrintGroupSetting($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'EDIT') {													# �O���[�v�ҏW���
		PrintGroupSetting($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'DELETE') {													# �O���[�v�폜�m�F���
		PrintGroupDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'IMPORT') {													# �O���[�v�C���|�[�g���
		PrintGroupImport($Page, $Sys, $Form, $BBS);
	}
	elsif ($subMode eq 'COMPLETE') {												# �O���[�v�ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�L���b�v�O���[�v����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �O���[�v�ݒ莸�s���
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
	$pSys->{'SECINFO'}->SetGroupInfo($Sys->Get('BBS'));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if ($subMode eq 'CREATE') {													# �O���[�v�쐬
		$err = FunctionGroupSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	elsif ($subMode eq 'EDIT') {													# �O���[�v�ҏW
		$err = FunctionGroupSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �O���[�v�폜
		$err = FunctionGroupDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'IMPORT') {													# �O���[�v�C���|�[�g
		$err = FunctionGroupImport($Sys, $Form, $this->{'LOG'}, $BBS);
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "CAP_GROUP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "CAP_GROUP($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('�O���[�v�ꗗ', "'bbs.cap','DISP','LIST'");
	
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 2, $bbs)) {
		$Base->SetMenu('�O���[�v�o�^', "'bbs.cap','DISP','CREATE'");
		$Base->SetMenu('�O���[�v�C���|�[�g', "'bbs.cap','DISP','IMPORT'");
	}
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('�V�X�e���Ǘ��֖߂�', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintGroupList
{
	my ($Page, $Sys, $Form) = @_;
	my ($Group, $BBS, @groupSet, @user, $name, $expl, $id, $common, $isAuth, $n);
	
	$Sys->Set('_TITLE', 'CAP Group List');
	
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	
	# �O���[�v���̓ǂݍ���
	$Group->Load($Sys);
	$Group->GetKeySet(\@groupSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\">�@</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Group Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Subscription</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:30\">Caps</td></tr>\n");
	
	# �����擾
	$isAuth = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 2, $Sys->Get('BBS'));
	
	# �O���[�v�ꗗ���o��
	foreach $id (@groupSet) {
		$name = $Group->Get('NAME', $id);
		$expl = $Group->Get('EXPL', $id);
		@user = split(/\,/, (defined ($_ = $Group->Get('CAPS', $id)) ? $_ : ''));
		$n = @user;
		
		$common = "\"javascript:SetOption('SELECT_CAPGROUP', '$id');";
		$common .= "DoSubmit('bbs.cap', 'DISP', 'EDIT')\"";
		
		# �����ɂ���ĕ\����}��
		$Page->Print("<tr><td><input type=checkbox name=CAP_GROUPS value=$id></td>");
		if ($isAuth) {
			$Page->Print("<td><a href=$common>$name</a></td><td>$expl</td><td>$n</td></tr>\n");
		}
		else {
			$Page->Print("<td>$name</td><td>$expl</td><td>$n</td></tr>\n");
		}
	}
	$common = "onclick=\"DoSubmit('bbs.cap', 'DISP'";
	
	$Page->HTMLInput('hidden', 'SELECT_CAPGROUP', '');
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$Page->Print("<tr><td colspan=4 align=right>");
		$Page->Print("<input type=button value=\"�@�폜�@\" $common,'DELETE')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintGroupSetting
{
	my ($Page, $Sys, $Form, $mode) = @_;
	my ($Group, $User, @userSet, @authNum, $i, $num, $id);
	my ($name, $expl, @auth, @user, $common);
	
	$Sys->Set('_TITLE', 'CAP Group Edit')	if ($mode == 1);
	$Sys->Set('_TITLE', 'CAP Group Create')	if ($mode == 0);
	
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	$Group = SHELOB->new;
	
	# ���[�U���̓ǂݍ���
	$User->Load($Sys);
	$Group->Load($Sys);
	$User->GetKeySet('ALL', '', \@userSet);
	
	# �ҏW���[�h�Ȃ烆�[�U�����擾����
	if ($mode) {
		$name = $Group->Get('NAME', $Form->Get('SELECT_CAPGROUP'));
		$expl = $Group->Get('EXPL', $Form->Get('SELECT_CAPGROUP'));
		@auth = split(/\,/, (defined ($_ = $Group->Get('AUTH', $Form->Get('SELECT_CAPGROUP'))) ? $_ : ''));
		@user = split(/\,/, (defined ($_ = $Group->Get('CAPS', $Form->Get('SELECT_CAPGROUP'))) ? $_ : ''));
		
		# �����ԍ��}�b�s���O�z����쐬
		for ($i = 0 ; $i < 19 ; $i++) {
			$authNum[$i] = '';
		}
		foreach $num (@auth) {
			$authNum[$num - 1] = 'checked';
		}
	}
	else {
		$Form->Set('SELECT_CAPGROUP', '');
		$name = '';
		$expl = '';
		for ($i = 0 ; $i < 19 ; $i++) {
			$authNum[$i] = '';
		}
	}
	
	$Page->Print("<center><br><table border=0 cellspacing=2 width=90%>");
	$Page->Print("<tr><td colspan=2>�e������͂���[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>��{���</td></tr>");
	$Page->Print("<tr><td colspan=2><table cellspcing=2>");
	$Page->Print("<tr><td class=\"DetailTitle\">�O���[�v����</td><td>");
	$Page->Print("<input name=GROUPNAME_CAP type=text size=50 value=\"$name\"></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">����</td><td>");
	$Page->Print("<input name=GROUPSUBS_CAP type=text size=50 value=\"$expl\"></td></tr>");
	$Page->Print("</table><br></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\" width=40%>�������</td>");
	$Page->Print("<td class=\"DetailTitle\">�����L���b�v</td></tr><tr><td valign=top>");
	
	# �����ꗗ�\��
	$Page->Print("<input type=checkbox name=C_SUBJECT $authNum[0] value=on>�^�C�g���������K������<br>");
	$Page->Print("<input type=checkbox name=C_NAME $authNum[1] value=on>���O�������K������<br>");
	$Page->Print("<input type=checkbox name=C_MAIL $authNum[2] value=on>���[���������K������<br>");
	$Page->Print("<input type=checkbox name=C_CONTENTS $authNum[3] value=on>�{���������K������<br>");
	$Page->Print("<input type=checkbox name=C_CONTLINE $authNum[4] value=on>�{���s���K������<br>");
	$Page->Print("<input type=checkbox name=C_LINECOUNT $authNum[5] value=on>�{��1�s�������K������<br>");
	$Page->Print("<input type=checkbox name=C_NONAME $authNum[6] value=on>�������K������<br>");
	$Page->Print("<input type=checkbox name=C_THREAD $authNum[7] value=on>�X���b�h�쐬�K������<br>");
	$Page->Print("<input type=checkbox name=C_THREADCAP $authNum[8] value=on>�X���b�h�쐬�\(�L���b�v)<br>");
	$Page->Print("<input type=checkbox name=C_CONTINUAS $authNum[9] value=on>�A�����e�K������<br>");
	$Page->Print("<input type=checkbox name=C_DUPLICATE $authNum[10] value=on>��d�������݋K������<br>");
	$Page->Print("<input type=checkbox name=C_SHORTWRITE $authNum[11] value=on>�Z���ԓ��e�K������<br>");
	$Page->Print("<input type=checkbox name=C_READONLY $authNum[12] value=on>�ǎ��p�K������<br>");
	$Page->Print("<input type=checkbox name=C_IDDISP $authNum[13] value=on>ID�\\���K������<br>");
	$Page->Print("<input type=checkbox name=C_HOSTDISP $authNum[14] value=on>�����z�X�g�\\���K������<br>");
	$Page->Print("<input type=checkbox name=C_MOBILETHREAD $authNum[15] value=on>�g�т���̃X���b�h�쐬<br>");
	$Page->Print("<input type=checkbox name=C_FIXHANLDLE $authNum[16] value=on>�R�e�n�����\\��<br>");
	$Page->Print("<input type=checkbox name=C_SAMBA $authNum[17] value=on>Samba�K������<br>");
	$Page->Print("<input type=checkbox name=C_PROXY $authNum[18] value=on>�v���L�V�K������<br>");
	$Page->Print("</td>\n<td valign=top>");
	
	# �������[�U�ꗗ�\��
	foreach $id (@userSet) {
		# �V�X�e�����ʃL���b�v�A���̃O���[�v�ɏ������Ă���L���b�v�͔�\��
		if (0 == $User->Get('SYSAD', $id) &&
			($Group->GetBelong($id) eq '' || $Group->GetBelong($id) eq $Form->Get('SELECT_CAPGROUP'))) {
			my $userName = $User->Get('NAME', $id);
			my $fullName = $User->Get('FULL', $id);
			my $check = '';
			foreach (@user) {
				if ($_ eq $id) {
					$check = 'checked'
				}
			}
			$Page->Print("<input type=checkbox name=BELONGUSER_CAP value=$id $check>$userName($fullName)<br>");
		}
	}
	
	# submit�ݒ�
	$common = "'" . $Form->Get('MODE_SUB') . "'";
	$common = "onclick=\"DoSubmit('bbs.cap', 'FUNC', $common)\"";
	
	$Page->HTMLInput('hidden', 'SELECT_CAPGROUP', $Form->Get('SELECT_CAPGROUP'));
	$Page->Print("</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=submit value=\"�@�ݒ�@\" $common></td></tr>");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintGroupDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($Group, $BBS, @groupSet, $name, $expl, $rang, $id, $common);
	
	$SYS->Set('_TITLE', 'CAP Group Delete Confirm');
	
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	$Group->Load($SYS);
	
	# ���[�U�����擾
	@groupSet = $Form->GetAtArray('CAP_GROUPS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�ȉ��̃L���b�v�O���[�v���폜���܂��B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Group Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Subscription</td>");
	
	# ���[�U���X�g���o��
	foreach $id (@groupSet) {
		$name = $Group->Get('NAME', $id);
		$expl = $Group->Get('EXPL', $id);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$expl</td></tr>\n");
		$Page->HTMLInput('hidden', 'CAP_GROUPS', $id);
	}
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����O���[�v�����ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("�����F�폜����O���[�v�ɏ������Ă���L���b�v�͂��ׂĖ�������ԂɂȂ�܂��B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=right><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('bbs.cap','FUNC','DELETE')\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�C���|�[�g��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$BBS	BBS���
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintGroupImport
{
	my ($Page, $SYS, $Form, $BBS) = @_;
	my (@bbsSet, $id, $name);
	
	$SYS->Set('_TITLE', 'CAP Group Import');
	
	# ����BBS���擾
	$SYS->Get('ADMIN')->{'SECINFO'}->GetBelongBBSList($SYS->Get('ADMIN')->{'USER'}, $BBS, \@bbsSet);
#	$BBS->GetKeySet('ALL', '', \@bbsSet);
	
	$Page->Print("<br><center><table cellspcing=2>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">����BBS����C���|�[�g</td>");
	$Page->Print("<td><select name=IMPORT_BBS><option value=\"\">--�f����I��--</option>");
	
	# �f���ꗗ�̏o��
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$Page->Print("<option value=$id>$name</option>\n");
	}
	
	$Page->Print("</select></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=right><input type=button value=\"�C���|�[�g\"");
	$Page->Print("onclick=\"DoSubmit('bbs.cap','FUNC','IMPORT');\"></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�쐬/�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�ҏW:1, �쐬:0
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#	2010.08.12 windyakin ��
#	 -> �L���b�v�����̒ǉ�
#
#------------------------------------------------------------------------------------------------------------
sub FunctionGroupSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	my ($Group, $User, @userSet, @authNum, @belongUser);
	my ($name, $expl, $auth, $user, $i);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 1, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('GROUPNAME_CAP');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	$Group = SHELOB->new;
	
	# ���[�U���̓ǂݍ���
	$User->Load($Sys);
	$Group->Load($Sys);
	
	# ��{���̐ݒ�
	$name = $Form->Get('GROUPNAME_CAP');
	$expl = $Form->Get('GROUPSUBS_CAP');
	
	# �������̐���
	$auth = '';
	$authNum[0]		= $Form->Equal('C_SUBJECT', 'on') ? 1 : 0;
	$authNum[1]		= $Form->Equal('C_NAME', 'on') ? 1 : 0;
	$authNum[2]		= $Form->Equal('C_MAIL', 'on') ? 1 : 0;
	$authNum[3]		= $Form->Equal('C_CONTENTS', 'on') ? 1 : 0;
	$authNum[4]		= $Form->Equal('C_CONTLINE', 'on') ? 1 : 0;
	$authNum[5]		= $Form->Equal('C_LINECOUNT', 'on') ? 1 : 0;
	$authNum[6]		= $Form->Equal('C_NONAME', 'on') ? 1 : 0;
	$authNum[7]		= $Form->Equal('C_THREAD', 'on') ? 1 : 0;
	$authNum[8]		= $Form->Equal('C_THREADCAP', 'on') ? 1 : 0;
	$authNum[9]		= $Form->Equal('C_CONTINUAS', 'on') ? 1 : 0;
	$authNum[10]	= $Form->Equal('C_DUPLICATE', 'on') ? 1 : 0;
	$authNum[11]	= $Form->Equal('C_SHORTWRITE', 'on') ? 1 : 0;
	$authNum[12]	= $Form->Equal('C_READONLY', 'on') ? 1 : 0;
	$authNum[13]	= $Form->Equal('C_IDDISP', 'on') ? 1 : 0;
	$authNum[14]	= $Form->Equal('C_HOSTDISP', 'on') ? 1 : 0;
	$authNum[15]	= $Form->Equal('C_MOBILETHREAD', 'on') ? 1 : 0;
	$authNum[16]	= $Form->Equal('C_FIXHANLDLE', 'on') ? 1 : 0;
	$authNum[17]	= $Form->Equal('C_SAMBA', 'on') ? 1 : 0;
	$authNum[18]	= $Form->Equal('C_PROXY', 'on') ? 1 : 0;
	
	for ($i = 1 ; $i < 20 ; $i++) {
		if ($authNum[$i - 1]){
			$auth .= "$i,";
		}
	}
	$auth = substr($auth, 0, length($auth) - 1);
	
	# �������[�U���̐���
	@belongUser = $Form->GetAtArray('BELONGUSER_CAP');
	$user = join(', ', @belongUser);
	
	# �ݒ���̓o�^
	if ($mode){
		my $groupID = $Form->Get('SELECT_CAPGROUP');
		$Group->Set($groupID, 'NAME', $name);
		$Group->Set($groupID, 'EXPL', $expl);
		$Group->Set($groupID, 'AUTH', $auth);
		$Group->Set($groupID, 'CAPS', $user);
	}
	else {
		$Group->Add($name, $expl, $auth, $user);
	}
	
	# �ݒ��ۑ�
	$Group->Save($Sys);
	
	# �������O
	{
		my $id;
		push @$pLog, '���ȉ��̃L���b�v�O���[�v��o�^���܂����B';
		push @$pLog, "�O���[�v���́F$name";
		push @$pLog, "�����F$expl";
		push @$pLog, "�����F$auth";
		push @$pLog, '�����L���b�v�F';
		foreach	$id (@belongUser){
			push @$pLog, '�@�@> ' . $User->Get('NAME', $id);
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionGroupDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Group, @groupSet, $id);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 1, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	
	# ���[�U���̓ǂݍ���
	$Group->Load($Sys);
	
	push @$pLog, '���ȉ��̃O���[�v���폜���܂����B';
	@groupSet = $Form->GetAtArray('CAP_GROUPS');
	
	foreach $id (@groupSet) {
		push @$pLog, $Group->Get('NAME', $id) . '(' . $Group->Get('EXPL', $id) . ')';
		$Group->Delete($id);
	}
	
	# �ݒ�̕ۑ�
	$Group->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�C���|�[�g
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionGroupImport
{
	my ($Sys, $Form, $pLog, $BBS) = @_;
	my ($src, $dst);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 1, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/earendil.pl';
	
	$src = $Sys->Get('BBSPATH') . '/' . $BBS->Get('DIR', $Form->Get('IMPORT_BBS')) . '/info/capgroups.cgi';
	$dst = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/info/capgroups.cgi';
	
	# �O���[�v�ݒ���R�s�[
	eval {
		EARENDIL::Copy($src, $dst);
	};
	
	# ���O�̏o��
	if ($@ ne '') {
		push @$pLog, $@;
		return 9999;
	}
	else {
		my $name = $BBS->Get('NAME', $Form->Get('IMPORT_BBS'));
		push @$pLog, "�u$name�v�̃L���b�v�O���[�v�ݒ���C���|�[�g���܂����B";
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

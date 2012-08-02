#============================================================================================================
#
#	�V�X�e���Ǘ� - ���ʃL���b�v�O���[�v ���W���[��
#	sys.capg.pl
#	---------------------------------------------------------------------------
#	2011.02.12 start ���낿���˂�v���X
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
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys);
	
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
	elsif ($subMode eq 'COMPLETE') {												# �O���[�v�ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�L���b�v�O���[�v����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �O���[�v�ݒ莸�s���
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
	
	if ($subMode eq 'CREATE') {														# �O���[�v�쐬
		$err = FunctionGroupSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	elsif ($subMode eq 'EDIT') {													# �O���[�v�ҏW
		$err = FunctionGroupSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �O���[�v�폜
		$err = FunctionGroupDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
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
	my ($Base, $pSys) = @_;
	
	$Base->SetMenu('�O���[�v�ꗗ', "'sys.capg','DISP','LIST'");
	
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('�O���[�v�o�^', "'sys.capg','DISP','CREATE'");
	}
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
	my ($Group, @groupSet, @user, $name, $expl, $color, $id, $common, $isAuth, $n);
	
	$Sys->Set('_TITLE', 'Common CAP Group List');
	
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	
	# �O���[�v���̓ǂݍ���
	$Group->Load($Sys, 1);
	$Group->GetKeySet(\@groupSet, 1);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\">�@</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Group Name</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">Subscription</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:30\">Cap Color</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:30\">Caps</td></tr>\n");
	
	# �����擾
	$isAuth = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 2, $Sys->Get('BBS'));
	
	# �O���[�v�ꗗ���o��
	foreach $id (@groupSet) {
		$name = $Group->Get('NAME', $id);
		$expl = $Group->Get('EXPL', $id);
		$color = $Group->Get('COLOR', $id);
		@user = split(/\,/, (defined ($_ = $Group->Get('CAPS', $id)) ? $_ : ''));
		$n = @user;
		
		$common = "\"javascript:SetOption('SELECT_CAPGROUP', '$id');";
		$common .= "DoSubmit('sys.capg', 'DISP', 'EDIT')\"";
		
		# �����ɂ���ĕ\����}��
		$Page->Print("<tr><td><input type=checkbox name=CAP_GROUPS value=$id></td>");
		if ($isAuth) {
			$Page->Print("<td><a href=$common>$name</a></td><td>$expl</td><td>$color</td><td>$n</td></tr>\n");
		}
		else {
			$Page->Print("<td>$name</td><td>$expl</td><td>$color</td><td>$n</td></tr>\n");
		}
	}
	$common = "onclick=\"DoSubmit('sys.capg', 'DISP'";
	
	$Page->HTMLInput('hidden', 'SELECT_CAPGROUP', '');
	$Page->Print("<tr><td colspan=5><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$Page->Print("<tr><td colspan=5 align=right>");
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
	my ($name, $expl, $color, @auth, @user, $common);
	
	$Sys->Set('_TITLE', 'Common CAP Group Edit')	if ($mode == 1);
	$Sys->Set('_TITLE', 'Common CAP Group Create')	if ($mode == 0);
	
	require './module/ungoliants.pl';
	$User = UNGOLIANT->new;
	$Group = SHELOB->new;
	
	# ���[�U���̓ǂݍ���
	$User->Load($Sys);
	$Group->Load($Sys, 1);
	$User->GetKeySet('ALL', '', \@userSet);
	
	# �ҏW���[�h�Ȃ烆�[�U�����擾����
	if ($mode) {
		$name = $Group->Get('NAME', $Form->Get('SELECT_CAPGROUP'));
		$expl = $Group->Get('EXPL', $Form->Get('SELECT_CAPGROUP'));
		$color = $Group->Get('COLOR', $Form->Get('SELECT_CAPGROUP'));
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
		$color = '';
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
	$Page->Print("<tr><td class=\"DetailTitle\">�L���b�v�̐F(���L���Ńf�t�H���g)</td><td>");
	$Page->Print("<input name=GROUPCOLOR_CAP type=text size=50 value=\"$color\"></td></tr>");
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
	$Page->Print("<input type=checkbox name=C_THREADCAP $authNum[8] value=on>�X���b�h�쐬�\\(�L���b�v)<br>");
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
		my $groupid = $Group->GetBelong($id);
		# �V�X�e�����ʃL���b�v�A���̃O���[�v�ɏ������Ă���L���b�v�͔�\��
		if (0 == $User->Get('SYSAD', $id) &&
			( $groupid eq '' || $groupid eq $Form->Get('SELECT_CAPGROUP') )) {
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
	$common = "onclick=\"DoSubmit('sys.capg', 'FUNC', $common)\"";
	
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
	
	$SYS->Set('_TITLE', 'Common CAP Group Delete Confirm');
	
	require './module/ungoliants.pl';
	$Group = SHELOB->new;
	$Group->Load($SYS, 1);
	
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
		
		$Page->Print("<tr><td>$name</td><td>$expl</td></tr>\n");
		$Page->HTMLInput('hidden', 'CAP_GROUPS', $id);
	}
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����O���[�v�����ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("�����F�폜����O���[�v�ɏ������Ă���L���b�v�͂��ׂĖ�������ԂɂȂ�܂��B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=right><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.capg','FUNC','DELETE')\"></td></tr>");
	$Page->Print("</table>");
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
	my ($name, $expl, $color, $auth, $user, $i);
	
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
	$Group->Load($Sys, 1);
	
	# ��{���̐ݒ�
	$name = $Form->Get('GROUPNAME_CAP');
	$expl = $Form->Get('GROUPSUBS_CAP');
	$color = $Form->Get('GROUPCOLOR_CAP');
	$color =~ s/[^\w\d\#]//ig;
	
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
	$user = join(',', @belongUser);
	
	# �ݒ���̓o�^
	if ($mode){
		my $groupID = $Form->Get('SELECT_CAPGROUP');
		$Group->Set($groupID, 'NAME', $name);
		$Group->Set($groupID, 'EXPL', $expl);
		$Group->Set($groupID, 'COLOR', $color);
		$Group->Set($groupID, 'AUTH', $auth);
		$Group->Set($groupID, 'CAPS', $user);
		$Group->Set($groupID, 'ISCOMMON', 1);
	}
	else {
		$Group->Add($name, $expl, $color, $auth, $user, 1);
	}
	
	# �ݒ��ۑ�
	$Group->Save($Sys, 1);
	
	# �������O
	{
		my $id;
		push @$pLog, '���ȉ��̃L���b�v�O���[�v��o�^���܂����B';
		push @$pLog, "�O���[�v���́F$name";
		push @$pLog, "�����F$expl";
		push @$pLog, "�F�F$color";
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
	$Group->Load($Sys, 1);
	
	push @$pLog, '���ȉ��̃O���[�v���폜���܂����B';
	@groupSet = $Form->GetAtArray('CAP_GROUPS');
	
	foreach $id (@groupSet) {
		next if (! defined $Group->Get('NAME', $id));
		push @$pLog, $Group->Get('NAME', $id, '') . '(' . $Group->Get('EXPL', $id, '') . ')';
		$Group->Delete($id);
	}
	
	# �ݒ�̕ۑ�
	$Group->Save($Sys, 1);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

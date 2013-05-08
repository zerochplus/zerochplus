#============================================================================================================
#
#	�V�X�e���Ǘ� - ���ʃL���b�v�O���[�v ���W���[��
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
my $Page =
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# �O���[�v�ꗗ���
	if ($subMode eq 'LIST') {
		#PrintGroupList($Page, $Sys, $Form);
		$indata = PreparePageGroupList($Sys, $Form);
	}
	# �O���[�v�쐬���
	elsif ($subMode eq 'CREATE') {
		PrintGroupSetting($Page, $Sys, $Form, 0);
		#$indata = PreparePageGroupSetting($Sys, $Form, 0);
	}
	# �O���[�v�ҏW���
	elsif ($subMode eq 'EDIT') {
		PrintGroupSetting($Page, $Sys, $Form, 1);
		#$indata = PreparePageGroupSetting($Sys, $Form, 0);
	}
	# �O���[�v�폜�m�F���
	elsif ($subMode eq 'DELETE') {
		PrintGroupDelete($Page, $Sys, $Form);
		#$indata = PreparePageGroupDelete($Sys, $Form);
	}
	# �O���[�v�ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('�L���b�v�O���[�v����', $this->{'LOG'});
	}
	# �O���[�v�ݒ莸�s���
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
	
	# �O���[�v�쐬
	if ($subMode eq 'CREATE') {
		$err = FunctionGroupSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# �O���[�v�ҏW
	elsif ($subMode eq 'EDIT') {
		$err = FunctionGroupSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# �O���[�v�폜
	elsif ($subMode eq 'DELETE') {
		$err = FunctionGroupDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSCAP_GROUP($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
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
	my ($Base, $CGI) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('�O���[�v�ꗗ', "'sys.capg','DISP','LIST'");
	
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('�O���[�v�o�^', "'sys.capg','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageGroupList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# �O���[�v���̓ǂݍ���
	require './module/ungoliants.pl';
	my @groupSet;
	my $Group = SHELOB->new;
	$Group->Load($Sys, 1);
	$Group->GetKeySet(\@groupSet, 1);
	
	# �L���b�v�ꗗ���o��
	my $groups = [];
	foreach my $id (@groupSet) {
		push @$groups, {
			'id'	=> $id,
			'name'	=> $Group->Get('NAME', $id),
			'expl'	=> $Group->Get('EXPL', $id),
			'color'	=> $Group->Get('COLOR', $id),
			'num'	=> scalar(@$_ = split(/,/, $Group->Get('CAPS', $id, ''))),
		};
	}
	
	my $indata = {
		'title'		=> 'Common CAP Group List',
		'intmpl'	=> 'sys.capg.grouplist',
		'groups'	=> $groups,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�O���[�v�ݒ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�쐬�̏ꍇ:0, �ҏW�̏ꍇ:1
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
=pod
sub PreparePageGroupSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# ���[�U���̓ǂݍ���
	require './module/ungoliants.pl';
	my $Group = SHELOB->new;
	$Group->Load($Sys, 1);
	my @userSet;
	my $User = UNGOLIANT->new;
	$User->Load($Sys);
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $group = {
		'name'	=> '',
		'expl'	=> '',
		'color'	=> '',
		'auth'	=> [],
		'user'	=> [],
	};
	foreach (0 .. $CAP_MAXNUM) {
		$group->{'auth'}->[$_] = 0;
	}
	
	my $selgroup = '';
	
	# �ҏW���[�h�Ȃ烆�[�U�����擾����
	if ($mode) {
		$selgroup = $Form->Get('SELECT_CAPGROUP');
		$group->{'name'} = $Group->Get('NAME', $selgroup);
		$group->{'expl'} = $Group->Get('EXPL', $selgroup);
		$group->{'color'} = $Group->Get('COLOR', $selgroup);
		my @auth = split(/,/, $Group->Get('AUTH', $selgroup, ''));
		my @user = split(/,/, $Group->Get('CAPS', $selgroup, ''));
		foreach (@auth) {
			$group->{'auth'}->[$_-0] = 1;
		}
	}
	else {
		$group->{'name'} = '';
		$group->{'expl'} = '';
		$group->{'color'} = '';
	}
	
	# �������[�U�ꗗ�\��
	foreach my $id (@userSet) {
		my $groupid = $Group->GetBelong($id);
		# �V�X�e�����ʃL���b�v�A���̃O���[�v�ɏ������Ă���L���b�v�͔�\��
		if (!$User->Get('SYSAD', $id) &&
			($groupid eq '' || $groupid eq $selgroup)) {
			push @{$group->{'user'}}, {
				'id'		=> $id,
				'name'		=> $Group->Get('NAME', $id),
				'full'		=> $Group->Get('FULL', $id),
				'belong'	=> ($groupid ne '' && $groupid eq $selgroup ? 1 : 0),
			};
		}
	}
	
	my $indata = {
		'title'		=> 'Common CAP Group ' . ($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.capg.groupedit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'selgroup'	=> $selgroup,
		'group'		=> $group,
	};
	
	return $indata;
}
=cut

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
		for ($i = 0 ; $i < $ZP::CAP_MAXNUM ; $i++) {
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
		for ($i = 0 ; $i < $ZP::CAP_MAXNUM ; $i++) {
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
	$Page->Print("<input type=checkbox name=C_IDDISP $authNum[13] value=on>ID��\\��<br>");
	$Page->Print("<input type=checkbox name=C_NOSLIP $authNum[22] value=on>�[�����ʎq��\\��<br>");
	$Page->Print("<input type=checkbox name=C_HOSTDISP $authNum[14] value=on>�{���z�X�g��\\��<br>");
	$Page->Print("<input type=checkbox name=C_MOBILETHREAD $authNum[15] value=on>�g�т���̃X���b�h�쐬<br>");
	$Page->Print("<input type=checkbox name=C_FIXHANLDLE $authNum[16] value=on>�R�e�n�����\\��<br>");
	$Page->Print("<input type=checkbox name=C_SAMBA $authNum[17] value=on>Samba�K������<br>");
	$Page->Print("<input type=checkbox name=C_PROXY $authNum[18] value=on>�v���L�V�K������<br>");
	$Page->Print("<input type=checkbox name=C_JPHOST $authNum[19] value=on>�C�O�z�X�g�K������<br>");
	$Page->Print("<input type=checkbox name=C_NGUSER $authNum[20] value=on>���[�U�[�K������<br>");
	$Page->Print("<input type=checkbox name=C_NGWORD $authNum[21] value=on>NG���[�h�K������<br>");
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
	$Page->Print("<tr><td colspan=2 align=left>");
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
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.capg','FUNC','DELETE')\" class=\"delete\"></td></tr>");
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
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_CAPGROUP, $Sys->Get('BBS'))) == 0) {
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
	my %field2auth = (
		'C_SUBJECT'			=> $ZP::CAP_FORM_LONGSUBJECT,
		'C_NAME'			=> $ZP::CAP_FORM_LONGNAME,
		'C_MAIL'			=> $ZP::CAP_FORM_LONGMAIL,
		'C_CONTENTS'		=> $ZP::CAP_FORM_LONGTEXT,
		'C_CONTLINE'		=> $ZP::CAP_FORM_MANYLINE,
		'C_LINECOUNT'		=> $ZP::CAP_FORM_LONGLINE,
		'C_NONAME'			=> $ZP::CAP_FORM_NONAME,
		'C_THREAD'			=> $ZP::CAP_REG_MANYTHREAD,
		'C_THREADCAP'		=> $ZP::CAP_LIMIT_THREADCAPONLY,
		'C_CONTINUAS'		=> $ZP::CAP_REG_NOBREAKPOST,
		'C_DUPLICATE'		=> $ZP::CAP_REG_DOUBLEPOST,
		'C_SHORTWRITE'		=> $ZP::CAP_REG_NOTIMEPOST,
		'C_READONLY'		=> $ZP::CAP_LIMIT_READONLY,
		'C_IDDISP'			=> $ZP::CAP_DISP_NOID,
		'C_HOSTDISP'		=> $ZP::CAP_DISP_NOHOST,
		'C_MOBILETHREAD'	=> $ZP::CAP_LIMIT_MOBILETHREAD,
		'C_FIXHANLDLE'		=> $ZP::CAP_DISP_HANLDLE,
		'C_SAMBA'			=> $ZP::CAP_REG_SAMBA,
		'C_PROXY'			=> $ZP::CAP_REG_DNSBL,
		'C_JPHOST'			=> $ZP::CAP_REG_NOTJPHOST,
		'C_NGUSER'			=> $ZP::CAP_REG_NGUSER,
		'C_NGWORD'			=> $ZP::CAP_REG_NGWORD,
	);
	my @auths = ();
	foreach (keys %field2auth) {
		if ($Form->Equal($_, 'on')) {
			push @auths, $field2auth{$_};
		}
	}
	$auth = join(',', @auths);
	
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
		my $chkID = $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_CAPGROUP, $Sys->Get('BBS'))) == 0) {
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

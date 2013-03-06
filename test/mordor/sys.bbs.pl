#============================================================================================================
#
#	�V�X�e���Ǘ� - �f���� ���W���[��
#	sys.bbs.pl
#	---------------------------------------------------------------------------
#	2004.01.31 start
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
		LOG	=> \@LOG
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
	my ($BASE, $Page, $subMode);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	# �Ǘ�����o�^
	$Sys->Set('ADMIN', $pSys);
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'LIST') {														# �f���ꗗ���
		PrintBBSList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CREATE') {													# �f���쐬���
		PrintBBSCreate($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'DELETE') {													# �f���폜�m�F���
		PrintBBSDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATCHANGE') {												# �f���J�e�S���ύX���
		PrintBBScategoryChange($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORY') {												# �J�e�S���ꗗ���
		PrintCategoryList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORYADD') {												# �J�e�S���ǉ����
		PrintCategoryAdd($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'CATEGORYDEL') {												# �J�e�S���폜���
		PrintCategoryDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �����������
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�f������', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �������s���
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
	
	# �Ǘ�����o�^
	$Sys->Set('ADMIN', $pSys);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'CREATE') {														# �f���쐬
		$err = FunctionBBSCreate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �f���폜
		$err = FunctionBBSDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATCHANGE') {												# �J�e�S���ύX
		$err = FunctionCategoryChange($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATADD') {													# �J�e�S���ǉ�
		$err = FunctionCategoryAdd($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CATDEL') {													# �J�e�S���폜
		$err = FunctionCategoryDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE') {													# �f�����X�V
		$err = FunctionBBSInfoUpdate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEBBS') {												# �f���X�V
		$err = FunctionBBSUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('�f���ꗗ', "'sys.bbs','DISP','LIST'");
	
	# �V�X�e���Ǘ������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('�f���쐬', "'sys.bbs','DISP','CREATE'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('�f���J�e�S���ꗗ', "'sys.bbs','DISP','CATEGORY'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSList
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name, $category, $subject);
	my ($common1, $common2, $sCat, @belongBBS, $belongID, $isSysad);
	
	$SYS->Set('_TITLE', 'BBS List');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	$sCat = $Form->Get('BBS_CATEGORY', '');
	
	# ���[�U������BBS�ꗗ���擾
	$SYS->Get('ADMIN')->{'SECINFO'}->GetBelongBBSList($SYS->Get('ADMIN')->{'USER'}, $BBS, \@belongBBS);
	
	# �V�X�e���Ǘ��������擾
	$isSysad = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, $ZP::AUTH_SYSADMIN, '*');
	
	# �f�������擾
	if ($sCat eq '' || $sCat eq 'ALL') {
		$BBS->GetKeySet('ALL', '', \@bbsSet);
	}
	else {
		$BBS->GetKeySet('CATEGORY', $sCat, \@bbsSet);
	}
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=4 align=right>�J�e�S��");
	$Page->Print("<select name=BBS_CATEGORY>");
	$Page->Print("<option value=ALL>���ׂ�</option>\n");
	
	# �J�e�S�����X�g���o��
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		if ($id eq $sCat) {
			$Page->Print("<option value=\"$id\" selected>$name</option>\n");
		}
		else {
			$Page->Print("<option value=\"$id\">$name</option>\n");
		}
	}
	$Page->Print("</select><input type=button value=\"�@�\\���@\" onclick=");
	$Page->Print("\"DoSubmit('sys.bbs','DISP','LIST')\"></td></tr>\n");
	
	# �f�����X�g���o��
	$Page->Print("<tr><td style=\"width:20\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">SubScription</th></tr>\n");
	
	foreach $id (@bbsSet) {
		# �����f���̂ݕ\��
		foreach $belongID (@belongBBS) {
			if ($id eq $belongID) {
				$name		= $BBS->Get('NAME', $id);
				$subject	= $BBS->Get('SUBJECT', $id);
				$category	= $BBS->Get('CATEGORY', $id);
				$category	= $Category->Get('NAME', $category);
				
				$common1 = "\"javascript:SetOption('TARGET_BBS','$id');";
				$common1 .= "DoSubmit('bbs.thread','DISP','LIST');\"";
				
				$Page->Print("<tr><td><input type=checkbox name=BBSS value=$id></td>");
				$Page->Print("<td><a href=$common1>$name</a></td><td>$category</td>");
				$Page->Print("<td>$subject</td></tr>\n");
			}
		}
	}
	$common1 = "onclick=\"DoSubmit('sys.bbs','FUNC'";
	$common2 = "onclick=\"DoSubmit('sys.bbs','DISP'";
	
	$Page->HTMLInput('hidden', 'TARGET_BBS', '');
	$Page->Print("<tr><td colspan=4 align=left><hr>");
	$Page->Print("<input type=button value=\"�J�e�S���ύX\" $common2,'CATCHANGE')\"> ")	if (1);
	$Page->Print("<input type=button value=\"���X�V\" $common1,'UPDATE')\"> ")		if ($isSysad);
	$Page->Print("<input type=button value=\"index�X�V\" $common1,'UPDATEBBS')\"> ")	if (1);
	$Page->Print("<input type=button value=\"�@�폜�@\" $common2,'DELETE')\" class=\"delete\"> ")		if ($isSysad);
	$Page->Print("</td></tr></table>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���쐬��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSCreate
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name);
	
	$SYS->Set('_TITLE', 'BBS Create');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	# �f�������擾
	$BBS->GetKeySet('ALL', '', \@bbsSet);
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�쐬]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�f���J�e�S��</td>");
	$Page->Print("<td><select name=BBS_CATEGORY>");
	
	# �J�e�S�����X�g���o��
	foreach $id (@catSet) {
		$name	= $Category->Get('NAME', $id);
		$Page->Print("<option value=\"$id\">$name</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�f���f�B���N�g��</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_DIR value=\"[�f�B���N�g����]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�f������</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_NAME value=\"[�f����]��0ch�f����\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">����</td><td>");
	$Page->Print("<input type=text size=60 name=BBS_EXPLANATION value=\"[����]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�f���ݒ�p��</td>");
	$Page->Print("<td><select name=BBS_INHERIT>");
	$Page->Print("<option value=\"\">���Ȃ�</option>\n");
	
	# �f�����X�g���o��
	foreach $id (@bbsSet) {
		$name = $BBS->Get('NAME', $id);
		$Page->Print("<option value=$id>$name</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"�@�쐬�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CREATE')\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���폜�m�F��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, $id, $name, $subject, $category);
	
	$SYS->Set('_TITLE', 'BBS Delete Confirm');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̌f�����폜���܂��B<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">SubScription</th></tr>\n");
	
	# �f�����X�g���o��
	foreach $id (@bbsSet) {
		$name		= $BBS->Get('NAME', $id);
		$subject	= $BBS->Get('SUBJECT', $id);
		$category	= $BBS->Get('CATEGORY', $id);
		$category	= $Category->Get('NAME', $category);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$category</td>");
		$Page->Print("<td>$subject</td></tr>\n");
		$Page->HTMLInput('hidden', 'BBSS', $id);
	}
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("�����F�폜�����f�������ɖ߂����Ƃ͂ł��܂���B</b></td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=left><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','DELETE')\" class=\"delete\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���J�e�S���ύX��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBScategoryChange
{
	my ($Page, $SYS, $Form) = @_;
	my ($BBS, $Category, @bbsSet, @catSet, $id, $name, $subject, $category);
	
	$SYS->Set('_TITLE', 'Category Change');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	$BBS->Load($SYS);
	$Category->Load($SYS);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	$Category->GetKeySet(\@catSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>�ȉ��̌f���̃J�e�S����ύX���܂��B<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">BBS Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Category</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">SubScription</th></tr>\n");
	
	# �f�����X�g���o��
	foreach $id (@bbsSet) {
		$name		= $BBS->Get('NAME', $id);
		$subject	= $BBS->Get('SUBJECT', $id);
		$category	= $BBS->Get('CATEGORY', $id);
		$category	= $Category->Get('NAME', $category);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$category</td>");
		$Page->Print("<td>$subject</td></tr>\n");
		$Page->HTMLInput('hidden', 'BBSS', $id);
	}
	$Page->Print("<tr><td colspan=3><hr></td></tr>");
	$Page->Print("<tr><td colspan=3 align=right>�ύX��J�e�S���F<select name=SEL_CATEGORY>");
	
	# �J�e�S�����X�g���o��
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		$Page->Print("<option value=\"$id\">$name</option>\n");
	}
	$Page->Print("</select><input type=button value=\"�@�ύX�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CATCHANGE')\"></td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���ꗗ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryList
{
	my ($Page, $SYS, $Form) = @_;
	my ($Category, $BBS, $id, $name, $subj, $common);
	my (@catsSet, @bbsSet, $bbsNum);
	
	$SYS->Set('_TITLE', 'Category List');
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$Category = ANGMAR->new;
	
	$BBS->Load($SYS);
	$Category->Load($SYS);
	$Category->GetKeySet(\@catsSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td style=\"width:20\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Category Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:300\">SubScription</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Belonging</th></tr>\n");
	
	# �J�e�S���ꗗ�̏o��
	foreach $id (@catsSet) {
		$BBS->GetKeySet('CATEGORY', $id, \@bbsSet);
		
		$name	= $Category->Get('NAME', $id);
		$subj	= $Category->Get('SUBJECT', $id);
		$bbsNum	= @bbsSet;
		
		$Page->Print("<tr><td><input type=checkbox name=CATS value=$id>");
		$Page->Print("</td><td>$name</td><td>$subj</td>");
		$Page->Print("<td align=center>$bbsNum</td></tr>\n");
		undef @bbsSet;
	}
	$common = "onclick=\"DoSubmit('sys.bbs','DISP'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>");
	$Page->Print("<tr><td colspan=4 align=left>");
	$Page->Print("<input type=button value=\"�@�ǉ��@\" $common,'CATEGORYADD')\"> ");
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'CATEGORYDEL')\" class=\"delete\"> ");
	$Page->Print("</td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���ǉ���ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryAdd
{
	my ($Page, $SYS, $Form) = @_;
	my ($common);
	
	$SYS->Set('_TITLE', 'Category Add');
	$common = "onclick=\"DoSubmit('sys.bbs','FUNC','CATADD');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ǉ�]�{�^���������Ă��������B</td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�J�e�S������</td><td><input type=text name=NAME size=60></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�J�e�S������</td><td><input type=text name=SUBJ size=60></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=left>");
	$Page->Print("<input type=button value=\"�@�ǉ��@\" $common>");
	$Page->Print("</td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�J�e�S���폜��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCategoryDelete
{
	my ($Page, $SYS, $Form) = @_;
	my ($Category, $name, $subj, @catSet, $id);
	
	$SYS->Set('_TITLE', 'Category Delete Confirm');
	
	require './module/nazguls.pl';
	$Category = ANGMAR->new;
	$Category->Load($SYS);
	
	@catSet = $Form->GetAtArray('CATS');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�ȉ��̃J�e�S�����폜���܂��B<br><br></td></tr>");
	
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Category Name</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">SubScription</th></tr>\n");
	
	# ���[�U���X�g���o��
	foreach $id (@catSet) {
		$name = $Category->Get('NAME', $id);
		$subj = $Category->Get('SUBJECT', $id);
		
		$Page->Print("<tr><td>$name</a></td>");
		$Page->Print("<td>$subj</td></tr>\n");
		$Page->HTMLInput('hidden', 'CATS', $id);
	}
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td bgcolor=yellow colspan=2><b><font color=red>");
	$Page->Print("�����F�폜�����J�e�S�������ɖ߂����Ƃ͂ł��܂���B</b><br>");
	$Page->Print("�����F�������Ă���f���̃J�e�S���͋����I�Ɂu��ʁv�ɂȂ�܂��B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td colspan=2 align=left><input type=button value=\"�@�폜�@\" ");
	$Page->Print("onclick=\"DoSubmit('sys.bbs','FUNC','CATDEL')\" class=\"delete\"></td></tr>");
	$Page->Print("</table>");
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
	my ($bbsCategory, $bbsDir, $bbsName, $bbsExplanation, $bbsInherit);
	my ($createPath, $dataPath);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef) = $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('BBS_DIR', 'BBS_NAME', 'BBS_CATEGORY');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		if (! $Form->IsBBSDir(['BBS_DIR'])) {
			return 1002;
		}
	}
	require './module/earendil.pl';
	
	# POST�f�[�^�̎擾
	$bbsCategory	= $Form->Get('BBS_CATEGORY');
	$bbsDir			= $Form->Get('BBS_DIR');
	$bbsName		= $Form->Get('BBS_NAME');
	$bbsExplanation	= $Form->Get('BBS_EXPLANATION');
	$bbsInherit		= $Form->Get('BBS_INHERIT');
	
	# �p�X�̐ݒ�
	$createPath		= $Sys->Get('BBSPATH') . '/' . $bbsDir;
	$dataPath		= '.' . $Sys->Get('DATA');
	
	# �f���f�B���N�g���̍쐬�ɐ���������A���̉��̃f�B���N�g�����쐬����
	if (! (EARENDIL::CreateDirectory($createPath, $Sys->Get('PM-BDIR')))) {
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
	
	# �ݒ�p�����̃R�s�[
	if ($bbsInherit ne '') {
		my ($BBS, $inheritPath);
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		$BBS->Load($Sys);
		
		$inheritPath = $Sys->Get('BBSPATH') . '/' . $BBS->Get('DIR', $bbsInherit);
		EARENDIL::Copy("$inheritPath/SETTING.TXT", "$createPath/SETTING.TXT");
		EARENDIL::Copy("$inheritPath/info/groups.cgi", "$createPath/info/groups.cgi");
		EARENDIL::Copy("$inheritPath/info/capgroups.cgi", "$createPath/info/capgroups.cgi");
		
		push @$pLog, "���ݒ�p������...[$inheritPath]";
	}
	
	my ($bbsSetting);
	
	# �f���ݒ��񐶐�
	require './module/isildur.pl';
	$bbsSetting = ISILDUR->new;
	
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
	require './module/nazguls.pl';
	my $BBS = NAZGUL->new;
	$BBS->Load($Sys);
	$BBS->Add($bbsName, $bbsDir, $bbsExplanation, $bbsCategory);
	$BBS->Save($Sys);
	
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
	my ($BBSAid, $BBS, @bbsSet, $id, $bbs, $name);
	
	require './module/nazguls.pl';
	require './module/varda.pl';
	$BBS = NAZGUL->new;
	$BBSAid = VARDA->new;
	
	$BBS->Load($Sys);
	@bbsSet = $Form->GetAtArray('BBSS');
	
	foreach $id (@bbsSet) {
		$bbs = $BBS->Get('DIR', $id, '');
		next if ($bbs eq '');
		$name = $BBS->Get('NAME', $id);
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
	my ($BBS);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef)	= $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	$BBS->Load($Sys);
	$BBS->Update($Sys, '');
	$BBS->Save($Sys);
	
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
	my ($BBS, @bbsSet, $id, $dir, $name, $path);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef)	= $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	require './module/earendil.pl';
	$BBS = NAZGUL->new;
	$BBS->Load($Sys);
	
	@bbsSet = $Form->GetAtArray('BBSS');
	
	foreach $id (@bbsSet) {
		$dir	= $BBS->Get('DIR', $id);
		next if (! defined $dir);
		$name	= $BBS->Get('NAME', $id);
		$path	= $Sys->Get('BBSPATH') . "/$dir";
		
		# �f���f�B���N�g���ƌf�����̍폜
		EARENDIL::DeleteDirectory($path);
		$BBS->Delete($id);
		
		push @$pLog, "���f���u$name($dir)�v���폜���܂����B<br>";
	}
	$BBS->Save($Sys);
	
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
	my ($Category, $name, $subj);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef)	= $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$Category = ANGMAR->new;
	
	$Category->Load($Sys);
	
	$name = $Form->Get('NAME');
	$subj = $Form->Get('SUBJ');
	
	$Category->Add($name, $subj);
	$Category->Save($Sys);
	
	# ���O�̐ݒ�
	{
		push @$pLog, '<b>�� �J�e�S���ǉ�</b>';
		push @$pLog, "�J�e�S�����́F$name";
		push @$pLog, "�J�e�S�������F$subj";
	}
	
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
	my ($Category, $BBS, $name, $id, $bbsID);
	my (@categorySet, @bbsSet);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef) = $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS		= NAZGUL->new;
	$Category	= ANGMAR->new;
	
	$BBS->Load($Sys);
	$Category->Load($Sys);
	
	@categorySet = $Form->GetAtArray('CATS');
	
	foreach $id (@categorySet) {
		if ($id ne '0000000001') {
			$name = $Category->Get('NAME', $id);
			$BBS->GetKeySet('CATEGORY', $id, \@bbsSet);
			foreach $bbsID (@bbsSet) {
				$BBS->Set($bbsID, 'CATEGORY', '0000000001');
			}
			undef @bbsSet;
			$Category->Delete($id);
			push @$pLog, "�J�e�S���u$name�v���폜";
		}
	}
	$BBS->Save($Sys);
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
	my ($BBS, $Category, @bbsSet, $idCat, $nmCat, $nmBBS, $id);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my ($chkID, undef) = $SEC->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
		
		if (($SEC->IsAuthority($chkID, $ZP::AUTH_SYSADMIN, '*')) == 0) {
			return 1000;
		}
	}
	require './module/nazguls.pl';
	$BBS		= NAZGUL->new;
	$Category	= ANGMAR->new;
	
	$BBS->Load($Sys);
	$Category->Load($Sys);
	
	@bbsSet	= $Form->GetAtArray('BBSS');
	$idCat	= $Form->Get('SEL_CATEGORY');
	$nmCat	= $Category->Get('NAME', $idCat);
	
	foreach $id (@bbsSet) {
		$BBS->Set($id, 'CATEGORY', $idCat);
		$nmBBS = $BBS->Get('NAME', $id);
		push @$pLog, "�u$nmBBS�v�̃J�e�S�����u$nmCat�v�ɕύX";
	}
	
	$BBS->Save($Sys);
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

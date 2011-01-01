#============================================================================================================
#
#	�V�X�e���Ǘ� - ���[�U ���W���[��
#	sys.top.pl
#	---------------------------------------------------------------------------
#	2004.09.11 start
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;
no warnings 'redefine';

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
	
	if ($subMode eq 'NOTICE') {														# �ʒm�ꗗ���
		PrintNoticeList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'NOTICE_CREATE') {											# �ʒm�ꗗ���
		PrintNoticeCreate($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'ADMINLOG') {												# ���O�{�����
		PrintAdminLog($Page, $Sys, $Form, $pSys->{'LOGGER'});
	}
	elsif ($subMode eq 'COMPLETE') {												# �ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('���[�U�ʒm����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �ݒ莸�s���
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
	
	if ($subMode eq 'CREATE') {														# �ʒm�쐬
		$err = FunctionNoticeCreate($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# �ʒm�폜
		$err = FunctionNoticeDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'LOG_REMOVE') {												# ���샍�O�폜
		$err = FunctionLogRemove($Sys, $Form, $pSys->{'LOGGER'}, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", 'COMPLETE');
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
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('���[�U�ʒm�ꗗ', "'sys.top','DISP','NOTICE'");
	$Base->SetMenu('���[�U�ʒm�쐬', "'sys.top','DISP','NOTICE_CREATE'");
	
	# �V�X�e���Ǘ������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('���샍�O�{��', "'sys.top','DISP','ADMINLOG'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoticeList
{
	my ($Page, $Sys, $Form) = @_;
	my ($Notices, @noticeSet, $from, $subj, $text, $date, $id, $common);
	my ($dispNum, $i, $dispSt, $dispEd, $listNum, $isAuth, $curUser);
	my ($orz, $or2);
	
	$Sys->Set('_TITLE', 'User Notice List');
	
	require './module/gandalf.pl';
	require './module/galadriel.pl';
	$Notices = GANDALF->new;
	
	# �ʒm���̓ǂݍ���
	$Notices->Load($Sys);
	
	# �ʒm�����擾
	$Notices->GetKeySet('ALL', '', \@noticeSet);
	@noticeSet = sort @noticeSet;
	@noticeSet = reverse @noticeSet;
	
	# �\�����̐ݒ�
	$listNum	= @noticeSet;
	$dispNum	= $Form->Get('DISPNUM_NOTICE', 5) || 5;
	$dispSt		= $Form->Get('DISPST_NOTICE', 0) || 0;
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	
	$orz = $dispSt - $dispNum;
	$or2 = $dispSt + $dispNum;
	
	$common		= "DoSubmit('sys.top','DISP','NOTICE');";
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="2" width="100%">
   <tr>
    <td>
    </td>
    <td>
    <a href="javascript:SetOption('DISPST_NOTICE', $orz);$common">&lt;&lt; PREV</a> |
    <a href="javascript:SetOption('DISPST_NOTICE', $or2);$common">NEXT &gt;&gt;</a>
    </td>
    <td align=right colspan="2">
    �\\���� <input type=text name="DISPNUM_NOTICE" size="4" value="$dispNum">
    <input type=button value="�@�\\���@" onclick="$common">
    </td>
   </tr>
   <tr>
    <td style="width:30px;"><br></td>
    <td colspan="3" class="DetailTitle">Notification</td>
   </tr>
HTML
	
	# �J�����g���[�U
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	# �ʒm�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$id = $noticeSet[$i];
		if ($Notices->IsInclude($id, $curUser) && ! $Notices->IsLimitOut($id)) {
			if ($Notices->Get('FROM', $id) eq '0000000000') {
				$from = '0ch�Ǘ��V�X�e��';
			}
			else {
				$from = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'}->Get('NAME', $Notices->Get('FROM', $id));
			}
			$subj = $Notices->Get('SUBJECT', $id);
			$text = $Notices->Get('TEXT', $id);
			$date = GALADRIEL::GetDateFromSerial(undef, $Notices->Get('DATE', $id), 0);
			
$Page->Print(<<HTML);
   <tr>
    <td><input type=checkbox name="NOTICES" value="$id"></td>
    <td class="Response" colspan="3">
    <dl style="margin:0px;">
     <dt><b>$subj</b> <font color="blue">From�F$from</font> $date</dt>
      <dd>
      $text<br>
      <br></dd>
    </dl>
    </td>
   </tr>
HTML

		}
		else {
			$dispEd++ if ($dispEd + 1 < $listNum);
		}
	}
	
$Page->Print(<<HTML);
   <tr>
    <td colspan="4" align="right">
    <input type="button" value="�@�폜�@" onclick="DoSubmit('sys.top','FUNC','DELETE')">
    </td>
   </tr>
  </table>
  <input type="hidden" name="DISPST_NOTICE" value="">
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�쐬��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoticeCreate
{
	my ($Page, $Sys, $Form) = @_;
	my ($isSysad, $User, @userSet, $id, $name, $full, $common);
	
	$Sys->Set('_TITLE', 'User Notice Create');
	
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 0, '*');
	$User = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'};
	$User->GetKeySet('ALL', '', \@userSet);
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="2" width="100%">
    <tr>
    <td class="DetailTitle">�^�C�g��</td>
    <td><input type="text" size="60" name="NOTICE_TITLE"></td>
   </tr>
   <tr>
    <td class="DetailTitle">�{��</td>
    <td>
    <textarea rows="10" cols="70" name="NOTICE_CONTENT"></textarea>
    </td>
   </tr>
   <tr>
    <td class="DetailTitle">�ʒm�惆�[�U</td>
    <td>
    <table width="100%" cellspacing="2">
HTML
	
	if ($isSysad) {
		
$Page->Print(<<HTML);
     <tr>
      <td class="DetailTitle">
      <input type="radio" name="NOTICE_KIND" value="ALL">�S�̒ʒm
      </td>
      <td>
      �L�������F<input type="text" name="NOTICE_LIMIT" size="10" value="30">��
      </td>
     </tr>
     <tr>
      <td class="DetailTitle">
      <input type="radio" name="NOTICE_KIND" value="ONE" checked>�ʒʒm
      </td>
      <td>
HTML
	}
	else {
$Page->Print(<<HTML);
     <tr>
      <td class="DetailTitle">
      <input type="radio" name="NOTICE_KIND" value="ONE" checked>�ʒʒm
      </td>
      <td>
HTML
	}
	
	# ���[�U�ꗗ��\��
	foreach $id (@userSet) {
		$name = $User->Get('NAME', $id);
		$full = $User->Get('FULL', $id);
		$Page->Print("      <input type=\"checkbox\" name=\"NOTICE_USERS\" value=\"$id\"> $name($full)<br>\n");
	}
	
$Page->Print(<<HTML);
      </td>
     </tr>
    </table>
    </td>
   </tr>
   <tr>
    <td colspan="2" align="right">
    <input type="button" value="�@���M�@" onclick="DoSubmit('sys.top','FUNC','CREATE')">
    </td>
   </tr>
  </table>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	�Ǘ����샍�O�{����ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintAdminLog
{
	my ($Page, $Sys, $Form, $Logger) = @_;
	my ($common);
	my ($dispNum, $i, $dispSt, $dispEd, $listNum, $isSysad, $data, @elem);
	my ($orz, $or2);
	
	$Sys->Set('_TITLE', 'Operation Log');
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 0, '*');
	
	# �\�����̐ݒ�
	$listNum	= $Logger->Size();
	$dispNum	= ($Form->Get('DISPNUM_LOG') eq '' ? 10 : $Form->Get('DISPNUM_LOG'));
	$dispSt		= ($Form->Get('DISPST_LOG') eq '' ? 0 : $Form->Get('DISPST_LOG'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	$common		= "DoSubmit('sys.top','DISP','ADMINLOG');";
	
	$orz		= $dispSt - $dispNum;
	$or2		= $dispSt + $dispNum;
	
$Page->Print(<<HTML);
  <table border="0" cellspacing="2" width="100%">
   <tr>
    <td colspan="2">
    <a href="javascript:SetOption('DISPST_LOG', $orz);$common">&lt;&lt; PREV</a> |
    <a href="javascript:SetOption('DISPST_LOG', $or2);$common">NEXT &gt;&gt;</a>
    </td>
    <td align="right" colspan="2">
    �\\���� <input type="text" name="DISPNUM_LOG" size="4" value="$dispNum">
    <input type="button" value="�@�\\���@" onclick="$common">
    </td>
   </tr>
   <tr>
    <td class="DetailTitle">Date</td>
    <td class="DetailTitle">User</td>
    <td class="DetailTitle">Operation</td>
    <td class="DetailTitle">Result</td>
   </tr>
HTML
	
	require './module/galadriel.pl';
	
	# ���O�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$data = $Logger->Get($listNum - $i - 1);
		@elem = split(/<>/, $data);
		if (1) {
			$elem[0] = GALADRIEL::GetDateFromSerial(undef, $elem[0], 0);
			$Page->Print("   <tr><td>$elem[0]</td><td>$elem[1]</td><td>$elem[2]</td><td>$elem[3]</td></tr>\n");
		}
		else {
			$dispEd++ if ($dispEd + 1 < $listNum);
		}
	}
	
$Page->Print(<<HTML);
   <tr>
    <td colspan="4"><hr></td>
   </tr>
   <tr>
    <td colspan="4" align="right">
    <input type="button" value="���O�̍폜" onclick="DoSubmit('sys.top','FUNC','LOG_REMOVE')">
    </td>
   </tr>
  </table>
  
  <input type="hidden" name="DISPST_LOG" value="">
  
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�쐬
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeCreate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Notice, $subject, $content, $date, $limit, $users);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if ($chkID eq '') {
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my @inList = ('NOTICE_TITLE', 'NOTICE_CONTENT');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
		@inList = ('NOTICE_LIMIT');
		if ($Form->Equal('NOTICE_KIND', 'ALL') && ! $Form->IsInput(\@inList)) {
			return 1001;
		}
		@inList = ('NOTICE_USERS');
		if ($Form->Equal('NOTICE_KIND', 'ONE') && ! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/gandalf.pl';
	$Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	$date = time;
	$subject = $Form->Get('NOTICE_TITLE');
	$content = $Form->Get('NOTICE_CONTENT');
	
	require './module/galadriel.pl';
	GALADRIEL::ConvertCharacter1(undef, \$subject, 0);
	GALADRIEL::ConvertCharacter1(undef, \$content, 2);
	
	if ($Form->Equal('NOTICE_KIND', 'ALL')) {
		$users = '*';
		$limit = $Form->Get('NOTICE_LIMIT');
		$limit = $date + ($limit * 24 * 60 * 60);
	}
	else {
		my @toSet = $Form->GetAtArray('NOTICE_USERS');
		$users = join(', ', @toSet);
		$limit = 0;
	}
	# �ʒm����ǉ�
	$Notice->Add($users, $Sys->Get('ADMIN')->{'USER'}, $subject, $content, $limit);
	$Notice->Save($Sys);
	
	push @$pLog, '���[�U�ւ̒ʒm�I��';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ʒm�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Notice, @noticeSet, $curUser, $id);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if ($chkID eq '') {
			return 1000;
		}
	}
	require './module/gandalf.pl';
	$Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	@noticeSet = $Form->GetAtArray('NOTICES');
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	foreach $id	(@noticeSet) {
		if ($Notice->Get('TO', $id) eq '*') {
			my $subj = $Notice->Get('SUBJECT', $id);
			push @$pLog, "�ʒm�u$subj�v�͑S�̒ʒm�Ȃ̂ō폜�ł��܂���ł����B";
		}
		else {
			my $subj = $Notice->Get('SUBJECT', $id);
			$Notice->RemoveToUser($id, $curUser);
			push @$pLog, "�ʒm�u$subj�v���폜���܂����B";
		}
	}
	$Notice->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���샍�O�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogRemove
{
	my ($Sys, $Form, $Logger, $pLog) = @_;
	my ($Notice, @noticeSet, $curUser, $id);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	$Logger->Clear();
	push @$pLog, '���샍�O���폜���܂����B';
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

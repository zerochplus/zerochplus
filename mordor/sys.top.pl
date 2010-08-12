#============================================================================================================
#
#	�V�X�e���Ǘ� - ���[�U ���W���[��
#	sys.top.pl
#	---------------------------------------------------------------------------
#	2004.09.11 start
#
#============================================================================================================
package	MODULE;

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
	my		$this = shift;
	my		($obj,@LOG);
	
	$obj = {
		'LOG'	=> \@LOG
	};
	bless($obj,$this);
	
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
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($subMode,$BASE,$BBS);
	
	require('./mordor/sauron.pl');
	$BASE = new SAURON;
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys,$Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE,$pSys);
	
	if		($subMode eq 'NOTICE'){													# �ʒm�ꗗ���
		PrintNoticeList($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'NOTICE_CREATE'){											# �ʒm�ꗗ���
		PrintNoticeCreate($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'ADMINLOG'){												# ���O�{�����
		PrintAdminLog($Page,$Sys,$Form,$pSys->{'LOGGER'});
	}
	elsif	($subMode eq 'COMPLETE'){												# �ݒ芮�����
		$Sys->Set('_TITLE','Process Complete');
		$BASE->PrintComplete('���[�U�ʒm����',$this->{'LOG'});
	}
	elsif	($subMode eq 'FALSE'){													# �ݒ莸�s���
		$Sys->Set('_TITLE','Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'),1);
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
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($subMode,$err);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if		($subMode eq 'CREATE'){													# �ʒm�쐬
		$err = FunctionNoticeCreate($Sys,$Form,$this->{'LOG'});
	}
	elsif	($subMode eq 'DELETE'){													# �ʒm�폜
		$err = FunctionNoticeDelete($Sys,$Form,$this->{'LOG'});
	}
	elsif	($subMode eq 'LOG_REMOVE'){												# ���샍�O�폜
		$err = FunctionLogRemove($Sys,$Form,$pSys->{'LOGGER'},$this->{'LOG'});
	}
	
	# �������ʕ\��
	if	($err){
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_TOP($subMode)",'ERROR:'.$err);
		push(@{$this->{'LOG'}},$err);
		$Form->Set('MODE_SUB','FALSE');
	}
	else{
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_TOP($subMode)",'COMPLETE');
		$Form->Set('MODE_SUB','COMPLETE');
	}
	$this->DoPrint($Sys,$Form,$pSys);
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
	my		($Base,$pSys) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu("���[�U�ʒm�ꗗ","'sys.top','DISP','NOTICE'");
	$Base->SetMenu("���[�U�ʒm�쐬","'sys.top','DISP','NOTICE_CREATE'");
	
	# �V�X�e���Ǘ������̂�
	if	($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'},0,'*')){
		$Base->SetMenu('<hr>','');
		$Base->SetMenu("���샍�O�{��","'sys.top','DISP','ADMINLOG'");
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
	my		($Page,$Sys,$Form) = @_;
	my		($Notices,@noticeSet,$from,$subj,$text,$date,$id,$common);
	my		($dispNum,$i,$dispSt,$dispEd,$listNum,$isAuth,$curUser);
	
	$Sys->Set('_TITLE','User Notice List');
	
	require('./module/gandalf.pl');
	require('./module/galadriel.pl');
	$Notices = new GANDALF;
	
	# �ʒm���̓ǂݍ���
	$Notices->Load($Sys);
	
	# �ʒm�����擾
	$Notices->GetKeySet('ALL','',\@noticeSet);
	@noticeSet = sort(@noticeSet);
	@noticeSet = reverse(@noticeSet);
	
	# �\�����̐ݒ�
	$listNum	= @noticeSet;
	$dispNum	= ($Form->Get('DISPNUM_NOTICE') eq '' ? 5 : $Form->Get('DISPNUM_NOTICE'));
	$dispSt		= ($Form->Get('DISPST_NOTICE') eq '' ? 0 : $Form->Get('DISPST_NOTICE'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('sys.top','DISP','NOTICE');";
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td></td><td><b><a href=\"javascript:SetOption('DISPST_NOTICE'," . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_NOTICE',");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td align=right colspan=2>");
	$Page->Print("�\\����<input type=text name=DISPNUM_NOTICE size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\"><br></td>");
	$Page->Print("<td colspan=3 class=\"DetailTitle\">Notification</td></tr>\n");
	
	# �J�����g���[�U
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	# �ʒm�ꗗ���o��
	for	($i = $dispSt;$i < $dispEd;$i++){
		$id = $noticeSet[$i];
		if	($Notices->IsInclude($id,$curUser) && !$Notices->IsLimitOut($id)){
			if	($Notices->Get('FROM',$id) eq '0000000000'){
				$from = '0ch�Ǘ��V�X�e��';
			}
			else{
				$from = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'}->Get('NAME',$Notices->Get('FROM',$id));
			}
			$subj = $Notices->Get('SUBJECT',$id);
			$text = $Notices->Get('TEXT',$id);
			$date = GALADRIEL::GetDateFromSerial(undef,$Notices->Get('DATE',$id),0);
			
			$Page->Print("<tr><td><input type=checkbox name=NOTICES value=\"$id\"></td>");
			$Page->Print("<td class=\"Response\" colspan=3>");
			$Page->Print("<dt><b>$subj <font color=blue>From�F</b>$from</font>�@");
			$Page->Print("$date</dt><dd><br>$text<br><br></dd>\n");
		}
		else{
			$dispEd++	if	($dispEd + 1 < $listNum);
		}
	}
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'DELETE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table></dl><br>");
	$Page->HTMLInput('hidden','DISPST_NOTICE','');
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
	my		($Page,$Sys,$Form) = @_;
	my		($isSysad,$User,@userSet,$id,$name,$full);
	
	$Sys->Set('_TITLE','User Notice Create');
	
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},0,'*');
	$User = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'};
	$User->GetKeySet('ALL','',\@userSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">�^�C�g��</td><td>");
	$Page->Print("<input type=text size=60 name=NOTICE_TITLE></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�{��</td><td>");
	$Page->Print("<textarea rows=10 cols=70 name=NOTICE_CONTENT wrap=off></textarea></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�ʒm�惆�[�U</td><td>");
	$Page->Print("<table width=100% cellspaing=2>");
	
	if	($isSysad){
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=radio name=NOTICE_KIND value=ALL>�S�̒ʒm</td>");
		$Page->Print("<td>�L�������F<input type=text name=NOTICE_LIMIT size=10 value=30>��</td></tr>");
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=radio name=NOTICE_KIND value=ONE checked>�ʒʒm</td><td>");
	}
	else{
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=hidden name=NOTICE_KIND value=ONE>�ʒʒm</td><td>");
	}
	
	# ���[�U�ꗗ��\��
	foreach	$id (@userSet){
		$name = $User->Get('NAME',$id);
		$full = $User->Get('FULL',$id);
		$Page->Print("<input type=checkbox name=NOTICE_USERS value=\"$id\"> $name�i$full�j<br>");
	}
	$Page->Print("</td></tr></table></td></tr>");
	
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@���M�@\" $common,'CREATE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table>");
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
	my		($Page,$Sys,$Form,$Logger) = @_;
	my		($common);
	my		($dispNum,$i,$dispSt,$dispEd,$listNum,$isSysad,$data,@elem);
	
	$Sys->Set('_TITLE','Operation Log');
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},0,'*');
	
	# �\�����̐ݒ�
	$listNum	= $Logger->Size();
	$dispNum	= ($Form->Get('DISPNUM_LOG') eq '' ? 10 : $Form->Get('DISPNUM_LOG'));
	$dispSt		= ($Form->Get('DISPST_LOG') eq '' ? 0 : $Form->Get('DISPST_LOG'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	$common		= "DoSubmit('sys.top','DISP','ADMINLOG');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST_LOG'," . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_LOG',");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td align=right colspan=2>");
	$Page->Print("�\\����<input type=text name=DISPNUM_LOG size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">Date</td>");
	$Page->Print("<td class=\"DetailTitle\">User</td>");
	$Page->Print("<td class=\"DetailTitle\">Operation</td>");
	$Page->Print("<td class=\"DetailTitle\">Result</td></tr>\n");
	
	require('./module/galadriel.pl');
	
	# ���O�ꗗ���o��
	for	($i = $dispSt;$i < $dispEd;$i++){
		$data = $Logger->Get($listNum - $i - 1);
		@elem = split(/<>/,$data);
		if	(1){
			$elem[0] = GALADRIEL::GetDateFromSerial(undef,$elem[0],0);
			$Page->Print("<tr><td>$elem[0]</td><td>$elem[1]</td><td>$elem[2]</td><td>$elem[3]</td></tr>\n");
		}
		else{
			$dispEd++	if	($dispEd + 1 < $listNum);
		}
	}
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"���O�̍폜\" $common,'LOG_REMOVE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	$Page->HTMLInput('hidden','DISPST_LOG','');
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
	my		($Sys,$Form,$pLog) = @_;
	my		($Notice,$subject,$content,$date,$limit,$users);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	($chkID eq ''){
			return 1000;
		}
	}
	# ���̓`�F�b�N
	{
		my	@inList = ('NOTICE_TITLE','NOTICE_CONTENT');
		if	(!$Form->IsInput(@inList)){
			return 1001;
		}
		@inList = ('NOTICE_LIMIT');
		if	($Form->Equal('NOTICE_KIND','ALL') && !$Form->IsInput(@inList)){
			return 1001;
		}
		@inList = ('NOTICE_USERS');
		if	($Form->Equal('NOTICE_KIND','ONE') && !$Form->IsInput(@inList)){
			return 1001;
		}
	}
	require('./module/gandalf.pl');
	$Notice = new GANDALF;
	$Notice->Load($Sys);
	
	$date = time();
	$subject = $Form->Get('NOTICE_TITLE');
	$content = $Form->Get('NOTICE_CONTENT');
	$content =~ s/\r\n|\r|\n/<br>/g;
	
	if	($Form->Equal('NOTICE_KIND','ALL')){
		$users = '*';
		$limit = $Form->Get('NOTICE_LIMIT');
		$limit = $date + ($limit * 24 * 60 * 60);
	}
	else{
		my	@toSet = $Form->GetAtArray('NOTICE_USERS');
		$users = join(',',@toSet);
		$limit = 0;
	}
	# �ʒm����ǉ�
	$Notice->Add($users,$Sys->Get('ADMIN')->{'USER'},$subject,$content,$limit);
	$Notice->Save($Sys);
	
	push(@$pLog,"���[�U�ւ̒ʒm�I��");
	
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
	my		($Sys,$Form,$pLog) = @_;
	my		($Notice,@noticeSet,$curUser,$id);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	($chkID eq ''){
			return 1000;
		}
	}
	require('./module/gandalf.pl');
	$Notice = new GANDALF;
	$Notice->Load($Sys);
	
	@noticeSet = $Form->GetAtArray('NOTICES');
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	foreach	$id	(@noticeSet){
		if	($Notice->Get('TO',$id) eq '*'){
			my	$subj = $Notice->Get('SUBJECT',$id);
			push(@$pLog,"�ʒm�u$subj�v�͑S�̒ʒm�Ȃ̂ō폜�ł��܂���ł����B");
		}
		else{
			my	$subj = $Notice->Get('SUBJECT',$id);
			$Notice->RemoveToUser($id,$curUser);
			push(@$pLog,"�ʒm�u$subj�v���폜���܂����B");
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
	my		($Sys,$Form,$Logger,$pLog) = @_;
	my		($Notice,@noticeSet,$curUser,$id);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	(($SEC->IsAuthority($chkID,0,'*')) == 0){
			return 1000;
		}
	}
	$Logger->Clear();
	push(@$pLog,"���샍�O���폜���܂����B");
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

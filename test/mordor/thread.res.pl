#============================================================================================================
#
#	�X���b�h�Ǘ� - ���X ���W���[��
#	thread.res.pl
#	---------------------------------------------------------------------------
#	2004.07.21 start
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
		'LOG' => \@LOG
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
	my		($subMode,$BASE,$BBS,$DAT);
	
	require('./mordor/sauron.pl');
	$BASE = new SAURON;
	$BBS = $pSys->{'AD_BBS'};
	$DAT = $pSys->{'AD_DAT'};
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	if	($pSys->{'AD_BBS'} eq undef){
		require('./module/nazguls.pl');
		$BBS = new NAZGUL;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS',$BBS->Get('DIR',$Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR',$Form->Get('TARGET_BBS')));
	}
	
	# dat�̓ǂݍ���
	if	($pSys->{'AD_DAT'} eq undef){
		require('./module/gondor.pl');
		$DAT = new ARAGORN;
		
		$Sys->Set('KEY',$Form->Get('TARGET_THREAD'));
		my	$datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
		$DAT->Load($Sys,$datPath,1);
	}
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys,$Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE,$pSys,$Sys->Get('BBS'));
	
	if		($subMode eq 'LIST'){													# ���X�ꗗ���
		PrintResList($Page,$Sys,$Form,$DAT);
	}
	elsif	($subMode eq 'EDIT'){													# ���X�ҏW���
		PrintResEdit($Page,$Sys,$Form,$DAT);
	}
	elsif	($subMode eq 'ABONE'){													# ���X�폜�m�F���
		PrintResDelete($Page,$Sys,$Form,$DAT,1);
	}
	elsif	($subMode eq 'DELETE'){													# ���X�폜�m�F���
		PrintResDelete($Page,$Sys,$Form,$DAT,0);
	}
	elsif	($subMode eq 'DELLUMP'){												# ���X�ꊇ�폜���
		PrintResLumpDelete($Page,$Sys,$Form,$DAT);
	}
	elsif	($subMode eq 'COMPLETE'){												# �������
		$Sys->Set('_TITLE','Process Complete');
		$BASE->PrintComplete('�ߋ����O����',$this->{'LOG'});
	}
	elsif	($subMode eq 'FALSE'){													# ���s���
		$Sys->Set('_TITLE','Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# �f���E�X���b�h����ݒ�
	$Page->HTMLInput('hidden','TARGET_BBS',$Form->Get('TARGET_BBS'));
	$Page->HTMLInput('hidden','TARGET_THREAD',$Form->Get('TARGET_THREAD'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME',$Form->Get('TARGET_BBS'))
					. ' - ' . $DAT->GetSubject(),3);
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
	my		($subMode,$err,$BBS,$DAT);
	
	require('./module/gondor.pl');
	require('./module/nazguls.pl');
	$BBS = new NAZGUL;
	$DAT = new ARAGORN;
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	eval{
		$BBS->Load($Sys);
		$Sys->Set('BBS',$BBS->Get('DIR',$Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR',$Form->Get('TARGET_BBS')));
	};
	
	# dat�̓ǂݍ���
	eval{
		$Sys->Set('KEY',$Form->Get('TARGET_THREAD'));
		my	$datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
		$DAT->Load($Sys,$datPath,1);
	};
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if		($subMode eq 'EDIT'){													# ���X�ҏW
		$err = FunctionResEdit($Sys,$Form,$DAT,$this->{'LOG'});
	}
	elsif		($subMode eq 'ABONE'){												# ���X���ځ`��
		$err = FunctionResDelete($Sys,$Form,$DAT,$this->{'LOG'},1);
	}
	elsif		($subMode eq 'DELETE'){												# ���X�폜
		$err = FunctionResDelete($Sys,$Form,$DAT,$this->{'LOG'},0);
	}
	
	# �������ʕ\��
	if	($err){
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"RESPONSE($subMode)",'ERROR:'.$err);
		push(@{$this->{'LOG'}},$err);
		$Form->Set('MODE_SUB','FALSE');
	}
	else{
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"RESPONSE($subMode)",'COMPLETE');
		$Form->Set('MODE_SUB','COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
	$pSys->{'AD_DAT'} = $DAT;
	$this->DoPrint($Sys,$Form,$pSys);
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
	my		($Base,$pSys,$bbs) = @_;
	
	$Base->SetMenu("���X�ꗗ","'thread.res','DISP','LIST'");
	
	# ���X�폜�����̂�
	if	($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'},12,$bbs)){
		$Base->SetMenu("���X�ꊇ�폜","'thread.res','DISP','DELLUMP'");
	}
	# �Ǘ��O���[�v�����̂�
	if	($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'},1,$bbs)){
		$Base->SetMenu("<hr>","");
		$Base->SetMenu("�������݃��O","'thread.res','DISP','LOG_THREAD_WRITE'");
	}
	$Base->SetMenu("<hr>","");
	$Base->SetMenu("�f���Ǘ��֖߂�","'bbs.thread','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResList
{
	my		($Page,$Sys,$Form,$Dat) = @_;
	my		(@elem,$resNum,$dispNum,$dispSt,$dispEd,$common,$i);
	my		($pRes,$isAbone,$isEdit);
	
	$Sys->Set('_TITLE','Res List');
	
	# �\�������̐ݒ�
	$format = $Form->Get('DISP_FORMAT') eq '' ? '-10' : $Form->Get('DISP_FORMAT');
	($dispSt,$dispEd) = AnalyzeFormat($format,$Dat);
	
	$common	= "DoSubmit('thread.res','DISP','LIST');";
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2 align=right>�\\�������F<input type=text name=DISP_FORMAT");
	$Page->Print(" value=\"$format\"><input type=button value=\"�@�\\���@\" onclick=\"$common\">");
	$Page->Print("</td></tr>\n<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:300\">Contents</td></tr>\n");
	
	# �����擾
	$isAbone = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},12,$Sys->Get('BBS'));
	$isEdit = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},13,$Sys->Get('BBS'));
	
	# ���X�ꗗ���o��
	for	($i = $dispSt;$i < $dispEd;$i++){
		$pRes	= $Dat->Get($i);
		@elem	= split(/<>/,$$pRes);
		
		$Page->Print("<tr><td class=\"Response\" valign=top>");
		
		# ���X�폜���ɂ��\���}��
		if	($isAbone){
			$Page->Print("<input type=checkbox name=RESS value=$i></td>");
		}
		else{
			$Page->Print("</td>");
		}
		$Page->Print("<td class=\"Response\"><dt>");
		
		# ���X�ҏW���ɂ��\���}��
		if	($isEdit){
			$common = "\"javascript:SetOption('SELECT_RES','$i');";
			$common = $common . "DoSubmit('thread.res','DISP','EDIT')\"";
			$Page->Print("<a href=$common>" . ($i + 1) . "</a>");
		}
		else{
			$Page->Print('' . ($i + 1));
		}
		$Page->Print("�F<font color=forestgreen><b>$elem[0]</b></font>[$elem[1]]");
		$Page->Print("�F$elem[2]</dt><dd>$elem[3]<br><br></dd></td></tr>\n");
	}
	$Page->HTMLInput('hidden','SELECT_RES','');
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �V�X�e�������L���ɂ��\���}��
	if	($isAbone){
		$common = "onclick=\"DoSubmit('thread.res','DISP'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"���ځ`��\" $common,'ABONE')\"> ");
		$Page->Print("<input type=button value=\"�������ځ`��\" $common,'DELETE')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table></dl><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResEdit
{
	my		($Page,$Sys,$Form,$Dat) = @_;
	my		(@elem,$pRes,$isEdit);
	
	$Sys->Set('_TITLE','Res Edit');
	
	$isEdit = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},13,$Sys->Get('BBS'));
	$pRes	= $Dat->Get($Form->Get('SELECT_RES'));
	@elem	= split(/<>/,$$pRes);
	
	# <br>�����s�ɕϊ�
	$elem[3] =~ s/<br>/\n/g;
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���O</td><td>");
	$Page->Print("<input type=text size=50 value=\"$elem[0]\" name=FROM></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���[��</td><td>");
	$Page->Print("<input type=text size=50 value=\"$elem[1]\" name=mail></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���t�EID</td><td>");
	$Page->Print("<input type=text size=50 value=\"$elem[2]\" name=_DATE_></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">�{��</td><td>");
	$Page->Print("<textarea name=MESSAGE cols=70 rows=10>$elem[3]</textarea></td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>");
	
	$Page->HTMLInput('hidden','SELECT_RES',$Form->Get('SELECT_RES'));
	
	# �V�X�e�������L���ɂ��\���}��
	if	($isEdit){
		$common = "onclick=\"DoSubmit('thread.res','FUNC'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�ύX�@\" $common,'EDIT')\"> ");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�폜�m�F�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResDelete
{
	my		($Page,$Sys,$Form,$Dat,$mode) = @_;
	my		(@resSet,@elem,$pRes,$num,$common,$isAbone);
	
	$Sys->Set('_TITLE','Res Delete Confirm');
	
	# �I�����X���擾
	@resSet = $Form->GetAtArray('RESS');
	
	# �����擾
	$isAbone = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},12,$Sys->Get('BBS'));
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td>�ȉ��̃��X��" . ($mode ? '���ځ`��' : '�폜') . "���܂��B</td></tr>\n");
	$Page->Print("<tr><td><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Contents</td></tr>\n");
	
	# ���X�ꗗ���o��
	foreach	$num (@resSet){
		$pRes	= $Dat->Get($num);
		@elem	= split(/<>/,$$pRes);
		
		$Page->Print("<tr><td class=\"Response\"><dt>" . ($num + 1));
		$Page->Print("�F<font color=forestgreen><b>$elem[0]</b></font>[$elem[1]]");
		$Page->Print("�F$elem[2]</dt><dd>$elem[3]<br><br></dd></td></tr>\n");
		$Page->HTMLInput('hidden','RESS',$num);
	}
	$Page->Print("<tr><td><hr></td></tr>\n");
	
	# �V�X�e�������L���ɂ��\���}��
	if	($isAbone){
		$common = "onclick=\"DoSubmit('thread.res','FUNC','";
		$common = $common . ($mode ? 'ABONE' : 'DELETE') . "')\"";
		$Page->Print("<tr><td align=right>");
		$Page->Print("<input type=button value=\"�@���s�@\" $common> ");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table></dl><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�ꊇ�폜�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResLumpDelete
{
	my		($Page,$Sys,$Form,$Dat) = @_;
	my		(@resSet,@elem,$pRes,$format,$num,$common,$isAbone);
	
	$Sys->Set('_TITLE','Res Lump Delete');
	
	# �����̉��
	$format = $Form->Get('DEL_FORMAT');
	if	($format ne ''){
		AnalyzeDeleteFormat($format,$Dat,\@resSet);
		$num = @resSet;
	}
	
	# �����擾
	$isAbone = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},12,$Sys->Get('BBS'));
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�폜���X����</td><td>");
	$Page->Print("<input type=text name=DEL_FORMAT size=40 value=$format></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	if	($num > 0){
		$Page->Print("<tr><td colspan=2 class=\"DetailTitle\">Delete Contents</td></tr>");
		
		# ���X�ꗗ���o��
		foreach	$num (@resSet){
			$pRes	= $Dat->Get($num);
			@elem	= split(/<>/,$$pRes);
			
			$Page->Print("<tr><td colspan=2 class=\"Response\"><dt>" . ($num + 1));
			$Page->Print("�F<font color=forestgreen><b>$elem[0]</b></font>[$elem[1]]");
			$Page->Print("�F$elem[2]</dt><dd>$elem[3]<br><br></dd></td></tr>\n");
			$Page->HTMLInput('hidden','RESS',$num);
		}
		$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	}
	
	# �V�X�e�������L���ɂ��\���}��
	if	($isAbone){
		$common = "onclick=\"DoSubmit('thread.res'";
		$Page->Print("<tr><td align=right colspan=2>");
		$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','DELLUMP')\"> ");
		$Page->Print("<input type=button value=\"���ځ`��\" $common,'FUNC','ABONE')\"> ");
		$Page->Print("<input type=button value=\"�������ځ`��\" $common,'FUNC','DELETE')\"> ");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table></dl><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	Dat�ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionResEdit
{
	my		($Sys,$Form,$Dat,$pLog) = @_;
	my		(@elem,$pRes,$data);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $Sys->Get('ADMIN')->{'USER'};
		
		if	(($SEC->IsAuthority($chkID,13,$Sys->Get('BBS'))) == 0){
			return 1000;
		}
	}
	
	# �������݃��[�h�œǂݒ���
	$Dat->ReLoad($Sys,0);
	
	$pRes		= $Dat->Get($Form->Get('SELECT_RES'));
	@elem		= split(/<>/,$$pRes);
	$elem[0]	= $Form->Get('FROM');
	$elem[1]	= $Form->Get('mail');
	$elem[2]	= $Form->Get('_DATE_');
	$elem[3]	= $Form->Get('MESSAGE');
	
	# ���s�E�֑������̕ϊ�
	$elem[3]	=~ s/\r\n|\r|\n/<br>/g;
	$elem[3]	=~ s/<>/&lt;&gt;/g;
	
	# �f�[�^�̘A��
	$data		= join('<>',@elem);
	
	# �f�[�^�̐ݒ�ƕۑ�
	$Dat->Set($Form->Get('SELECT_RES'),$data);
	$Dat->Save($Sys);
	
	# ���O�̐ݒ�
	push(@$pLog,'�ԍ�[' . $Form->Get('SELECT_RES') . ']�̃��X���ȉ��̂悤�ɕύX���܂����B');
	foreach	(@elem){
		push(@$pLog,$_);
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	Dat�ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionResDelete
{
	my		($Sys,$Form,$Dat,$pLog,$mode) = @_;
	my		(@resSet,$pRes,$abone,$path,$tm,$user,$delCnt,$num,$datPath);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $Sys->Get('ADMIN')->{'USER'};
		
		if	(($SEC->IsAuthority($chkID,12,$Sys->Get('BBS'))) == 0){
			return 1000;
		}
	}
	
	# ���ځ`�񎞂͍폜�����擾
	if	($mode){
		my	$Setting;
		require('./module/isildur.pl');
		$Setting = new ISILDUR;
		$Setting->Load($Sys);
		$abone	= $Setting->Get('BBS_DELETE_NAME');
	}
	
	# �e�l��ݒ�
	@resSet	= $Form->GetAtArray('RESS');
	$datPath= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/del_' . $Sys->Get('KEY') . '.cgi';
	$tm		= time;
	$user	= $Form->Get('UserName');
	$delCnt	= 0;
	
	# dat���������݃��[�h�œǂݒ���
	$Dat->Close();
	$Dat->Load($Sys,$datPath,0);
	
	# �폜�Ɠ����ɍ폜���O�֍폜�������e��ۑ�����
	eval{
		open(DELLOG,">>$path");
		flock(DELLOG,2);
		binmode(DELLOG);
		foreach	$num (@resSet){
			$pRes = $Dat->Get($num - $delCnt);
			print DELLOG "$tm<>$user<>$num<>$mode<>$$pRes";
			if	($mode){
				$Dat->Set($num,"$abone<>$abone<>$abone<>$abone<>$abone\n");
			}
			else{
				$Dat->Delete($num - $delCnt);
				$delCnt ++;
			}
		}
		close(DELLOG);
		chmod($Sys->Get('PM-LOG'),$path);
	};
	
	# �ۑ�
	$Dat->Save($Sys);
	
	# ���O�̐ݒ�
	$delCnt = 0;
	$abone	= '';
	push(@$pLog,'�ȉ��̃��X��' . ($mode ? '���ځ`��' : '�폜') . '���܂����B');
	foreach	(@resSet){
		if	($delCnt > 5){
			push(@$pLog,$abone);
			$abone = '';
			$delCnt = 0;
		}
		else{
			$abone .= ($_ + 1) . ',';
			$delCnt ++;
		}
	}
	push(@$pLog,$abone);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�폜�����̉��
#	-------------------------------------------------------------------------------------
#	@param	$format	����������
#	@param	$Dat	ARAGORN�I�u�W�F�N�g
#	@param	$pSet	���ʊi�[�z��̎Q��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub AnalyzeDeleteFormat
{
	my	($format,$Dat,$pSet) = @_;
	my	(%deleteTable,@elem,$i,$st,$ed);
	
	# �Z�p���[�^�ŕ���
	@elem = split(/\,/,$format);
	
	# 1�敪��������͂����ăn�b�V��(��d�o�^�h�~�̂���)�Ɋi�[
	foreach	(@elem){
		($st,$ed) = AnalyzeFormat($_,$Dat);
		if	($st != 0 || $ed != 0){
			for	($i = $st;$i < $ed;$i++){
				$deleteTable{$i} = 'true';
			}
		}
	}
	
	# ���ʂ�z��ɐݒ�
	foreach	(sort{$a<=>$b}(keys(%deleteTable))){
		push(@$pSet,$_);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�����̉��
#	-------------------------------------------------------------------------------------
#	@param	$format	����������
#	@param	$Dat	ARAGORN�I�u�W�F�N�g
#	@return	(�J�n�ԍ�,�I���ԍ�)
#
#------------------------------------------------------------------------------------------------------------
sub AnalyzeFormat
{
	my	($format,$Dat) = @_;
	my	($start,$end,$max);
	
	# �����G���[
	if	($format =~ /[^0-9\-l]/ || $format eq ''){
		return (0,0);
	}
	$max = $Dat->Size();
	
	# �ŐVn��
	if		($format =~ /l(\d+)/){
		$end	= $max;
		$start	= ($max - $1) > 0 ? ($max - $1) : 1;
	}
	# n�`m
	elsif	($format =~ /(\d+)-(\d+)/){
		$start	= $1 > $max ? $max : $1;
		$end	= $2 > $max ? $max : $2;
	}
	# n�ȍ~���ׂ�
	elsif	($format =~ /(\d+)-/){
		$start	= $1 > $max ? $max : $1;
		$end	= $max;
	}
	# n�ȑO���ׂ�
	elsif	($format =~ /-(\d+)/){
		$start	= 1;
		$end	= $1 > $max ? $max : $1;
	}
	# n�̂�
	elsif	($format =~ /(\d+)/){
		$start	= $1 > $max ? $max : $1;
		$end	= $1 > $max ? $max : $1;
	}
	
	# �������K��
	if	($start > $end){
		$max = $start;
		$start = $end;
		$end = $start;
	}
	
	return ($start - 1,$end);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

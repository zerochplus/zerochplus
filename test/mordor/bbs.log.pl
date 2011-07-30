#============================================================================================================
#
#	�f���Ǘ� - ���O�{�� ���W���[��
#	bbs.log.pl
#	---------------------------------------------------------------------------
#	2005.05.21 start
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
	
	if ($subMode eq 'INFO') {														# �g�b�v���
		PrintLogsInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'THREADLOG') {												# �X���b�h�쐬���O���
		PrintLogs($Page, $Sys, $Form, 0);
	}
	elsif ($subMode eq 'HOSTLOG') {													# �z�X�g���O���
		PrintLogs($Page, $Sys, $Form, 1);
	}
	elsif ($subMode eq 'ERRORLOG') {												# �G���[���O���
		PrintLogs($Page, $Sys, $Form, 2);
	}
	elsif ($subMode eq 'COMPLETE') {												# �������
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('���O���쏈��', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# ���s���
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
	
	if ($subMode eq 'REMOVE_THREADLOG') {										# ���O�폜
		$err = FunctionLogDelete($Sys, $Form, 0, $this->{'LOG'});
	}
	elsif ($subMode eq 'REMOVE_HOSTLOG') {										# ���O�폜
		$err = FunctionLogDelete($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'REMOVE_ERRORLOG') {										# ���O�폜
		$err = FunctionLogDelete($Sys, $Form, 2, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS_LOG($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS_LOG($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('���O���', "'bbs.log','DISP','INFO'");
	$Base->SetMenu('<hr>', '');
	
	# ���O�{�������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 15, $bbs)) {
		$Base->SetMenu('�X���b�h�쐬���O', "'bbs.log','DISP','THREADLOG'");
		$Base->SetMenu('�z�X�g���O', "'bbs.log','DISP','HOSTLOG'");
		$Base->SetMenu('�G���[���O', "'bbs.log','DISP','ERRORLOG'");
		$Base->SetMenu('<hr>', '');
	}
	$Base->SetMenu('�V�X�e���Ǘ��֖߂�', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	���O���̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLogsInfo
{
	my ($Page, $Sys, $Form) = @_;
	my (@logFiles, $i, $size, $date);
	
	$logFiles[0] = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/IP.cgi';
	$logFiles[1] = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/HOST.cgi';
	$logFiles[2] = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/errs.cgi';
	
	$Sys->Set('_TITLE', 'Log Information');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\" style=\"width:50\">Log Kind</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:150\">Log File</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:200\">File Size</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Last Update</td></tr>\n");
	
	require './module/galadriel.pl';
	my @logKind = ('�X���b�h�쐬���O', '�z�X�g���O', '�G���[���O');
	
	for ($i = 0 ; $i < 3 ; $i++) {
		$size = (stat $logFiles[$i])[7];
		$date = (stat _)[9];
		$date = GALADRIEL::GetDateFromSerial(undef, $date, 0);
		
		$Page->Print("<tr><td>$logKind[$i]</td>");
		$Page->Print("<td>$logFiles[$i]</td>");
		$Page->Print("<td>$size bytes</td>");
		$Page->Print("<td>$date</td></tr>\n");
	}
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	0:�X���b�h�쐬���O
#					1:�z�X�g���O
#					2:�G���[���O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLogs
{
	my ($Page, $Sys, $Form, $mode) = @_;
	my ($Logger, $common, $logFile, $keyNum, $keySt);
	my ($dispNum, $i, $dispSt, $dispEd, $listNum, $isSysad, $data, @elem);
	
	$Sys->Set('_TITLE', 'Thread Create Log')	if ($mode == 0);
	$Sys->Set('_TITLE', 'Hosts Log')			if ($mode == 1);
	$Sys->Set('_TITLE', 'Error Log')			if ($mode == 2);
	
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/IP'	if ($mode == 0);
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/HOST'	if ($mode == 1);
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/errs'	if ($mode == 2);
	$Logger->Open($logFile, 0, 1 | 2);
	
	$keyNum = 'DISPNUM_' . $Form->Get('MODE_SUB');
	$keySt = 'DISPST_' . $Form->Get('MODE_SUB');
	
	# �\�����̐ݒ�
	$listNum	= $Logger->Size();
	$dispNum	= ($Form->Get($keyNum) eq '' ? 10 : $Form->Get($keyNum));
	$dispSt		= ($Form->Get($keySt) eq '' ? 0 : $Form->Get($keySt));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	$common		= "DoSubmit('bbs.log','DISP','" . $Form->Get('MODE_SUB') . "');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('$keySt', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('$keySt', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td align=right colspan=2>");
	$Page->Print("�\\����<input type=text name=$keyNum size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"�@�\\���@\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	# �J�����w�b�_�̕\��
	$Page->Print("<tr><td class=\"DetailTitle\">Date</td>");
	if ($mode == 0) {
		$Page->Print("<td class=\"DetailTitle\">Thread KEY</td>");
		$Page->Print("<td class=\"DetailTitle\">Script ver.</td>");
		$Page->Print("<td class=\"DetailTitle\">Create HOST</td></tr>\n");
	}
	elsif ($mode == 1) {
		$Page->Print("<td class=\"DetailTitle\">HOST</td>");
		$Page->Print("<td class=\"DetailTitle\">Thread KEY</td>");
		$Page->Print("<td class=\"DetailTitle\">Operation</td></tr>\n");
	}
	elsif ($mode == 2) {
		$Page->Print("<td class=\"DetailTitle\">Error Code</td>");
		$Page->Print("<td class=\"DetailTitle\">Script ver.</td>");
		$Page->Print("<td class=\"DetailTitle\">HOST</td></tr>\n");
	}
	
	require './module/galadriel.pl';
	
	# ���O�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$data = $Logger->Get($listNum - $i - 1);
		@elem = split(/<>/, $data);
		if (1) {
			$elem[0] = GALADRIEL::GetDateFromSerial(undef, $elem[0], 0);
			$Page->Print("<tr><td>$elem[0]</td><td>$elem[1]</td><td>$elem[2]</td><td>$elem[3]</td></tr>\n");
		}
		else {
			$dispEd++ if ($dispEd + 1 < $listNum);
		}
	}
	$common = "onclick=\"DoSubmit('bbs.log','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"�@�폜�@\" $common,'REMOVE_" . $Form->Get('MODE_SUB') . "')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	$Page->HTMLInput('hidden', $keySt, '');
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	0:�X���b�h�쐬���O
#					1:�z�X�g���O
#					2:�G���[���O
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogDelete
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	my ($Logger, $logFile, $size, @dummy);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 15, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/IP'	if ($mode == 0);
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/HOST'	if ($mode == 1);
	$logFile = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/errs'	if ($mode == 2);
	
#	eval
	{
		# ���O���̍폜
		$Logger->Open($logFile, 0, 2 | 4);
		
		# �������O��ޔ�����
		$Logger->MoveToOld();
		push @$pLog, '�������O�̑ޔ�����...';
		
		# ���O�̃N���A�ƕۑ�
		$Logger->Clear();
		$Logger->Write();
		$Logger->Close();
		push @$pLog, '���O�̍폜����...';
	};
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

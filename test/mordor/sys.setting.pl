#============================================================================================================
#
#	�V�X�e���Ǘ� - �ݒ� ���W���[��
#	sys.setting.pl
#	---------------------------------------------------------------------------
#	2004.02.14 start
#
#	���낿���˂�v���X
#	2010.08.12 �ݒ荀�ڒǉ��ɂ�����
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
	my ($subMode, $BASE, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	# �Ǘ�����o�^
	$Sys->Set('ADMIN', $pSys);
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'INFO') {														# �V�X�e�������
		PrintSystemInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'BASIC') {													# ��{�ݒ���
		PrintBasicSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PERMISSION') {												# �p�[�~�b�V�����ݒ���
		PrintPermissionSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'LIMITTER') {												# ���~�b�^�ݒ���
		PrintLimitterSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'OTHER') {													# ���̑��ݒ���
		PrintOtherSetting($Page, $Sys, $Form);
	}
=pod
	elsif ($subMode eq 'PLUS') {													# ����v���X�I���W�i��
		PrintPlusSetting($Page, $Sys, $Form);
	}
=cut
	elsif ($subMode eq 'VIEW') {													# �\���ݒ�
		PrintPlusViewSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SEC') {														# �K���ݒ�
		PrintPlusSecSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PLUGIN') {													# �g���@�\�ݒ���
		PrintPluginSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �V�X�e���ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�V�X�e���ݒ菈��', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �V�X�e���ݒ莸�s���
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
	
	if ($subMode eq 'BASIC') {														# ��{�ݒ�
		$err = FunctionBasicSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'PERMISSION') {												# �p�[�~�b�V�����ݒ�
		$err = FunctionPermissionSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'LIMITTER') {												# �����ݒ�
		$err = FunctionLimitterSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'OTHER') {													# ���̑��ݒ�
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
=pod
	elsif ($subMode eq 'PLUS') {													# ����v���X�I���W�i��
		$err = FunctionPlusSetting($Sys, $Form, $this->{'LOG'});
	}
=cut
	elsif ($subMode eq 'VIEW') {													# �\���ݒ�
		$err = FunctionPlusViewSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SEC') {														# �K���ݒ�
		$err = FunctionPlusSecSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SET_PLUGIN') {												# �g���@�\���ݒ�
		$err = FunctionPluginSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE_PLUGIN') {											# �g���@�\���X�V
		$err = FunctionPluginUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('���', "'sys.setting','DISP','INFO'");
	
	# �V�X�e���Ǘ������̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('��{�ݒ�', "'sys.setting','DISP','BASIC'");
		$Base->SetMenu('�p�[�~�b�V�����ݒ�', "'sys.setting','DISP','PERMISSION'");
		$Base->SetMenu('���~�b�^�ݒ�', "'sys.setting','DISP','LIMITTER'");
		$Base->SetMenu('���̑��ݒ�', "'sys.setting','DISP','OTHER'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('�\���ݒ�', "'sys.setting','DISP','VIEW'");
		$Base->SetMenu('�K���ݒ�', "'sys.setting','DISP','SEC'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('�g���@�\\�ݒ�', "'sys.setting','DISP','PLUGIN'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e������ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemInfo
{
	my ($Page, $SYS, $Form) = @_;
	
	$SYS->Set('_TITLE', '0ch+ Administrator Information');
	
	$Page->Print("<br><b>0ch+ BBS - Administrator Script</b>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e����{�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBasicSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($server, $cgi, $bbs, $info, $data, $common);
	
	$SYS->Set('_TITLE', 'System Base Setting');
	
	$server	= $SYS->Get('SERVER');
	$cgi	= $SYS->Get('CGIPATH');
	$bbs	= $SYS->Get('BBSPATH');
	$info	= $SYS->Get('INFO');
	$data	= $SYS->Get('DATA');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','BASIC');\"";
	$server = 'http://' . $ENV{'SERVER_NAME'}	if ($server eq '');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�ғ��T�[�o</td>");
	$Page->Print("<td><input type=text size=60 name=SERVER value=\"$server\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">CGI�ݒu�f�B���N�g���i���΃p�X�j</td>");
	$Page->Print("<td><input type=text size=60 name=CGIPATH value=\"$cgi\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�f���z�u�f�B���N�g���i���΃p�X�j</td>");
	$Page->Print("<td><input type=text size=60 name=BBSPATH value=\"$bbs\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�V�X�e�����f�B���N�g���i���΃p�X�j</td>");
	$Page->Print("<td><input type=text size=60 name=INFO value=\"$info\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�V�X�e���f�[�^�f�B���N�g���i���΃p�X�j</td>");
	$Page->Print("<td><input type=text size=60 name=DATA value=\"$data\" ></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�[�~�b�V�����ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintPermissionSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($datP, $txtP, $logP, $admP, $stopP, $admDP, $bbsDP, $logDP);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Permission Setting');
	
	$datP	= sprintf("%o", $SYS->Get('PM-DAT'));
	$txtP	= sprintf("%o", $SYS->Get('PM-TXT'));
	$logP	= sprintf("%o", $SYS->Get('PM-LOG'));
	$admP	= sprintf("%o", $SYS->Get('PM-ADM'));
	$stopP	= sprintf("%o", $SYS->Get('PM-STOP'));
	$admDP	= sprintf("%o", $SYS->Get('PM-ADIR'));
	$bbsDP	= sprintf("%o", $SYS->Get('PM-BDIR'));
	$logDP	= sprintf("%o", $SYS->Get('PM-LDIR'));
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','PERMISSION');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B<br>");
	$Page->Print("<b>�i8�i�l�Őݒ肷�邱�Ɓj</b></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">dat�t�@�C���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_DAT value=\"$datP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�e�L�X�g�t�@�C���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_TXT value=\"$txtP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���O�t�@�C���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG value=\"$logP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�Ǘ��t�@�C���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN value=\"$admP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">��~�X���b�h�t�@�C���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_STOP value=\"$stopP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�Ǘ��f�B���N�g���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN_DIR value=\"$admDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�f���f�B���N�g���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_BBS_DIR value=\"$bbsDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���O�ۑ��f�B���N�g���p�[�~�b�V����</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG_DIR value=\"$logDP\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�����ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> �V�X�e���ύX�ɔ����ݒ荀�ڂ̒ǉ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLimitterSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@vSYS, $common);
	
	$SYS->Set('_TITLE', 'System Limitter Setting');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','LIMITTER');\"";
	$vSYS[0] = $SYS->Get('RESMAX');
	$vSYS[1] = $SYS->Get('SUBMAX');
	$vSYS[2] = $SYS->Get('ANKERS');
	$vSYS[3] = $SYS->Get('ERRMAX');
	$vSYS[4] = $SYS->Get('HISMAX');
	$vSYS[5] = $SYS->Get('ADMMAX');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">1�f����subject�ő�ێ���</td>");
	$Page->Print("<td><input type=text size=10 name=SUBMAX value=\"$vSYS[1]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1�X���b�h�̃��X�ő吔</td>");
	$Page->Print("<td><input type=text size=10 name=RESMAX value=\"$vSYS[0]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1���X�̃A���J�[�ő吔(0�Ŗ�����)</td>");
	$Page->Print("<td><input type=text size=10 name=ANKERS value=\"$vSYS[2]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�G���[���O�ő�ێ���</td>");
	$Page->Print("<td><input type=text size=10 name=ERRMAX value=\"$vSYS[3]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�������ݗ����ő�ێ���</td>");
	$Page->Print("<td><input type=text size=10 name=HISMAX value=\"$vSYS[4]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�Ǘ����샍�O�ő�ێ���</td>");
	$Page->Print("<td><input type=text size=10 name=ADMMAX value=\"$vSYS[5]\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���̑��ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintOtherSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($urlLink, $linkSt, $linkEd, $pathKind, $headText, $headUrl, $FastMode, $BBSGET);
	my ($linkChk, $pathInfo, $pathQuery, $fastMode, $bbsget);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Other Setting');
	
	$urlLink	= $SYS->Get('URLLINK');
	$linkSt		= $SYS->Get('LINKST');
	$linkEd		= $SYS->Get('LINKED');
	$pathKind	= $SYS->Get('PATHKIND');
	$headText	= $SYS->Get('HEADTEXT');
	$headUrl	= $SYS->Get('HEADURL');
	$FastMode	= $SYS->Get('FASTMODE');
	$BBSGET		= $SYS->Get('BBSGET');
	
	$linkChk	= ($urlLink eq 'TRUE' ? 'checked' : '');
	$fastMode	= ($FastMode == 1 ? 'checked' : '');
	$pathInfo	= ($pathKind == 0 ? 'checked' : '');
	$pathQuery	= ($pathKind == 1 ? 'checked' : '');
	$bbsget		= ($BBSGET == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','OTHER');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">�w�b�_�֘A</td></tr>\n");
	$Page->Print("<tr><td>�w�b�_�����ɕ\\������e�L�X�g</td>");
	$Page->Print("<td><input type=text size=60 name=HEADTEXT value=\"$headText\" ></td></tr>\n");
	$Page->Print("<tr><td>��L�e�L�X�g�ɓ\\�郊���N��URL</td>");
	$Page->Print("<td><input type=text size=60 name=HEADURL value=\"$headUrl\" ></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">�{������URL</td></tr>\n");
	$Page->Print("<tr><td colpan=2><input type=checkbox name=URLLINK $linkChk value=on>");
	$Page->Print("�{����URL�ւ̎��������N</td>");
	$Page->Print("<tr><td colspan=2><b>�ȉ����������NOFF���̂ݗL��</b></td></tr>\n");
	$Page->Print("<tr><td>�@�@�����N�֎~���ԑ�</td>");
	$Page->Print("<td><input type=text size=2 name=LINKST value=\"$linkSt\" >�� �` ");
	$Page->Print("<input type=text size=2 name=LINKED value=\"$linkEd\" >��</td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">���샂�[�h(read.cgi)</td></tr>\n");
	$Page->Print("<tr><td>PATH���</td>");
	$Page->Print("<td><input type=radio name=PATHKIND value=\"0\" $pathInfo>PATHINFO�@");
	$Page->Print("<input type=radio name=PATHKIND value=\"1\" $pathQuery>QUERYSTRING</td></tr>\n");
	
	$Page->Print("<tr><td colpan=2><input type=checkbox name=FASTMODE $fastMode value=on>");
	$Page->Print("�����������݃��[�h</td>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">bbs.cgi��GET���\�b�h</td></tr>\n");
	$Page->Print("<tr><td>bbs.cgi��GET���\\�b�h���g�p����</td>");
	$Page->Print("<td><input type=checkbox name=BBSGET $bbsget value=on></td></tr>\n");
	
	
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�\���ݒ��ʂ̕\��(���낿���˂�v���X�I���W�i��)
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#	2010.09.08 windyakin ��
#	 -> �\���ݒ�ƋK���ݒ�̕���
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusViewSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($Banner, $Counter, $Prtext, $Prlink, $Msec);
	my ($banner, $msec);
	my ($common);
	
	$SYS->Set('_TITLE', 'System View Setting');
	
	$Banner		= $SYS->Get('BANNER');
	$Counter	= $SYS->Get('COUNTER');
	$Prtext		= $SYS->Get('PRTEXT');
	$Prlink		= $SYS->Get('PRLINK');
	$Msec		= $SYS->Get('MSEC');
	
	$banner		= ($Banner == 1 ? 'checked' : '');
	$msec		= ($Msec == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','VIEW');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Read.cgi�֘A</td></tr>\n");
	$Page->Print("<tr><td>ofuda.cc�̃A�J�E���g�������</td>");
	$Page->Print("<td><input type=text size=60 name=COUNTER value=\"$Counter\"></td></tr>\n");
	$Page->Print("<tr><td>PR���̕\\��������</td>");
	$Page->Print("<td><input type=text size=60 name=PRTEXT value=\"$Prtext\"></td></tr>\n");
	$Page->Print("<tr><td>PR���̃����NURL</td>");
	$Page->Print("<td><input type=text size=60 name=PRLINK value=\"$Prlink\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">���m���\\��</td></tr>\n");
	$Page->Print("<tr><td>index.html�ȊO�̍��m����\\������</td>");
	$Page->Print("<td><input type=checkbox name=BANNER $banner value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">msec�\\��</td></tr>\n");
	$Page->Print("<tr><td>�~���b�܂ŕ\\������</small></td>");
	$Page->Print("<td><input type=checkbox name=MSEC $msec value=on></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���ݒ��ʂ̕\��(���낿���˂�v���X�I���W�i��)
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#	2010.09.08 windyakin ��
#	 -> �\���ݒ�ƋK���ݒ�̕���
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusSecSetting
{
	
	my ($Page, $SYS, $Form) = @_;
	my ($Kakiko, $Samba, $isSamba, $Houshi, $Trip12, $BBQ, $BBX, $SpamCh);
	my ($kakiko, $trip12, $issamba, $bbq, $bbx, $spamch);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Regulation Setting');
	
	$Kakiko		= $SYS->Get('KAKIKO');
	$Samba		= $SYS->Get('SAMBATM');
	$Trip12		= $SYS->Get('TRIP12');
	$BBQ		= $SYS->Get('BBQ');
	$BBX		= $SYS->Get('BBX');
	$SpamCh		= $SYS->Get('SPAMCH');

	$kakiko		= ($Kakiko == 1 ? 'checked' : '');
	$trip12		= ($Trip12 == 1 ? 'checked' : '');
	$bbq		= ($BBQ == 1 ? 'checked' : '');
	$bbx		= ($BBX == 1 ? 'checked' : '');
	$spamch		= ($SpamCh == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','SEC');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>�e���ڂ�ݒ肵��[�ݒ�]�{�^���������Ă��������B</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">�Q�d�������ł����H�H</td></tr>\n");
	$Page->Print("<tr><td>����IP����̏������݂̕��������ω����Ȃ��ꍇ�K������</td>");
	$Page->Print("<td><input type=checkbox name=KAKIKO $kakiko value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">�A�����e�K��</td></tr>\n");
	$Page->Print("<tr><td>�A�����e�K���b�������(0�ŋK������)</td>");
	$Page->Print("<td><input type=text size=60 name=SAMBATM value=\"$Samba\"></td></tr>\n");
	$Page->Print("<tr><td>��Samba�̐ݒ肪�D�悳��܂��BSamba�̐ݒ�͔ʂł�</td>");
#	$Page->Print("<tr><td>Samba�ɂ���</td>");
#	$Page->Print("<td><input type=checkbox name=ISSAMBA $issamba value=on></td></tr>\n");
#	$Page->Print("<tr><td>Samba�K�����������(0�ŋK������)</td>");
#	$Page->Print("<td><input type=text size=60 name=HOUSHI value=\"$Houshi\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">�V�d�l�g���b�v</td></tr>\n");
	$Page->Print("<tr><td>�V�d�l�g���b�v(12�� =SHA-1)��L���ɂ���<br><small>�vDigest::SHA1���W���[��</small></td>");
	$Page->Print("<td><input type=checkbox name=TRIP12 $trip12 value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">DNSBL�ݒ�</td></tr>\n");
	$Page->Print("<tr><td colspan=2>�K�p����DNSBL�Ƀ`�F�b�N������Ă�������<br>\n");
	$Page->Print("<input type=checkbox name=BBQ $bbq value=on>");
	$Page->Print("<a href=\"http://bbq.uso800.net/\" target=\"_blank\">BBQ</a>\n");
	$Page->Print("<input type=checkbox name=BBX $bbx value=on>BBX\n");
	$Page->Print("<input type=checkbox name=SPAMCH $spamch value=on>");
	$Page->Print("<a href=\"http://spam-champuru.livedoor.com/dnsbl/\" target=\"_blank\">�X�p�������Ղ�[</a>\n");
	$Page->Print("</td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintPluginSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@pluginSet, $num, $common, $Plugin);
	
	$SYS->Set('_TITLE', 'System Plugin Setting');
	$common = "onclick=\"DoSubmit('sys.setting','FUNC'";
	
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($SYS);
	$num = $Plugin->GetKeySet('ALL', '', \@pluginSet);
	
	# �g���@�\�����݂���ꍇ�͗L���E�����ݒ��ʂ�\��
	if ($num > 0) {
		my ($id, $file, $class, $name, $expl, $valid);
		
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td colspan=4>�L���ɂ���@�\\�Ƀ`�F�b�N�����Ă��������B</td></tr>\n");
		$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
		$Page->Print("<tr>");
		$Page->Print("<td class=\"DetailTitle\">Function Name</td>");
		$Page->Print("<td class=\"DetailTitle\">Explanation</td>");
		$Page->Print("<td class=\"DetailTitle\">File</td>");
		$Page->Print("<td class=\"DetailTitle\">Class Name</td></tr>\n");
		
		foreach $id (@pluginSet) {
			$file = $Plugin->Get('FILE', $id);
			$class = $Plugin->Get('CLASS', $id);
			$name = $Plugin->Get('NAME', $id);
			$expl = $Plugin->Get('EXPL', $id);
			$valid = $Plugin->Get('VALID', $id) == 1 ? 'checked' : '';
			$Page->Print("<tr><td><input type=checkbox name=PLUGIN_VALID value=$id $valid>");
			$Page->Print(" $name</td><td>$expl</td><td>$file</td><td>$class</td></tr>\n");
		}
		$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
		$Page->Print("<tr><td colspan=4 align=right>");
		$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'SET_PLUGIN');\"> ");
	}
	else {
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td><b>�v���O�C���͑��݂��܂���B</b></td></tr>\n");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td align=right>");
	}
	$Page->Print("<input type=button value=\"�@�X�V�@\" $common,'UPDATE_PLUGIN');\">");
	$Page->Print("</td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	��{�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBasicSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
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
		my @inList = ('SERVER', 'CGIPATH', 'BBSPATH', 'INFO', 'DATA');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('SERVER', $Form->Get('SERVER'));
	$SYSTEM->Set('CGIPATH', $Form->Get('CGIPATH'));
	$SYSTEM->Set('BBSPATH', $Form->Get('BBSPATH'));
	$SYSTEM->Set('INFO', $Form->Get('INFO'));
	$SYSTEM->Set('DATA', $Form->Get('DATA'));
	
	$SYSTEM->Save();
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�� ��{�ݒ�';
		push @$pLog, '�@�@�@ �T�[�o�F' . $Form->Get('SERVER');
		push @$pLog, '�@�@�@ CGI�p�X�F' . $Form->Get('CGIPATH');
		push @$pLog, '�@�@�@ �f���p�X�F' . $Form->Get('BBSPATH');
		push @$pLog, '�@�@�@ �Ǘ��f�[�^�t�H���_�F' . $Form->Get('INFO');
		push @$pLog, '�@�@�@ ��{�f�[�^�t�H���_�F' . $Form->Get('DATA');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�[�~�b�V�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPermissionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('PM-DAT', oct($Form->Get('PERM_DAT')));
	$SYSTEM->Set('PM-TXT', oct($Form->Get('PERM_TXT')));
	$SYSTEM->Set('PM-LOG', oct($Form->Get('PERM_LOG')));
	$SYSTEM->Set('PM-ADM', oct($Form->Get('PERM_ADMIN')));
	$SYSTEM->Set('PM-STOP', oct($Form->Get('PERM_STOP')));
	$SYSTEM->Set('PM-ADIR', oct($Form->Get('PERM_ADMIN_DIR')));
	$SYSTEM->Set('PM-BDIR', oct($Form->Get('PERM_BBS_DIR')));
	$SYSTEM->Set('PM-LDIR', oct($Form->Get('PERM_LOG_DIR')));
	
	$SYSTEM->Save();
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�� ��{�ݒ�';
		push @$pLog, '�@�@�@ dat�p�[�~�b�V�����F' . $Form->Get('PERM_DAT');
		push @$pLog, '�@�@�@ txt�p�[�~�b�V�����F' . $Form->Get('PERM_TXT');
		push @$pLog, '�@�@�@ log�p�[�~�b�V�����F' . $Form->Get('PERM_LOG');
		push @$pLog, '�@�@�@ �Ǘ��t�@�C���p�[�~�b�V�����F' . $Form->Get('PERM_ADMIN');
		push @$pLog, '�@�@�@ ��~�X���b�h�p�[�~�b�V�����F' . $Form->Get('PERM_STOP');
		push @$pLog, '�@�@�@ �Ǘ�DIR�p�[�~�b�V�����F' . $Form->Get('PERM_ADMIN_DIR');
		push @$pLog, '�@�@�@ �f����DIR�p�[�~�b�V�����F' . $Form->Get('PERM_BBS_DIR');
		push @$pLog, '�@�@�@ ���ODIR�p�[�~�b�V�����F' . $Form->Get('PERM_LOG_DIR');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����l�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitterSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('RESMAX', $Form->Get('RESMAX'));
	$SYSTEM->Set('SUBMAX', $Form->Get('SUBMAX'));
	$SYSTEM->Set('ANKERS', $Form->Get('ANKERS'));
	$SYSTEM->Set('ERRMAX', $Form->Get('ERRMAX'));
	$SYSTEM->Set('HISMAX', $Form->Get('HISMAX'));
	$SYSTEM->Set('ADMMAX', $Form->Get('ADMMAX'));
	
	$SYSTEM->Save();
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�� ��{�ݒ�';
		push @$pLog, '�@�@�@ subject�ő吔�F' . $Form->Get('SUBMAX');
		push @$pLog, '�@�@�@ ���X�ő吔�F' . $Form->Get('RESMAX');
		push @$pLog, '�@�@�@ �A���J�[�ő吔�F' . $Form->Get('ANKERS');
		push @$pLog, '�@�@�@ �G���[���O�ő吔�F' . $Form->Get('ERRMAX');
		push @$pLog, '�@�@�@ �������ݗ����ő吔�F' . $Form->Get('HISMAX');
		push @$pLog, '�@�@�@ �Ǘ����샍�O�ő吔�F' . $Form->Get('ADMMAX');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���̑��ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('HEADTEXT', $Form->Get('HEADTEXT'));
	$SYSTEM->Set('HEADURL', $Form->Get('HEADURL'));
	$SYSTEM->Set('URLLINK', ($Form->Equal('URLLINK', 'on') ? 'TRUE' : 'FALSE'));
	$SYSTEM->Set('LINKST', $Form->Get('LINKST'));
	$SYSTEM->Set('LINKED', $Form->Get('LINKED'));
	$SYSTEM->Set('PATHKIND', $Form->Get('PATHKIND'));
	$SYSTEM->Set('FASTMODE', ($Form->Equal('FASTMODE', 'on') ? 1 : 0));
	$SYSTEM->Set('BBSGET', ($Form->Equal('BBSGET', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�� ���̑��ݒ�';
		push @$pLog, '�@�@�@ �w�b�_�e�L�X�g�F' . $SYSTEM->Get('HEADTEXT');
		push @$pLog, '�@�@�@ �w�b�_URL�F' . $SYSTEM->Get('HEADURL');
		push @$pLog, '�@�@�@ URL���������N�F' . $SYSTEM->Get('URLLINK');
		push @$pLog, '�@�@�@ �@�J�n���ԁF' . $SYSTEM->Get('LINKST');
		push @$pLog, '�@�@�@ �@�I�����ԁF' . $SYSTEM->Get('LINKED');
		push @$pLog, '�@�@�@ PATH��ʁF' . $SYSTEM->Get('PATHKIND');
		push @$pLog, '�@�@�@ �������[�h�F' . $SYSTEM->Get('FASTMODE');
		push @$pLog, '�@�@�@ bbs.cgi��GET���\\�b�h�F' . $SYSTEM->Get('BBSGET');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\���ݒ�(���낿���˂�v���X�I���W�i��)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#	2010.09.08 windyakin ��
#	 -> �\���ݒ�ƋK���ݒ�̕���
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusViewSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('COUNTER', $Form->Get('COUNTER'));
	$SYSTEM->Set('PRTEXT', $Form->Get('PRTEXT'));
	$SYSTEM->Set('PRLINK', $Form->Get('PRLINK'));
	$SYSTEM->Set('BANNER', ($Form->Equal('BANNER', 'on') ? 1 : 0));
	$SYSTEM->Set('MSEC', ($Form->Equal('MSEC', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�@�@�@ �J�E���^�[�A�J�E���g�F' . $SYSTEM->Get('COUNTER');
		push @$pLog, '�@�@�@ PR���\\��������F' . $SYSTEM->Get('PRTEXT');
		push @$pLog, '�@�@�@ PR�������NURL�F' . $SYSTEM->Get('PRLINK');
		push @$pLog, '�@�@�@ �o�i�[�\\���F' . $SYSTEM->Get('BANNER');
		push @$pLog, '�@�@�@ �~���b�\���F' . $SYSTEM->Get('MSEC');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���ݒ�(���낿���˂�v���X�I���W�i��)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#	2010.09.08 windyakin ��
#	 -> �\���ݒ�ƋK���ݒ�̕���
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusSecSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('KAKIKO', ($Form->Equal('KAKIKO', 'on') ? 1 : 0));
	$SYSTEM->Set('SAMBATM', $Form->Get('SAMBATM'));
#	$SYSTEM->Set('ISSAMBA', ($Form->Equal('ISSAMBA', 'on') ? 1 : 0));
#	$SYSTEM->Set('HOUSHI', $Form->Get('HOUSHI'));
	$SYSTEM->Set('TRIP12', ($Form->Equal('TRIP12', 'on') ? 1 : 0));
	$SYSTEM->Set('BBQ', ($Form->Equal('BBQ', 'on') ? 1 : 0));
	$SYSTEM->Set('BBX', ($Form->Equal('BBX', 'on') ? 1 : 0));
	$SYSTEM->Set('SPAMCH', ($Form->Equal('SPAMCH', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	{
		push @$pLog, '�@�@�@ 2�d�J�L�R�K���F' . $SYSTEM->Get('KAKIKO');
		push @$pLog, '�@�@�@ �A�����e�K���b���F' . $SYSTEM->Get('SAMBATM');
#		push @$pLog, '�@�@�@ Samba�K���F' . $SYSTEM->Get('ISSAMBA');
#		push @$pLog, '�@�@�@ Samba�K�������F' . $SYSTEM->Get('HOUSHI');
		push @$pLog, '�@�@�@ 12���g���b�v�F' . $SYSTEM->Get('TRIP12');
		push @$pLog, '�@�@�@ BBQ�F' . $SYSTEM->Get('BBQ');
		push @$pLog, '�@�@�@ BBX�F' . $SYSTEM->Get('BBX');
		push @$pLog, '�@�@�@ �X�p�������Ղ�[�F' . $SYSTEM->Get('SPAMCH');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my (@pluginSet, @validSet, $id, $valid);
	
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	@validSet = $Form->GetAtArray('PLUGIN_VALID');
	
	foreach $id (@pluginSet) {
		$valid = 0;
		foreach (@validSet) {
			if ($_ eq $id) {
				$valid = 1;
				last;
			}
		}
		push @$pLog, $Plugin->Get('NAME', $id) . ' ��' . ($valid ? '�L��' : '����') . '�ɐݒ肵�܂����B';
		$Plugin->Set($id, 'VALID', $valid);
	}
	$Plugin->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	
	# ���̍X�V�ƕۑ�
	$Plugin->Load($Sys);
	$Plugin->Update();
	$Plugin->Save($Sys);
	
	# ���O�̐ݒ�
	{
		push @$pLog, '�� �v���O�C�����̍X�V';
		push @$pLog, '�@�v���O�C�����̍X�V���������܂����B';
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

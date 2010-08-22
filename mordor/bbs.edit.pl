#============================================================================================================
#
#	�f���Ǘ� - �e��ҏW ���W���[��
#	bbs.edit.pl
#	---------------------------------------------------------------------------
#	2004.06.23 start
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
	
	if ($subMode eq 'HEAD') {														# �w�b�_�ҏW���
		PrintHeaderEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'FOOT') {													# �t�b�^�ҏW���
		PrintFooterEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'META') {													# META�ҏW���
		PrintMETAEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'USER') {													# �K�����[�U�ҏW���
		PrintValidUserEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'NGWORD') {													# NG���[�h�ҏW���
		PrintNGWordsEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'LAST') {													# 1001�ҏW���
		PrintLastEdit($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# �ݒ芮�����
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('�e��ҏW����', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# �ݒ莸�s���
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
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($Sys->Get('BBS'));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if ($subMode eq 'HEAD') {														# �w�b�_�ҏW
		$err = FunctionTextEdit($Sys, $Form, 1, $this->{'LOG'});
	}
	elsif ($subMode eq 'FOOT') {													# �t�b�^�ҏW
		$err = FunctionTextEdit($Sys, $Form, 2, $this->{'LOG'});
	}
	elsif ($subMode eq 'META') {													# META�ҏW
		$err = FunctionTextEdit($Sys, $Form, 3, $this->{'LOG'});
	}
	elsif ($subMode eq 'USER') {													# �K�����[�U�ҏW
		$err = FunctionValidUserEdit($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'NGWORD') {													# NG���[�h�ҏW
		$err = FunctionNGWordEdit($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'LAST') {													# 1001�ҏW
		$err = FunctionLastEdit($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS_EDIT($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'), "BBS_EDIT($subMode)", 'COMPLETE');
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
	my ($bAuth) = 0;
	
	$Base->SetMenu('�w�b�_�̕ҏW', "'bbs.edit','DISP','HEAD'");
	$Base->SetMenu('�t�b�^�̕ҏW', "'bbs.edit','DISP','FOOT'");
	$Base->SetMenu('META���̕ҏW', "'bbs.edit','DISP','META'");
	$Base->SetMenu('<hr>', '');
	
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 11, $bbs)) {
		$Base->SetMenu("�K�����[�U�̕ҏW","'bbs.edit','DISP','USER'");
		$bAuth = 1;
	}
	# �Ǘ��O���[�v�ݒ茠���̂�
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 10, $bbs)) {
		$Base->SetMenu("NG���[�h�̕ҏW","'bbs.edit','DISP','NGWORD'");
		$bAuth = 1;
	}
	if ($bAuth) {
		$Base->SetMenu('<hr>', '');
	}
	$Base->SetMenu('1001�̕ҏW', "'bbs.edit','DISP','LAST'");
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('�V�X�e���Ǘ��֖߂�', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	�w�b�_�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHeaderEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($Head, $Setting, $pHead, $common, $isAuth);
	
	$SYS->Set('_TITLE', 'BBS Header Edit');
	
	require './module/isildur.pl';
	require './module/legolas.pl';
	$Head = LEGOLAS->new;
	$Setting = ISILDUR->new;
	$Head->Load($SYS, 'HEAD');
	$Setting->Load($SYS);
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 14, $SYS->Get('BBS'));
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>");
	$Page->Print("<tr><td colspan=2 align=center>");
	
	# �w�b�_�v���r���[�\��
	if (! $Form->Equal('HEAD_TEXT', '')) {
		$Head->Set(\($Form->Get('HEAD_TEXT')));
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $PreviewPage = THORIN->new;
	$Head->Print($PreviewPage, $Setting);
	$PreviewPage->{'BUFF'} = CreatePreviewData($PreviewPage->{'BUFF'});
	$Page->Merge($PreviewPage);
	
	$Page->Print("</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���e�ҏW</td><td>");
	$Page->Print("<textarea name=HEAD_TEXT rows=11 cols=80 wrap=off>");
	
	# �w�b�_���e�e�L�X�g�̕\��
	if ($Form->Equal('HEAD_TEXT', '')) {
		$pHead = $Head->Get();
		foreach (@$pHead) {
			$Page->Print($_);
		}
	}
	else {
		$Page->Print($Form->Get('HEAD_TEXT'));
	}
	
	$Page->Print("</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','HEAD')\"> ");
		$Page->Print("<input type=button value=\"�@�ύX�@\" $common,'FUNC','HEAD')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFooterEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($Foot, $common, $isAuth);
	
	$SYS->Set('_TITLE', 'BBS Footer Edit');
	
	require './module/legolas.pl';
	$Foot = LEGOLAS->new;
	$Foot->Load($SYS, 'FOOT');
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 14, $SYS->Get('BBS'));
	
	$Page->Print("<table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>");
	$Page->Print("<tr><td colspan=2 style=\"background-image:url(./datas/default_bac.gif)\">");
	
	# �t�b�^�v���r���[�\��
	if (! $Form->Equal('FOOT_TEXT', '')) {
		$Foot->Set(\($Form->Get('FOOT_TEXT')));
	}
	# �v���r���[�f�[�^�̍쐬
	my $PreviewPage = THORIN->new;
	$Foot->Print($PreviewPage, undef);
	$PreviewPage->{'BUFF'} = CreatePreviewData($PreviewPage->{'BUFF'});
	$Page->Merge($PreviewPage);
	
	$Page->Print("</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���e�ҏW</td><td>");
	$Page->Print("<textarea name=FOOT_TEXT rows=11 cols=80 wrap=off>");
	
	# �t�b�^���e�e�L�X�g�̕\��
	if ($Form->Equal('FOOT_TEXT', '')) {
		$Foot->Print($Page, undef);
	}
	else {
		$Page->Print($Form->Get('FOOT_TEXT'));
	}
	
	$Page->Print("</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','FOOT')\"> ");
		$Page->Print("<input type=button value=\"�@�ύX�@\" $common,'FUNC','FOOT')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	META���ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintMETAEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($Meta, $common, $isAuth);
	
	$SYS->Set('_TITLE', 'BBS META Edit');
	
	require './module/legolas.pl';
	$Meta = LEGOLAS->new;
	$Meta->Load($SYS, 'META');
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 14, $SYS->Get('BBS'));
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���e�ҏW</td><td>");
	$Page->Print("<textarea name=META_TEXT rows=11 cols=80 wrap=off>");
	
	# �t�b�^���e�e�L�X�g�̕\��
	$Meta->Print($Page, undef);
	
	$Page->Print("</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�ύX�@\" $common,'FUNC','META')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�A�N�Z�X�K�����[�U�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintValidUserEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($vUsers, $pUsers, $common, $isAuth, @kind);
	
	$SYS->Set('_TITLE', 'BBS Valid User Edit');
	
	require './module/faramir.pl';
	$vUsers = FARAMIR->new;
	$vUsers->Load($SYS);
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 11, $SYS->Get('BBS'));
	$pUsers = $vUsers->Get('USER');
	
	$kind[0] = $vUsers->Get('TYPE') eq 'disable' ? '' : 'selected';
	$kind[1] = $vUsers->Get('TYPE') eq 'enable' ? '' : 'selected';
	$kind[2] = $vUsers->Get('METHOD') eq 'disable' ? '' : 'selected';
	$kind[3] = $vUsers->Get('METHOD') eq 'host' ? '' : 'selected';
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�Ώۃz�X�g�ꗗ</td><td>");
	$Page->Print("<textarea name=VALID_USERS rows=10 cols=70 wrap=off>");
	
	foreach (@$pUsers) {
		$Page->Print("$_\n");
	}
	
	$Page->Print("</textarea></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">���[�U���</td><td>");
	$Page->Print("<select name=VALID_TYPE>");
	$Page->Print("<option value=enable $kind[0]>���胆�[�U</option>");
	$Page->Print("<option value=disable $kind[1]>�K�����[�U</option>");
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�K�����@</td><td>");
	$Page->Print("<select name=VALID_METHOD>");
	$Page->Print("<option value=host $kind[2]>�z�X�g�\\��</option>");
	$Page->Print("<option value=disable $kind[3]>�������ݕs��</option>");
	$Page->Print("</select></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'FUNC','USER')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	NG���[�h�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNGWordsEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($Words, $pWords, $common, $isAuth, @kind);
	
	$SYS->Set('_TITLE', 'BBS NG Words Edit');
	
	require './module/wormtongue.pl';
	$Words = WORMTONGUE->new;
	$Words->Load($SYS);
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 10, $SYS->Get('BBS'));
	$pWords = $Words->Get('NGWORD');
	
	$kind[0] = $Words->Get('METHOD') eq 'disable' ? 'selected' : '';
	$kind[1] = $Words->Get('METHOD') eq 'host' ? 'selected' : '';
	$kind[2] = $Words->Get('METHOD') eq 'delete' ? 'selected' : '';
	$kind[3] = $Words->Get('METHOD') eq 'substitute' ? 'selected' : '';
	$kind[4] = $Words->Get('SUBSTITUTE');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">NG���[�h�ꗗ</td><td>");
	$Page->Print("<textarea name=NG_WORDS rows=10 cols=70 wrap=off>");
	
	foreach (@$pWords) {
		$Page->Print("$_\n");
	}
	
	$Page->Print("</textarea></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">NG���[�h����</td><td>");
	$Page->Print("<select name=NG_METHOD>");
	$Page->Print("<option value=disable $kind[0]>�������ݕs��</option>");
	$Page->Print("<option value=host $kind[1]>�z�X�g�\\��</option>");
	$Page->Print("<option value=delete $kind[2]>NG���[�h�폜</option>");
	$Page->Print("<option value=substitute $kind[3]>NG���[�h�u��</option>");
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">NG���[�h�u��������</td><td>");
	$Page->Print("<input type=text name=NG_SUBSTITUTE value=\"$kind[4]\" size=60></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'FUNC','NGWORD')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	1001�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLastEdit
{
	my ($Page, $SYS, $Form) = @_;
	my ($common, $isAuth, $data, $isLast, @elem, $path);
	
	$SYS->Set('_TITLE', 'BBS 1001 Edit');
	$Form->DecodeForm(1);
	
	$data = '�P�O�O�P<><>Over 1000 Thread<>���̃X���b�h�͂P�O�O�O�𒴂��܂����B<br>';
	$data .= '���������Ȃ��̂ŁA�V�����X���b�h�𗧂ĂĂ��������ł��B�B�B<>';
	if (!$Form->IsExist('LAST_FROM')) {
		# 1000.txt�̓ǂݍ���
		$path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/1000.txt';
		$isLast = 0;
		
		if (-e $path) {
			open LAST, $path;
			while(<LAST>) {
				$data = $_;
				last;
			}
			close LAST;
			chomp $data;
			$isLast = 1;
		}
	}
	else {
		my $formLast = join('<>',
			$Form->Get('LAST_FROM'),
			$Form->Get('LAST_mail'),
			$Form->Get('LAST_date'),
			$Form->Get('LAST_MESSAGE'),
			''
		);
		if ($formLast ne '<><><><>'){
			$data = $formLast;
			$isLast = 1;
		}
	}
	@elem = split(/<>/, $data);
	for (0 .. 4) {
		$elem[$_] = '' if (! defined $elem[$_]);
	}
	
	# �����擾
	$isAuth = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 14, $SYS->Get('BBS'));
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>");
	$Page->Print("<tr><td colspan=2><center><dl><table border cellspacing=7 bgcolor=#efefef width=100%>");
	$Page->Print("<tr><td>");
	
	# �v���r���[�\��
	$Page->Print("<dt>1001 ���O�F<b><font color=green>$elem[0]</font></b>")			if ($elem[1] eq '');
	$Page->Print("<dt>1001 ���O�F<b><a href=\"mailto:$elem[1]\">$elem[0]</a></b>")	if ($elem[1] ne '');
	$Page->Print("�F$elem[2]</dt><dd>$elem[3]<br><br></dd>");
	@elem = ('', '', '', '', '') if (! $isLast);
	
	$Page->Print("</td></tr></table></dl></td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>���e�ҏW</td></tr>");
	$Page->Print("<tr><td class=\"DetailTitle\">���O</td><td>");
	$Page->Print("<input type=text size=60 name=LAST_FROM value=\"$elem[0]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���[��</td><td>");
	$Page->Print("<input type=text size=60 name=LAST_mail value=\"$elem[1]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���t�EID</td><td>");
	$Page->Print("<input type=text size=60 name=LAST_date value=\"$elem[2]\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�{��</td><td>");
	$Page->Print("<textarea name=LAST_MESSAGE rows=10 cols=70 wrap=off>");
	
	$elem[3] =~ s/<br>/\n/g;
	
	$Page->Print("$elem[3]</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �����ɂ���ĕ\����}��
	if ($isAuth) {
		$common = "onclick=\"DoSubmit('bbs.edit'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','LAST')\"> ");
		$Page->Print("<input type=button value=\"�@�ύX�@\" $common,'FUNC','LAST')\">");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�e�L�X�g�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$mode	�ݒ胂�[�h(1:HEAD 2:FOOT 3:META)
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionTextEdit
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	my ($Texts, $readKey, $formKey, $value);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 14, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	
	# �ǂݎ��p�̃L�[��ݒ肷��
	if ($mode == 1) {
		$readKey = 'HEAD';
		$formKey = 'HEAD_TEXT';
		push @$pLog, 'head.txt��ݒ肵�܂����B';
	}
	elsif ($mode == 2) {
		$readKey = 'FOOT';
		$formKey = 'FOOT_TEXT';
		push @$pLog, 'foot.txt��ݒ肵�܂����B';
	}
	elsif ($mode == 3) {
		$readKey = 'META';
		$formKey = 'META_TEXT';
		push @$pLog, 'meta.txt��ݒ肵�܂����B';
	}
	
	require './module/legolas.pl';
	$Texts = LEGOLAS->new;
	$Texts->Load($Sys, $readKey);
	
	$value = $Form->Get($formKey);
	$Texts->Set(\$value);
	
	# �ݒ�̕ۑ�
	$Texts->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�K�����[�U�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionValidUserEdit
{
	my ($Sys, $Form, $pLog) = @_;
	my ($vUsers, @validUsers);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 11, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/faramir.pl';
	$vUsers = FARAMIR->new;
	$vUsers->Load($Sys);
	
	@validUsers = split(/\n/, $Form->Get('VALID_USERS'));
	$vUsers->Set('TYPE', $Form->Get('VALID_TYPE'));
	$vUsers->Set('METHOD', $Form->Get('VALID_METHOD'));
	
	$vUsers->Clear();
	push @$pLog, '���ȉ��̃��[�U���w��';
	foreach (@validUsers) {
		$vUsers->Add($_);
		push @$pLog, '�@�@' . $_;
	}
	push @$pLog, '���w�胆�[�U��ʁF' . $Form->Get('VALID_TYPE');
	push @$pLog, '���w�胆�[�U���u�F' . $Form->Get('VALID_METHOD');
	
	$vUsers->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	NG���[�h�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNGWordEdit
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Words, @ngWords);
	
	# �����`�F�b�N
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 10, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/wormtongue.pl';
	$Words = WORMTONGUE->new;
	$Words->Load($Sys);
	
	@ngWords = split(/\n/, $Form->Get('NG_WORDS'));
	$Words->Set('METHOD', $Form->Get('NG_METHOD'));
	$Words->Set('SUBSTITUTE', $Form->Get('NG_SUBSTITUTE'));
	
	$Words->Clear();
	push @$pLog, '��NG���[�h�Ƃ��Ĉȉ���ݒ�';
	foreach (@ngWords) {
		$Words->Add($_);
		push @$pLog, '�@�@' . $_;
	}
	push @$pLog, '��NG���[�h���u�F' . $Form->Get('NG_METHOD');
	
	$Words->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	1001�ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLastEdit
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Texts, $readKey, $formKey, $value, $lastPath, $name, $mail, $date, $cont, $forCheck);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 14, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	$Form->DecodeForm(1);
	
	# 1000.txt�̃p�X
	$lastPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/1000.txt';
	
	# �t�H�[�����̎擾
	$name = $Form->Get('LAST_FROM');
	$mail = $Form->Get('LAST_mail');
	$date = $Form->Get('LAST_date');
	$cont = $Form->Get('LAST_MESSAGE');
	$forCheck = $name . $mail . $date . $cont;
	
	# �S�ċ󗓂̏ꍇ��1000.txt���폜���f�t�H���g1001���g�p
	if ($forCheck eq ''){
		unlink $lastPath;
		push @$pLog, '��1000.txt��j�����ăf�t�H���g��1001���g�p���܂��B';
	}
	# �l���ݒ肳�ꂽ�ꍇ��1000.txt���쐬����
	else {
#		eval
		{
			open LAST, ">$lastPath";
			flock LAST, 2;
			binmode LAST;
			print LAST "$name<>$mail<>$date<>$cont<>\n";
			close LAST;
		};
		if ($@ ne ''){
			push @$pLog, $@;
			return 9999;
		}
		push @$pLog, '��1000.txt��ݒ肵�܂����B';
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���r���[�f�[�^�̍쐬
#	-------------------------------------------------------------------------------------
#	@param	$pData	�쐬���z��̎Q��
#	@return	�v���r���[�f�[�^�̔z��
#
#------------------------------------------------------------------------------------------------------------
sub CreatePreviewData
{
	my ($pData) = @_;
	my @temp;
	
	foreach (@$pData) {
		$_ =~ s/<[fF][oO][rR][mM].*?>/<!--form--><br>/g;
		$_ =~ s/<\/[fF][oO][rR][mM]>/<!--\/form--><br>/g;
		$_ =~ s/[nN][aA][mM][eE].*?=/_name_=/g;
		push @temp, $_;
	}
	return \@temp;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

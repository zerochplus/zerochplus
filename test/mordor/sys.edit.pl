#============================================================================================================
#
#	�V�X�e���Ǘ� - �ҏW ���W���[��
#	sys.edit.pl
#	---------------------------------------------------------------------------
#	2004.09.15 start
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
	my		($subMode,$BASE,$Page);
	
	require('./mordor/sauron.pl');
	$BASE = new SAURON;
	
	# �Ǘ�����o�^
	$Sys->Set('ADMIN',$pSys);
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys,$Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE,$pSys);
	
	if		($subMode eq 'BANNER_PC'){												# PC�p���m�ҏW���
		PrintBannerForPCEdit($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'BANNER_MOBILE'){											# �g�їp���m�ҏW���
		PrintBannerForMobileEdit($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'BANNER_SUB'){												# �T�u���m�ҏW���
		PrintBannerForSubEdit($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'COMPLETE'){												# �V�X�e���ݒ芮�����
		$Sys->Set('_TITLE','Process Complete');
		$BASE->PrintComplete('�V�X�e���ҏW����',$this->{'LOG'});
	}
	elsif	($subMode eq 'FALSE'){													# �V�X�e���ݒ莸�s���
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
	
	# �Ǘ�����o�^
	$Sys->Set('ADMIN',$pSys);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if		($subMode eq 'BANNER_PC'){													# PC�p���m
		$err = FunctionBannerEdit($Sys,$Form,1,$this->{'LOG'});
	}
	elsif	($subMode eq 'BANNER_MOBILE'){												# �g�їp���m
		$err = FunctionBannerEdit($Sys,$Form,2,$this->{'LOG'});
	}
	elsif	($subMode eq 'BANNER_SUB'){													# �T�u�o�i�[
		$err = FunctionBannerEdit($Sys,$Form,3,$this->{'LOG'});
	}
	
	# �������ʕ\��
	if	($err){
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_EDIT($subMode)",'ERROR:'.$err);
		push(@{$this->{'LOG'}},$err);
		$Form->Set('MODE_SUB','FALSE');
	}
	else{
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_EDIT($subMode)",'COMPLETE');
		$Form->Set('MODE_SUB','COMPLETE');
	}
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
	my		($Base,$pSys) = @_;
	
	$Base->SetMenu("���m�ҏW(PC�p)","'sys.edit','DISP','BANNER_PC'");
	$Base->SetMenu("���m�ҏW(�g�їp)","'sys.edit','DISP','BANNER_MOBILE'");
	$Base->SetMenu("���m�ҏW(�T�u)","'sys.edit','DISP','BANNER_SUB'");
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(PC)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBannerForPCEdit
{
	my		($Page,$SYS,$Form) = @_;
	my		($Banner,$bgColor,$content,$common);
	
	$SYS->Set('_TITLE','PC Banner Edit');
	
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($SYS);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=center>");
	
	# ���m���v���r���[�\��
	if	($Form->IsExist('PC_CONTENT')){
		$Banner->Set('COLPC',$Form->Get('PC_BGCOLOR'));
		$Banner->Set('TEXTPC',$Form->Get('PC_CONTENT'));
		$bgColor = $Form->Get('PC_BGCOLOR');
		$content = $Form->Get('PC_CONTENT');
	}
	else{
		$bgColor = $Banner->Get('COLPC');
		$content = $Banner->Get('TEXTPC');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $BannerPage = new THORIN;
	$Banner->Print($BannerPage,100,0,0);
	$BannerPage->{'BUFF'} = CreatePreviewData($BannerPage->{'BUFF'});
	$Page->Merge($BannerPage);
	
	$common = "onclick=\"DoSubmit('sys.edit'";
	
	$Page->Print("</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�w�i�F</td><td>");
	$Page->Print("<input type=text size=20 name=PC_BGCOLOR value=\"$bgColor\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���e</td><td>");
	$Page->Print("<textarea rows=10 cols=70 name=PC_CONTENT wrap=off>$content</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','BANNER_PC');\"> ");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'FUNC','BANNER_PC');\">");
	$Page->Print("</td></tr>\n</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(�g��)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBannerForMobileEdit
{
	my		($Page,$SYS,$Form) = @_;
	my		($Banner,$bgColor,$content);
	
	$SYS->Set('_TITLE','Mobile Banner Edit');
	
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($SYS);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=center>");
	
	# ���m���v���r���[�\��
	if	($Form->IsExist('MOBILE_CONTENT')){
		$Banner->Set('COLMB',$Form->Get('MOBILE_BGCOLOR'));
		$Banner->Set('TEXTMB',$Form->Get('MOBILE_CONTENT'));
		$bgColor = $Form->Get('MOBILE_BGCOLOR');
		$content = $Form->Get('MOBILE_CONTENT');
	}
	else{
		$bgColor = $Banner->Get('COLMB');
		$content = $Banner->Get('TEXTMB');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $BannerPage = new THORIN;
	$Banner->Print($BannerPage,100,0,1);
	$BannerPage->{'BUFF'} = CreatePreviewData($BannerPage->{'BUFF'});
	$Page->Merge($BannerPage);
	
	$common = "onclick=\"DoSubmit('sys.edit'";
	
	$Page->Print("</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">�w�i�F</td><td>");
	$Page->Print("<input type=text size=20 name=MOBILE_BGCOLOR value=\"$bgColor\"></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���e</td><td>");
	$Page->Print("<textarea rows=10 cols=70 name=MOBILE_CONTENT wrap=off>$content</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','BANNER_MOBILE');\"> ");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'FUNC','BANNER_MOBILE');\">");
	$Page->Print("</td></tr>\n</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���m��(�T�u)�ҏW��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBannerForSubEdit
{
	my		($Page,$SYS,$Form) = @_;
	my		($Banner,$content);
	
	$SYS->Set('_TITLE','Sub Banner Edit');
	
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($SYS);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td class=\"DetailTitle\" colspan=2>Preview</td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=center>");
	
	# ���m���v���r���[�\��
	if	($Form->IsExist('SUB_CONTENT')){
		$Banner->Set('TEXTSB',$Form->Get('SUB_CONTENT'));
		$content = $Form->Get('SUB_CONTENT');
	}
	else{
		$content = $Banner->Get('TEXTSB');
	}
	
	# �v���r���[�f�[�^�̍쐬
	my $BannerPage = new THORIN;
	$Banner->PrintSub($BannerPage);
	$BannerPage->{'BUFF'} = CreatePreviewData($BannerPage->{'BUFF'});
	$Page->Merge($BannerPage);
	
	$common = "onclick=\"DoSubmit('sys.edit'";
	
	$Page->Print("</td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">���e</td><td>");
	$Page->Print("<textarea rows=10 cols=70 name=SUB_CONTENT wrap=off>$content</textarea></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"�@�m�F�@\" $common,'DISP','BANNER_SUB');\"> ");
	$Page->Print("<input type=button value=\"�@�ݒ�@\" $common,'FUNC','BANNER_SUB');\">");
	$Page->Print("</td></tr>\n</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���m���ҏW
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBannerEdit
{
	my		($Sys,$Form,$mode,$pLog) = @_;
	my		($Banner);
	
	# �����`�F�b�N
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	(($SEC->IsAuthority($chkID,0,'*')) == 0){
			return 1000;
		}
	}
	# ���̓`�F�b�N
	if	($mode != 3){
		my	@inList;
		
		@inList = ('PC_CONTENT','PC_BGCOLOR')			if	($mode == 1);
		@inList = ('MOBILE_CONTENT','MOBILE_BGCOLOR')	if	($mode == 2);
		
		if	(!$Form->IsInput(@inList)){
			return 1001;
		}
	}
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($Sys);
	
	if	($mode == 1){
		$Banner->Set('TEXTPC',$Form->Get('PC_CONTENT'));
		$Banner->Set('COLPC',$Form->Get('PC_BGCOLOR'));
		push(@$pLog,"PC�p���m����ݒ肵�܂����B");
	}
	elsif	($mode == 2){
		$Banner->Set('TEXTMB',$Form->Get('MOBILE_CONTENT'));
		$Banner->Set('COLMB',$Form->Get('MOBILE_BGCOLOR'));
		push(@$pLog,"�g�їp���m����ݒ肵�܂����B");
	}
	elsif	($mode == 3){
		$Banner->Set('TEXTSB',$Form->Get('SUB_CONTENT'));
		push(@$pLog,"�T�u�o�i�[��ݒ肵�܂����B");
	}
	
	# �ݒ�̕ۑ�
	$Banner->Save($Sys);
	
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
	my	($pData) = @_;
	my	@temp;
	
	foreach(@$pData){
		$_ =~ s/<[fF][oO][rR][mM].*?>/<!--form--><br>/g;
		$_ =~ s/<\/[fF][oO][rR][mM]>/<!--\/form--><br>/g;
		$_ =~ s/[nN][aA][mM][eE].*?=/_name_=/g;
		push(@temp,$_);
	}
	return \@temp;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

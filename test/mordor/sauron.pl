#============================================================================================================
#
#	�Ǘ�CGI�x�[�X���W���[��
#	sauron.pl
#	---------------------------------------------------------------------------
#	2003.10.12 start
#
#============================================================================================================
package	SAURON;

require('./module/thorin.pl');

#------------------------------------------------------------------------------------------------------------
#
#	���W���[���R���X�g���N�^ - new
#	-------------------------------------------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my		$this = shift;
	my		($obj,@MnuStr,@MnuUrl);
	
	$obj = {
		'SYS'		=> undef,														# MELKOR�ێ�
		'FORM'		=> undef,														# SAMWISE�ێ�
		'INN'		=> undef,														# THORIN�ێ�
		'MNUSTR'	=> \@MnuStr,													# �@�\���X�g������
		'MNUURL'	=> \@MnuUrl,													# �@�\���X�gURL
		'MNUNUM'	=> 0															# �@�\���X�g��
	};
	bless $obj,$this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�I�u�W�F�N�g���� - Create
#	-------------------------------------------------------------------------------------
#	���@���F$M : MELKOR���W���[��
#			$S : SAMWISE���W���[��
#	�߂�l�FTHORIN���W���[��
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my		$this = shift;
	my		($Sys,$Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= new THORIN;
	$this->{'MNUNUM'}	= 0;
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[�̐ݒ� - SetMenu
#	-------------------------------------------------------------------------------------
#	���@���F$str : �\��������
#			$url : �W�����vURL
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my		$this = shift;
	my		($str,$url) = @_;
	
	push(@{$this->{'MNUSTR'}},$str);
	push(@{$this->{'MNUURL'}},$url);
	
	$this->{'MNUNUM'} ++;
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�o�� - Print
#	-------------------------------------------------------------------------------------
#	���@���F$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my		$this = shift;
	my		($ttl,$mode) = @_;
	my		($Tad,$Tin,$TPlus);
	
	$Tad	= new THORIN;
	$Tin	= $this->{'INN'};
	
	PrintHTML($Tad,$ttl);															# HTML�w�b�_�o��
	PrintCSS($Tad,$this->{'SYS'});													# CSS�o��
	PrintHead($Tad,$ttl,$mode);														# �w�b�_�o��
	PrintList($Tad,$this->{'MNUNUM'},$this->{'MNUSTR'},$this->{'MNUURL'});			# �@�\���X�g�o��
	PrintInner($Tad,$Tin,$ttl);														# �@�\���e�o��
	PrintCommonInfo($Tad,$this->{'FORM'});
	PrintFoot($Tad,$this->{'FORM'}->Get('UserName'),$this->{'SYS'}->Get('VERSION'));# �t�b�^�o��
	
	$Tad->Flush(0,0,'');															# ��ʏo��
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�o��(���j���[���X�g�Ȃ�) - PrintNoList
#	-------------------------------------------------------------------------------------
#	���@���F$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoList
{
	my		$this = shift;
	my		($ttl,$mode) = @_;
	my		($Tad,$Tin);
	
	$Tad = new THORIN;
	$Tin = $this->{'INN'};
	
	PrintHTML($Tad,$ttl);															# HTML�w�b�_�o��
	PrintCSS($Tad,$this->{'SYS'});													# CSS�o��
	PrintHead($Tad,$ttl,$mode);														# �w�b�_�o��
	PrintInner($Tad,$Tin,$ttl);														# �@�\���e�o��
	PrintFoot($Tad,'NONE',$this->{'SYS'}->Get('VERSION'));	# �t�b�^�o��
	
	$Tad->Flush(0,0,'');															# ��ʏo��
}

#------------------------------------------------------------------------------------------------------------
#
#	HTML�w�b�_�o�� - PrintHTML
#	-------------------------------------------
#	���@���F$T   : THORIN���W���[��
#			$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHTML
{
	my		($Page,$ttl) = @_;
	
	$Page->Print("Content-type: text/html\n\n<html><head><title>���낿���˂�Ǘ�");
	$Page->Print(" - [ $ttl ]</title>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X�^�C���V�[�g�o�� - PrintCSS
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCSS
{
	my		($Page,$Sys) = @_;
	my		($data);
	
	$data = $Sys->Get('DATA');
	
	$Page->Print('<meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">');
	$Page->Print("<link rel=stylesheet href=\".$data/admin.css\" type=text/css>");
	$Page->Print("<script language=javascript src=\".$data/admin.js\"></script>");
	$Page->Print("</head><!--nobanner-->\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�w�b�_�o�� - PrintHead
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#			$ttl : �y�[�W�^�C�g��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my		($Page,$ttl,$mode) = @_;
	my		($common);
	
	$common = '<a href="javascript:DoSubmit';
	
	$Page->Print("<body>");
	$Page->Print("<form name=ADMIN action=\"./admin.cgi\" method=\"POST\">");
	$Page->Print("<div class=\"MainMenu\" align=right>");
	
	# �V�X�e���Ǘ����j���[
	if	($mode == 1){
		$Page->Print("$common('sys.top','DISP','NOTICE');\">�g�b�v</a> | ");
		$Page->Print("$common('sys.bbs','DISP','LIST');\">�f����</a> | ");
		$Page->Print("$common('sys.user','DISP','LIST');\">���[�U�[</a> | ");
		$Page->Print("$common('sys.cap','DISP','LIST');\">�L���b�v</a> | ");
		$Page->Print("$common('sys.setting','DISP','INFO');\">�V�X�e���ݒ�</a> | ");
		$Page->Print("$common('sys.edit','DISP','BANNER_PC');\">�e��ҏW</a> | ");
	}
	# �f���Ǘ����j���[
	elsif	($mode == 2){
		$Page->Print("$common('bbs.thread','DISP','LIST');\">�X���b�h</a> | ");
		$Page->Print("$common('bbs.pool','DISP','LIST');\">�v�[��</a> | ");
		$Page->Print("$common('bbs.kako','DISP','LIST');\">�ߋ����O</a> | ");
		$Page->Print("$common('bbs.setting','DISP','SETINFO');\">�f���ݒ�</a> | ");
		$Page->Print("$common('bbs.edit','DISP','HEAD');\">�e��ҏW</a> | ");
		$Page->Print("$common('bbs.user','DISP','LIST');\">�Ǘ��O���[�v</a> | ");
		$Page->Print("$common('bbs.cap','DISP','LIST');\">�L���b�v�O���[�v</a> | ");
		$Page->Print("$common('bbs.log','DISP','INFO');\">���O�{��</a> | ");
	}
	# �X���b�h�Ǘ����j���[
	elsif	($mode == 3){
		$Page->Print("$common('thread.res','DISP','LIST');\">���X�ꗗ</a> | ");
		$Page->Print("$common('thread.del','DISP','LIST');\">�폜���X�ꗗ</a> ");
	}
	$Page->Print("<a $common('login','','');\">���O�I�t</a>");
	$Page->Print("</div>\n<div class=\"MainHead\" align=right>0ch BBS System Manager</div>");
	$Page->Print("<table cellspacing=0 width=100%><tr style=\"height:400px\">");
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���X�g�o�� - PrintList
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#			$str : �@�\�^�C�g���z��
#			$url : �@�\URL�z��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintList
{
	my		($Page,$n,$str,$url) = @_;
	my		($i);
	
	$Page->Print("<td align=center valign=top class=\"Content\">");
	$Page->Print("<table width=95% cellspacing=0><tr><td class=\"FunctionList\">\n");
	
	for	($i = 0;$i < $n;$i++){
		$strURL = $$url[$i];
		$strTXT = $$str[$i];
		if	($strURL eq ''){
			$Page->Print("<font color=gray>$strTXT</font>\n");
			if($strTXT ne '<hr>'){
				$Page->Print('<br>');
			}
		}
		else{
			$Page->Print("<a href=\"javascript:DoSubmit($$url[$i]);\" >");
			$Page->Print("$$str[$i]</a><br>\n");
		}
	}
	$Page->Print("</td></tr></table></td>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���e�o�� - PrintInner
#	-------------------------------------------
#	���@���F$Page1 : THORIN���W���[��(MAIN)
#			$Page2 : THORIN���W���[��(���e)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintInner
{
	my		($Page1,$Page2,$ttl) = @_;
	
	$Page1->Print("<td width=80% valign=top class=\"Function\">\n");
	$Page1->Print("<div class=\"FuncTitle\">$ttl</div><br>");
	$Page1->Merge($Page2);
	$Page1->Print("</td>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	���ʏ��o�� - PrintCommonInfo
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintCommonInfo
{
	my		($Page,$Form) = @_;
	
	$Page->HTMLInput('hidden','MODULE',"");
	$Page->HTMLInput('hidden','MODE',"");
	$Page->HTMLInput('hidden','MODE_SUB',"");
	
	$Page->HTMLInput('hidden','UserName',$Form->Get('UserName'));
	$Page->HTMLInput('hidden','PassWord',$Form->Get('PassWord'));
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�o�� - PrintFoot
#	-------------------------------------------
#	���@���F$Page   : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my		($Page,$user,$ver) = @_;
	
	$Page->Print("</tr></table>");
	$Page->Print("<div class=\"MainFoot\">");
	$Page->Print("Copyright 2001 - 2005 0ch BBS : Loggin User - <b>$user</b><br>");
	$Page->Print("Build Version:<b>$ver</b>");
	$Page->Print("</div></form></body></html>");
}

#------------------------------------------------------------------------------------------------------------
#
#	������ʂ̏o��
#	-------------------------------------------------------------------------------------
#	@param	$processName	������
#	@param	$pLog	�������O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintComplete
{
	my		$this = shift;
	my		($processName,$pLog) = @_;
	my		($Page,$text);
	
	$Page = $this->{'INN'};
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td><b>$processName�𐳏�Ɋ������܂����B</b><br><br>");
	$Page->Print("<small>�������O<hr><blockquote>");
	
	# ���O�̕\��
	foreach	$text (@$pLog){
		$Page->Print("$text<br>\n");
	}
	$Page->Print("</blockquote><hr></small></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$pLog	���O�p
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintError
{
	my		$this = shift;
	my		($pLog) = @_;
	my		($Page,$ecode);
	
	$Page = $this->{'INN'};
	
	# �G���[�R�[�h�̒��o
	$ecode = pop(@$pLog);
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td><br><font color=red><b>");
	$Page->Print("ERROR:$ecode<hr><blockquote>\n");
	
	if		($ecode == 1000){
		$Page->Print("�{�@�\�̏��������s���錠��������܂���B");
	}
	elsif	($ecode == 1001){
		$Page->Print("���͕K�{���ڂ��󗓂ɂȂ��Ă��܂��B");
	}
	elsif	($ecode == 1002){
		$Page->Print("�ݒ荀�ڂɋK��O�̕������g�p����Ă��܂��B");
	}
	elsif	($ecode == 2000){
		$Page->Print("�f���f�B���N�g���̍쐬�Ɏ��s���܂����B<br>");
		$Page->Print("�p�[�~�b�V�����A�܂��͊��ɓ����̌f�����쐬����Ă��Ȃ������m�F���Ă��������B");
	}
	elsif	($ecode == 2001){
		$Page->Print("SETTING.TXT�̐����Ɏ��s���܂����B");
	}
	elsif	($ecode == 2002){
		$Page->Print("�f���\\���v�f�̐����Ɏ��s���܂����B");
	}
	elsif	($ecode == 2003){
		$Page->Print("�ߋ����O�������̐����Ɏ��s���܂����B");
	}
	elsif	($ecode == 2004){
		$Page->Print("�f�����̍X�V�Ɏ��s���܂����B");
	}
	else{
		$Page->Print("�s���ȃG���[���������܂����B");
	}
	
	# �G���[���O������Ώo�͂���
	if	(@$pLog){
		$Page->Print('<hr>');
		foreach	(@$pLog){
			$Page->Print("$_<br>\n");
		}
	}
	
	$Page->Print("</blockquote><hr></b></font>");
	$Page->Print("</td></tr></table>");
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

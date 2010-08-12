#!/usr/bin/perl
#============================================================================================================
#
#	�����pCGI(�܂������Ă��݂܂���)
#	search.cgi
#	-----------------------------------------------------
#	2003.11.22 star
#	2004.09.16 �V�X�e�����ςɔ����ύX
#
#============================================================================================================

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(SearchCGI());

#------------------------------------------------------------------------------------------------------------
#
#	CGI���C������ - SearchCGI
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SearchCGI
{
	require('./module/melkor.pl');
	require('./module/thorin.pl');
	require('./module/samwise.pl');
	require('./module/nazguls.pl');
	$Sys	= new MELKOR;
	$Page	= new THORIN;
	$Form	= new SAMWISE;
	$BBS	= new NAZGUL;
	
	$Form->DecodeForm(1);
	$Sys->Init();
	$BBS->Load($Sys);
	PrintHead($Sys,$Page,$BBS,$Form);
	
	# �������[�h������ꍇ�͌��������s����
	if	(!$Form->Equal('WORD','')){
		Search($Sys,$Form,$Page,$BBS);
	}
	PrintFoot($Page);
	$Page->Flush(0,0,'');
}

#------------------------------------------------------------------------------------------------------------
#
#	�w�b�_�o�� - PrintHead
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my		($Sys,$Page,$BBS,$Form) = @_;
	my		($pBBS,$bbs,$name,$dir,$Banner);
	my		($sMODE,$sBBS,$sKEY,$sWORD,@sTYPE,@cTYPE,$types);
	
	$sMODE	= $Form->Get('MODE');
	$sBBS	= $Form->Get('BBS');
	$sKEY	= $Form->Get('KEY');
	$sWORD	= $Form->Get('WORD');
	@sTYPE	= $Form->GetAtArray('TYPE',0);
	
	$types = $sTYPE[0] | $sTYPE[1] | $sTYPE[2];
	$cTYPE[0] = ($types & 1 ? 'checked' : '');
	$cTYPE[1] = ($types & 2 ? 'checked' : '');
	$cTYPE[2] = ($types & 4 ? 'checked' : '');
	
	# �o�i�[�̓ǂݍ���
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($Sys);
	
	$Page->Print("Content-type: text/html\n\n<html><!--nobanner--><head>");
	$Page->Print("<style type=\"text/css\">.res{background-color:yellow;font-");
	$Page->Print("weight:bold;}</style><title>������0ch</title><body ");
	$Page->Print("bgcolor=#aaaaff background=\"./datas/default_bac.gif\">");
	$Page->Print("<form action=\"./search.cgi\" method=\"POST\">");
	$Page->Print("<table border=1 cellspacing=7 cellpadding=3 width=95% ");
	$Page->Print("bgcolor=#ccffcc align=center><tr><td><font size=+1 face=");
	$Page->Print("Arial><b>������0ch�X�N���v�d</b></font><center><br><table ");
	$Page->Print("boder=0><tr><td>�������[�h</td><td><select name=MODE>\n");
	
	if	($sMODE eq 'ALL'){
		$Page->Print("<option value=ALL selected>�I���S����</option>\n");
		$Page->Print("<option value=BBS>BBS�w��S����</option>\n");
		$Page->Print("<option value=THREAD>�X���b�h�w��S����</option>\n");
	}
	elsif	($sMODE eq 'BBS' || $sMODE eq ''){
		$Page->Print("<option value=ALL>�I���S����</option>\n");
		$Page->Print("<option value=BBS selected>BBS�w��S����</option>\n");
		$Page->Print("<option value=THREAD>�X���b�h�w��S����</option>\n");
	}
	elsif	($sMODE eq 'THREAD'){
		$Page->Print("<option value=ALL>�I���S����</option>\n");
		$Page->Print("<option value=BBS>BBS�w��S����</option>\n");
		$Page->Print("<option value=THREAD selected>�X���b�h�w��S����</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>�w��BBS</td><td><select name=BBS>");
	
	# BBS�Z�b�g�̎擾
	$BBS->GetKeySet('ALL','',\@bbsSet);
	
	foreach	$id (@bbsSet){
		$name = $BBS->Get('NAME',$id);
		$dir = $BBS->Get('DIR',$id);
		if	($sBBS eq $dir){
			$Page->Print("<option value=\"$dir\" selected>$name</option>\n");
		}
		else{
			$Page->Print("<option value=\"$dir\">$name</option>\n");
		}
	}
	
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>�w��X���b�h�L�[</td><td><input type=text size=20 ");
	$Page->Print("name=KEY value=\"$sKEY\"></td></tr><tr><td>�������[�h</td>");
	$Page->Print("<td><input type=text size=40 name=WORD value=\"$sWORD\">");
	$Page->Print("</td></tr><tr><td>�������</td><td>");
	$Page->Print("<input type=checkbox name=TYPE value=1 $cTYPE[0]>���O����<br>");
	$Page->Print("<input type=checkbox name=TYPE value=4 $cTYPE[2]>ID�E���t����<br>");
	$Page->Print("<input type=checkbox name=TYPE value=2 $cTYPE[1]>�{������<br>");
	$Page->Print("</td></tr><tr><td colspan=2 align=right><hr>\n");
	$Page->Print("<input type=submit value=\"�@�����@\"></td></tr></table><br>");
	$Page->Print("</td></tr></table><br>");
	
	$Banner->Print($Page,95,0,0);
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�o�� - PrintHead
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my		($Page) = @_;
	
	$Page->Print("<br><div align=right><small><b>0ch BBS search.cgi");
	$Page->Print("</b></small></div></body></html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʏo�� - Search
#	------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my		($Sys,$Form,$Page,$BBS) = @_;;
	my		($Search,$Mode,$Result,@elem,$n,$base,$word);
	my		(@types,$Type);
	
	require('./module/balrogs.pl');
	$Search = new BALROGS;
	
	$Mode = 0	if	($Form->Equal('MODE','ALL'));
	$Mode = 1	if	($Form->Equal('MODE','BBS'));
	$Mode = 2	if	($Form->Equal('MODE','THREAD'));
	
	@types	= $Form->GetAtArray('TYPE',0);
	$Type	= $types[0] | $types[1] | $types[2];
	
	# �����I�u�W�F�N�g�̐ݒ�ƌ����̎��s
	eval{
		$Search->Create($Sys,$Mode,$Type,$Form->Get('BBS'),$Form->Get('KEY'));
		$Search->Run($Form->Get('WORD'));
	};
	if	($@ ne ''){
		PrintSystemError($Page,$@);
		return;
	}
	
	# �������ʃZ�b�g�擾
	$Result = $Search->GetResultSet();
	$n		= @$Result;
	$base	= $Sys->Get('BBSPATH');
	$word	= $Form->Get('WORD');
	
	PrintResultHead($Page,$n);
	
	# �����q�b�g��1���ȏ゠��
	if	($n > 0){
		require('./module/galadriel.pl');
		my	$Conv = new GALADRIEL;
		$n = 1;
		foreach	(@$Result){
			@elem = split(/<>/);
			PrintResult($Page,$BBS,$Conv,$n,$base,\@elem);
			$n++;
		}
	}
	# �����q�b�g����
	else{
		PrintNoHit($Page);
	}
	
	PrintResultFoot($Page);
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʃw�b�_�o�� - PrintResultHead
#	------------------------------------------------
#	���@���FPage : �o�̓��W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultHead
{
	my		($Page,$n) = @_;
	
	$Page->Print("<br><table border=1 cellspacing=7 cellpadding=3 width=95%");
	$Page->Print(" bgcolor=#efefef align=center><tr><td><dl><b><small>");
	$Page->Print("�y�q�b�g���F$n�z</b></small><font size=+2 color=red>��������");
	$Page->Print("</font><br>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʓ��e�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResult
{
	my		($Page,$BBS,$Conv,$n,$base,$pResult) = @_;
	my		($name,@bbsSet);
	
	$BBS->GetKeySet('DIR',$$pResult[0],\@bbsSet);
	
	if	(@bbsSet > 0){
		$name = $BBS->Get('NAME',$bbsSet[0]);
		
		$Page->Print("<dt>$n ���O�F<b>");
		if	($$pResult[4] eq ''){
			$Page->Print("<font color=forestgreen>$$pResult[3]</font>");
		}
		else{
			$Page->Print("<a href=\"mailto:$$pResult[4]\">$$pResult[3]</a>");
		}
		$Page->Print("</b>�F$$pResult[5]</dt><dd>$$pResult[6]<br><hr>");
		$Page->Print("<a target=_blank href=\"$base/$$pResult[0]/\">�y$name�z</a>");
		$Page->Print("<a target=_blank href=\"./read.cgi/$$pResult[0]/$$pResult[1]/\">�y�X���b�h�z</a>");
		$Page->Print("<a target=_blank href=\"./read.cgi/$$pResult[0]/$$pResult[1]/$$pResult[2]\">�y���X�z</a>");
		$Page->Print("<br><br></dd>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʃt�b�^�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultFoot
{
	my		($Page) = @_;
	
	$Page->Print("</dl></td></tr></table>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	NoHit�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoHit
{
	my		($Page) = @_;
	
	$Page->Print("<dt>0 ���O�F<font color=forestgreen><b>�����G���W�\\��");
	$Page->Print("���낿���˂�</b></font>�FNo Hit</dt><dd><br><br>");
	$Page->Print("�Q|�P|���@�ꌏ���q�b�g���܂���ł����B�B<br><br></dd>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e���G���[�o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$msg	�G���[���b�Z�[�W
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemError
{
	my		($Page,$msg) = @_;
	
	$Page->Print("<br><table border=1 cellspacing=7 cellpadding=3 width=95%");
	$Page->Print(" bgcolor=#efefef align=center><tr><td><dl><b><small>");
	$Page->Print("�y�q�b�g���F0�z</b></small><font size=+2 color=red>�V�X�e���G���[");
	$Page->Print("</font><br>\n");
	$Page->Print("<dt>0 ���O�F<font color=forestgreen><b>�����G���W�\\��");
	$Page->Print("���낿���˂�</b></font>�FSystem Error</dt><dd><br><br>");
	$Page->Print("$msg<br><br></dd>\n");
	$Page->Print("</dl></td></tr></table>\n");
}

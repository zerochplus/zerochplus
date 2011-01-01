#!/usr/bin/perl
#============================================================================================================
#
#	�������ݗpCGI
#	bbs.cgi
#	-------------------------------------------------------------------------------------
#	2002.12.07 start
#	2003.02.06 ���ʕ��������W���[����
#	2004.04.10 �V�X�e���ύX�ɔ�������
#
#============================================================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);

push @INC, 'perllib';

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(BBSCGI());

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub BBSCGI
{
	my (%SYS, $Page, $err);
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# �������ɐ��������珑�����ݏ������J�n
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		require './module/vara.pl';
		my $WriteAid = new VARA;
		$WriteAid->Init($SYS{'SYS'}, $SYS{'FORM'}, $SYS{'SET'}, undef, $SYS{'CONV'});
		
		# �������݂ɐ���������f���\���v�f���X�V����
		if (($err = $WriteAid->Write()) == 0) {
			if (! $SYS{'SYS'}->Equal('FASTMODE', 1)) {
				require './module/varda.pl';
				my $BBSAid = new VARDA;
				
				$BBSAid->Init($SYS{'SYS'}, $SYS{'SET'});
				$BBSAid->CreateIndex();
				$BBSAid->CreateIIndex();
				$BBSAid->CreateSubback();
			}
			PrintBBSJump(\%SYS, $Page);
		}
		else {
			PrintBBSError(\%SYS, $Page, $err);
		}
	}
	else {
		# �X���b�h�쐬��ʕ\��
		if ($err == 9000) {
			PrintBBSThreadCreate(\%SYS, $Page);
			$err = 0;
		}
		# cookie�m�F��ʕ\��
		elsif ($err == 9001) {
			PrintBBSCookieConfirm(\%SYS, $Page);
			$err = 0;
		}
		# �������݊m�F��ʕ\��
		elsif ($err == 9002) {
			PrintBBSWriteConfirm(\%SYS, $Page);
			$err = 0;
		}
		# �g�т���̃X���b�h�쐬��ʕ\��
		elsif ($err == 9003) {
			PrintBBSMobileThreadCreate($SYS{'SYS'}, $Page, $SYS{'SET'});
			$err = 0;
		}
		# �G���[��ʕ\��
		else {
			PrintBBSError(\%SYS, $Page, $err);
		}
	}
	
	# ���ʂ̕\��
	$Page->Flush('', 0, 0);
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi������
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#	2010.08.23 windyakin ��
#	 -> �N�b�L�[�ƃX���b�h�쐬�̏�����ύX
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($Sys, $Page) = @_;
	
	# �g�p���W���[���̏�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/radagast.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	%$Sys = (
		'SYS'		=> new MELKOR,
		'SET'		=> new ISILDUR,
		'COOKIE'	=> new RADAGAST,
		'CONV'		=> new GALADRIEL,
		'PAGE'		=> $Page,
		'FORM'		=> 0,
	);
	
	# �V�X�e�����ݒ�
	if ($Sys->{'SYS'}->Init()) {
		return 990;
	}
	
	$Sys->{'FORM'} = SAMWISE->new($Sys->{'SYS'}->Get('BBSGET')),
	
	# form���ݒ�
	$Sys->{'FORM'}->DecodeForm(1);
	
	# �����L�����
	$Sys->{'SYS'}->{'MainCGI'} = $Sys;
	
	# �z�X�g���ݒ�(DNS�t����)
	$ENV{'REMOTE_HOST'} = $Sys->{'CONV'}->GetRemoteHost() unless ($ENV{'REMOTE_HOST'});
	$Sys->{'FORM'}->Set('HOST', $ENV{'REMOTE_HOST'});
	
	$Sys->{'SYS'}->Set('ENCODE', 'Shift_JIS');
	$Sys->{'SYS'}->Set('BBS', $Sys->{'FORM'}->Get('bbs', ''));
	$Sys->{'SYS'}->Set('KEY', $Sys->{'FORM'}->Get('key', ''));
	$Sys->{'SYS'}->Set('AGENT', $Sys->{'CONV'}->GetAgentMode($ENV{'HTTP_USER_AGENT'}));
	$Sys->{'SYS'}->Set('KOYUU', $ENV{'REMOTE_HOST'});
	
	# �g�т̏ꍇ�͋@�����ݒ�
	if ($Sys->{'SYS'}->Get('AGENT') !~ /^[0P]$/) {
		my $product = GetProductInfo($Sys->{'CONV'}, $ENV{'HTTP_USER_AGENT'}, $ENV{'REMOTE_HOST'});
		
		if (! defined  $product) {
			return 950;
		}
		else {
			$Sys->{'SYS'}->Set('KOYUU', $product);
		}
	}
	
	# SETTING.TXT�̓ǂݍ���
	if (! $Sys->{'SET'}->Load($Sys->{'SYS'})) {
		return 999;
	}
	
	# �g�т���̃X���b�h�쐬�t�H�[���\��
	# $Sys->{'SYS'}->Equal('AGENT', 'O') && 
	if ($Sys->{'FORM'}->Equal('mb', 'on') && ! $Sys->{'FORM'}->IsExist('time')) {
		return 9003;
	}
	
	# form����key�����݂����烌�X��������
	if ($Sys->{'FORM'}->IsExist('key'))	{ $Sys->{'SYS'}->Set('MODE', 2); }
	else								{ $Sys->{'SYS'}->Set('MODE', 1); }
	
	# �X���b�h�쐬���[�h��MESSAGE�������F�X���b�h�쐬���
	if ($Sys->{'SYS'}->Equal('MODE', 1)) {
		if (! $Sys->{'FORM'}->IsExist('MESSAGE')) {
			return 9000;
		}
		$Sys->{'FORM'}->Set('key', time);
		$Sys->{'SYS'}->Set('KEY', $Sys->{'FORM'}->Get('key'));
	}
	
	# cookie�̑��݃`�F�b�N(PC�̂�)
	if (! $Sys->{'SYS'}->Equal('AGENT', 'O')) {
		if ($Sys->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
			# ���ϐ��擾���s
			return 9001	if (!$Sys->{'COOKIE'}->Init());
			
			# ���O��cookie
			if ($Sys->{'SET'}->Equal('BBS_NAMECOOKIE_CHECK', 'checked')
				&& ! $Sys->{'COOKIE'}->IsExist('NAME')) {
				return 9001;
			}
			# ���[����cookie
			if ($Sys->{'SET'}->Equal('BBS_MAILCOOKIE_CHECK', 'checked')
				&& ! $Sys->{'COOKIE'}->IsExist('MAIL')) {
				return 9001;
			}
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�X���b�h�쐬�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSThreadCreate
{
	my ($Sys, $Page) = @_;
	my ($SET, $Caption, $title, $link, $image, $code, $cgipath);
	
	require './module/legolas.pl';
	$Caption = new LEGOLAS;
	$Caption->Load($Sys->{'SYS'}, 'META');
	
	$SET	= $Sys->{'SET'};
	$title	= $SET->Get('BBS_TITLE');
	$link	= $SET->Get('BBS_TITLE_LINK');
	$image	= $SET->Get('BBS_TITLE_PICTURE');
	$code	= $Sys->{'SYS'}->Get('ENCODE');
	$cgipath	= $Sys->{'SYS'}->Get('CGIPATH');
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
	$Page->Print("<html lang=\"ja\">\n");
	$Page->Print("<head>\n");
	$Page->Print(' <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">'."\n\n");
	$Caption->Print($Page, undef);
	$Page->Print(" <title>$title</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>�^�O�o��
	{
		my @work;
		$work[0] = $SET->Get('BBS_BG_COLOR');
		$work[1] = $SET->Get('BBS_TEXT_COLOR');
		$work[2] = $SET->Get('BBS_LINK_COLOR');
		$work[3] = $SET->Get('BBS_ALINK_COLOR');
		$work[4] = $SET->Get('BBS_VLINK_COLOR');
		$work[5] = $SET->Get('BBS_BG_PICTURE');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\" ");
		$Page->Print("background=\"$work[5]\">\n");
	}

	$Page->Print("<div align=\"center\">");
	# �Ŕ摜�\������
	if ($image ne '') {
		# �Ŕ摜����̃����N����
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$image\"></a><br>");
		}
		# �Ŕ摜�Ƀ����N�͂Ȃ�
		else {
			$Page->Print("<img src=\"$image\" border=\"0\"><br>");
		}
	}
	$Page->Print("</div>");

	# �w�b�_�e�[�u���̕\��
	$Caption->Load($Sys->{'SYS'}, 'HEAD');
	$Caption->Print($Page, $SET);
	
	# �X���b�h�쐬�t�H�[���̕\��
	{
		my ($tblCol, $name, $mail, $cgiPath, $bbs, $tm, $ver);
		$tblCol		= $SET->Get('BBS_MAKETHREAD_COLOR');
		$name		= $Sys->{'COOKIE'}->Get('NAME', '');
		$mail		= $Sys->{'COOKIE'}->Get('MAIL', '');
		$bbs		= $Sys->{'FORM'}->Get('bbs');
		$tm			= $Sys->{'FORM'}->Get('time');
		$ver		= $Sys->{'SYS'}->Get('VERSION');
		
		$Page->Print(<<HTML);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <b>�X���b�h�V�K�쐬</b><br>
  <center>
  <form method="POST" action="./bbs.cgi">
  <input type="hidden" name="bbs" value="$bbs"><input type="hidden" name="time" value="$tm">
  <table border="0">
   <tr>
    <td align="left">
    �^�C�g���F<input type="text" name="subject" size="25">�@<input type="submit" value="�V�K�X���b�h�쐬"><br>
    ���O�F<input type="text" name="FROM" size="19" value="$name">
    E-mail<font size="1">�i�ȗ��j</font>�F<input type="text" name="mail" size="19" value="$mail"><br>
    <textarea rows="5" cols="64" name="MESSAGE"></textarea>
    </td>
   </tr>
  </table>
  </form>
  </center>
  </td>
 </tr>
</table>

<p>
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a> $ver
</p>
HTML
	}

	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�X���b�h�쐬�y�[�W(�g��)�\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Page	THORIN
#	@param	$Set	ISILDUR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSMobileThreadCreate
{
	my ($Sys, $Page, $Set) = @_;
	my ($title, $bbs, $tm, $Banner);
	
	require './module/denethor.pl';
	$Banner = new DENETHOR;
	$Banner->Load($Sys);
	
	$title	= $Set->Get('BBS_TITLE');
	$bbs	= $Sys->Get('BBS');
	$tm		= time;
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print("<html><head><title>$title</title></head><!--nobanner-->");
	$Page->Print("\n<body><form action=\"./bbs.cgi\" method=\"POST\" utn><center>$title<hr>");
	
	$Banner->Print($Page, 100, 2, 1);
	
	$Page->Print("</center>\n");
	$Page->Print("�^�C�g��<br><input type=text name=subject><br>");
	$Page->Print("���O<br><input type=text name=FROM><br>");
	$Page->Print("���[��<br><input type=text name=mail><br>");
	$Page->Print("<textarea name=MESSAGE></textarea><br>");
	$Page->Print("<input type=hidden name=bbs value=$bbs>");
	$Page->Print("<input type=hidden name=time value=$tm>");
	$Page->Print("<input type=hidden name=mb value=on>");
	$Page->Print("<input type=submit value=\"�X���b�h�쐬\">");
	$Page->Print("</form></body></html>");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�N�b�L�[�m�F�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSCookieConfirm
{
	my ($Sys, $Page) = @_;
	my ($code, $name, $mail, $msg, $bbs, $tm, $subject, $COOKIE, $oSET, $Form);
	
	$Form		= $Sys->{'FORM'};
	$oSET		= $Sys->{'SET'};
	$COOKIE		= $Sys->{'COOKIE'};
	$code		= $Sys->{'SYS'}->Get('ENCODE');
	$bbs		= $Form->Get('bbs');
	$tm			= $Form->Get('time');
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$msg		= $Form->Get('MESSAGE');
	$subject	= $Form->Get('subject');
	
	# cookie���̏o��
	$COOKIE->Set('NAME', $name)	if ($oSET->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
	$COOKIE->Set('MAIL', $mail)	if ($oSET->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
	$COOKIE->Out($Page, $oSET->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<!-- 2ch_X:cookie -->
<head>

 <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">

 <title>�� �������݊m�F ��</title>

</head>
<!--nobanner-->
HTML
	
	# <body>�^�O�o��
	{
		my @work;
		$work[0] = $Sys->{'SET'}->Get('BBS_THREAD_COLOR');
		$work[1] = $Sys->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $Sys->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $Sys->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $Sys->{'SET'}->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n");
	}
	
	$Page->Print(<<HTML);
<font size="4" color="#FF0000"><b>�������݁��N�b�L�[�m�F</b></font>
<blockquote style="margin-top:4em;">
 ���O�F $name<br>
 E-mail�F $mail<br>
 ���e�F<br>
 $msg<br>
</blockquote>

<div style="font-weight:bold;">
���e�m�F<br>
�E���e�҂́A���e�Ɋւ��Ĕ�������ӔC���S�ē��e�҂ɋA�����Ƃ��������܂��B<br>
�E���e�҂́A�b��Ɩ��֌W�ȍL���̓��e�Ɋւ��āA�����̔�p���x�������Ƃ��������܂�<br>
�E���e�҂́A���e���ꂽ���e�ɂ��āA�f���^�c�҂��R�s�[�A�ۑ��A���p�A�]�ړ��̗��p���邱�Ƃ��������܂��B<br>
�@�܂��A�f���^�c�҂ɑ΂��āA����Ґl�i������؍s�g���Ȃ����Ƃ��������܂��B<br>
�E���e�҂́A�f���^�c�҂��w�肷���O�҂ɑ΂��āA���앨�̗��p��������؂��Ȃ����Ƃ��������܂��B<br>
</div>

<form method="POST" action="./bbs.cgi">
HTML
	
	$msg =~ s/<br>/\n/g;
	
	$Page->HTMLInput('hidden', 'subject', $subject);
	$Page->HTMLInput('hidden', 'FROM', $name);
	$Page->HTMLInput('hidden', 'mail', $mail);
	$Page->HTMLInput('hidden', 'MESSAGE', $msg);
	$Page->HTMLInput('hidden', 'bbs', $bbs);
	$Page->HTMLInput('hidden', 'time', $tm);
	
	# ���X�������݃��[�h�̏ꍇ��key��ݒ肷��
	if ($Sys->{'SYS'}->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $Form->Get('key'));
	}
	
	$Page->Print(<<HTML);
<input type="submit" value="��L�S�Ă��������ď�������"><br>
</form>

<p>
�ύX����ꍇ�͖߂�{�^���Ŗ߂��ď��������ĉ������B
</p>

<p>
���݁A�r�炵�΍�ŃN�b�L�[��ݒ肵�Ă��Ȃ��Ə������݂ł��Ȃ��悤�ɂ��Ă��܂��B<br>
<font size="2">(cookie��ݒ肷��Ƃ��̉�ʂ͂łȂ��Ȃ�܂��B)</font><br>
</p>

</body>
</html>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�������݊m�F�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSWriteConfirm
{
	my ($Sys, $Page) = @_;
	my ($Form, $bbs, $key, $tm, $subject, $name, $mail, $msg);
	
	$Form		= $Sys->{'FORM'};
	$bbs		= $Form->Get('bbs');
	$tm			= $Form->Get('time');
	$subject	= $Form->Get('subject');
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$msg		= $Form->Get('MESSAGE');
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<!-- 2ch_X:cookie -->
<head>
	<title>�� �������݊m�F ��</title>
<META http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
</head>
<!--nobanner-->
HTML

	# <body>�^�O�o��
	{
		my @work;
		$work[0] = $Sys->{'SET'}->Get('BBS_THREAD_COLOR');
		$work[1] = $Sys->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $Sys->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $Sys->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $Sys->{'SET'}->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n");
	}
	
	$Page->Print(<<HTML);
<font size="+1" color="#FF0000">�������݊m�F�B</font><br>
<br>
�������݂Ɋւ��ėl�X�ȃ��O��񂪋L�^����Ă��܂��B<br>
�����Ǒ��ɔ�������A���l�ɖ��f�������鏑�����݂͍T���ĉ�����<br>
<form method="POST" action="./subbbs.cgi">
�^�C�g���F$subject<br>
���O�F$name<br>
E-mail �F $mail<br>
���e�F
<blockquote>
$msg
</blockquote>
HTML	
	$msg =~ s/<br>/\n/g;
	
	$Page->HTMLInput('hidden', 'subject', $subject);
	$Page->HTMLInput('hidden', 'FROM', $name);
	$Page->HTMLInput('hidden', 'mail', $mail);
	$Page->HTMLInput('hidden', 'MESSAGE', $msg);
	$Page->HTMLInput('hidden', 'bbs', $bbs);
	$Page->HTMLInput('hidden', 'time', $tm);
	
	# ���X�������݃��[�h�̏ꍇ��key��ݒ肷��
	if ($Sys->{'SYS'}->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $Form->Get('key'));
	}
	$Page->Print(<<HTML);
<br>
<br>
<input type="submit" value="�S�ӔC�𕉂����Ƃ��������ď�������"><br>
�ύX����ꍇ�͖߂�{�^���Ŗ߂��ď��������ĉ������B<br>
</form>
</body>
</html>
HTML
}


#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�W�����v�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($Sys, $Page) = @_;
	my ($SYS, $Form, $bbsPath);
	
	$SYS		= $Sys->{'SYS'};
	$Form		= $Sys->{'FORM'};
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	
	# �g�їp�\��
	if ( $Form->Equal('mb', 'on') || $SYS->Equal('AGENT', 'O') ) {
		$bbsPath = $SYS->Get('CGIPATH').'/r.cgi/'.$Form->Get('bbs').'/'.$Form->Get('key').'/l10';
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>�������݊����ł�<br>');
		$Page->Print("<a href=\"$bbsPath\">������</a>");
		$Page->Print("����f���֖߂��Ă��������B\n");
	}
	# PC�p�\��
	else {
		my $COOKIE = $Sys->{'COOKIE'};
		my $oSET = $Sys->{'SET'};
		my $name = $Sys->{'FORM'}->Get('NAME', '');
		my $mail = $Sys->{'FORM'}->Get('MAIL', '');
		
		$COOKIE->Set('NAME', $name)	if ($oSET->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$COOKIE->Set('MAIL', $mail)	if ($oSET->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$COOKIE->Out($Page, $oSET->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print(<<HTML);
<html>
<head>
	<title>�������݂܂����B</title>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<meta http-equiv="Refresh" content="5;URL=$bbsPath/">
</head>
<!--nobanner-->
<body>
�������݂��I���܂����B<br>
<br>
��ʂ�؂�ւ���܂ł��΂炭���҂��������B<br>
<br>
<br>
<br>
<br>
<hr>
HTML
	
	}
	# ���m���\��(�\�����������Ȃ��ꍇ�̓R�����g�A�E�g��������0��)
	if (0) {
		require './module/denethor.pl';
		my $BANNER = new DENETHOR;
		$BANNER->Load($SYS);
		$BANNER->Print($Page, 100, 0, $SYS->Get('AGENT'));
	}
	# �f�o�b�O�p�\��
	if (0) {
		$Page->Print('MODE:' . $Sys->{'SYS'}->Get('MODE', '') . '<br>');
		$Page->Print('KEY:' . $Sys->{'FORM'}->Get('key', '') . '<br>');
		$Page->Print('SUBJECT:' . $Sys->{'FORM'}->Get('subject', '') . '<br>');
		$Page->Print('NAME:' . $Sys->{'FORM'}->Get('FROM', '') . '<br>');
		$Page->Print('MAIL:' . $Sys->{'FORM'}->Get('mail', '') . '<br>');
		$Page->Print('CONTENT:' . $Sys->{'FORM'}->Get('MESSAGE', '') . '<br>');
	}
	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�G���[�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($Sys, $Page, $err) = @_;
	my ($ERROR);
	
	require './module/orald.pl';
	$ERROR = new ORALD;
	$ERROR->Load($Sys->{'SYS'});
	
	$ERROR->Print($Sys, $Page, $err, $Sys->{'SYS'}->Get('AGENT'));
}

#------------------------------------------------------------------------------------------------------------
#
#	�g�ы@����擾
#	-------------------------------------------------------------------------------------
#	@param	$oConv	GARADRIEL
#	@param	$agent	HTTP_USER_AGENT�l
#	@return	�̎��ʔԍ�
#
#	2010.08.14 windyakin ��
#	 -> ��v3�L�����A+����p2������悤�ɕύX
#
#------------------------------------------------------------------------------------------------------------
sub GetProductInfo
{
	my ($oConv, $agent, $host) = @_;
	my $product = undef;
	
	# docomo
	if ( $host =~ /\.docomo.ne.jp$/ ) {
		# $ENV{'HTTP_X_DCMGUID'} - �[�������ԍ�, �̎��ʏ��, ���[�UID, i���[�hID
		$product = $ENV{'HTTP_X_DCMGUID'};
		$product =~ s/^X-DCMGUID: ([a-zA-Z0-9]+)$/$1/i;
	}
	# SoftBank
	elsif ( $host =~ /\.(?:jp-.|vodafone|softbank).ne.jp$/ ) {
		# USERAGENT�Ɋ܂܂��15���̐��� - �[���V���A���ԍ�
		$product = $agent;
		$product =~ s/.+\/SN([A-Za-z0-9]+)\ .+/$1/;
	}
	# au
	elsif ( $host =~ /\.ezweb.ne.jp$/ ) {
		# $ENV{'HTTP_X_UP_SUBNO'} - �T�u�X�N���C�oID, EZ�ԍ�
		$product = $ENV{'HTTP_X_UP_SUBNO'};
		$product =~ s/([A-Za-z0-9_]+).ezweb.ne.jp/$1/i;
	}
	# e-mobile(�����[��)
	elsif ( $host =~ /\.emobile.ad.jp$/ ) {
		# $ENV{'X-EM-UID'} - 
		$product = $ENV{'X-EM-UID'};
		$product =~ s/x-em-uid: (.+)/$1/i;
	}
	# ����p2
	elsif ( $host =~ /(?:cw43|p202).razil.jp$/ ) {
		# $ENV{'HTTP_X_P2_CLIENT_HOST'} - (�����҂̃z�X�g)
		# $ENV{'HTTP_X_P2_CLIENT_IP'} - (�����҂�IP)
		# $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} - (�����҂̌ő̎��ʔԍ�)
		$ENV{'REMOTE_P2'} = $ENV{'REMOTE_ADDR'};
		$ENV{'REMOTE_ADDR'} = $ENV{'HTTP_X_P2_CLIENT_IP'};
		if( $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} ne "" ) {
			$product = $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'};
		}
		else {
			$product = $agent;
			$product =~ s/.+p2-user-hash: (.+)\)/$1/i;
		}
	}
	else {
		$product = $oConv->GetRemoteHost();
	}
	return $product;
}


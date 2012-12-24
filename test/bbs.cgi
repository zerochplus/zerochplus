#!/usr/bin/perl
#============================================================================================================
#
#	�������ݗpCGI
#
#============================================================================================================

use lib './perllib';

use strict;
use warnings;
no warnings 'once';
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);


# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(BBSCGI());

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�G���[�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub BBSCGI
{
	require './module/constant.pl';
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	my $CGI = {};
	my $err = $ZP::E_SUCCESS;
	
	$err = Initialize($CGI, $Page);
	# �������ɐ��������珑�����ݏ������J�n
	if ($err == $ZP::E_SUCCESS) {
		my $Sys = $CGI->{'SYS'};
		my $Form = $CGI->{'FORM'};
		my $Set = $CGI->{'SET'};
		my $Conv = $CGI->{'CONV'};
		
		require './module/vara.pl';
		my $WriteAid = VARA->new;
		$WriteAid->Init($Sys, $Form, $Set, undef, $Conv);
		
		$err = $WriteAid->Write();
		# �������݂ɐ���������f���\���v�f���X�V����
		if ($err == $ZP::E_SUCCESS) {
			if (!$Sys->Equal('FASTMODE', 1)) {
				require './module/varda.pl';
				my $BBSAid = VARDA->new;
				
				$BBSAid->Init($Sys, $Set);
				$BBSAid->CreateIndex();
				$BBSAid->CreateIIndex();
				$BBSAid->CreateSubback();
			}
			PrintBBSJump($CGI, $Page);
		}
		else {
			PrintBBSError($CGI, $Page, $err);
		}
	}
	else {
		# �X���b�h�쐬��ʕ\��
		if ($err == $ZP::E_PAGE_THREAD) {
			PrintBBSThreadCreate($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# cookie�m�F��ʕ\��
		elsif ($err == $ZP::E_PAGE_COOKIE) {
			PrintBBSCookieConfirm($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# �������݊m�F��ʕ\��
		elsif ($err == $ZP::E_PAGE_WRITE) {
			PrintBBSWriteConfirm($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# �g�т���̃X���b�h�쐬��ʕ\��
		elsif ($err == $ZP::E_PAGE_THREADMOBILE) {
			PrintBBSMobileThreadCreate($CGI, $Page);
			$err = $ZP::E_SUCCESS;
		}
		# �G���[��ʕ\��
		else {
			PrintBBSError($CGI, $Page, $err);
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
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($CGI, $Page) = @_;
	
	# �g�p���W���[���̏�����
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/radagast.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	my $Sys = MELKOR->new;
	my $Conv = GALADRIEL->new;
	my $Set = ISILDUR->new;
	my $Cookie = RADAGAST->new;
	
	# �V�X�e�����ݒ�
	return $ZP::E_SYSTEM_ERROR if ($Sys->Init());
	
	my $Form = SAMWISE->new($Sys->Get('BBSGET'));
	
	%$CGI = (
		'SYS'		=> $Sys,
		'SET'		=> $Set,
		'COOKIE'	=> $Cookie,
		'CONV'		=> $Conv,
		'PAGE'		=> $Page,
		'FORM'		=> $Form,
	);
	
	# �����L�����
	$Sys->Set('MainCGI', $CGI);
	
	# form���ݒ�
	$Form->DecodeForm(1);
	
	# �z�X�g���ݒ�(DNS�t����)
	#�ϐ��������`�F�b�N��}���B
	if(!defined $ENV{'REMOTE_HOST'} || $ENV{'REMOTE_HOST'} eq '') {
		$ENV{'REMOTE_HOST'} = $Conv->GetRemoteHost();
	}
	$Form->Set('HOST', $ENV{'REMOTE_HOST'});
	
	my $client = $Conv->GetClient();
	
	$Sys->Set('ENCODE', 'Shift_JIS');
	$Sys->Set('BBS', $Form->Get('bbs', ''));
	$Sys->Set('KEY', $Form->Get('key', ''));
	$Sys->Set('CLIENT', $client);
	$Sys->Set('AGENT', $Conv->GetAgentMode($client));
	$Sys->Set('KOYUU', $ENV{'REMOTE_HOST'});
	$Sys->Set('BBSPATH_ABS', $Conv->MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH')));
	$Sys->Set('BBS_ABS', $Conv->MakePath($Sys->Get('BBSPATH_ABS'), $Sys->Get('BBS')));
	$Sys->Set('BBS_REL', $Conv->MakePath($Sys->Get('BBSPATH'), $Sys->Get('BBS')));
	
	# �g�т̏ꍇ�͋@�����ݒ�
	if ($client & $ZP::C_MOBILE_IDGET) {
		my $product = $Conv->GetProductInfo($client);
		
		if (!defined $product) {
			return $ZP::E_POST_NOPRODUCT;
		}
		
		$Sys->Set('KOYUU', $product);
	}
	
	# SETTING.TXT�̓ǂݍ���
	if (!$Set->Load($Sys)) {
		return $ZP::E_POST_NOTEXISTBBS;
	}
	
	# �g�т���̃X���b�h�쐬�t�H�[���\��
	# $S->Equal('AGENT', 'O') && 
	if ($Form->Equal('mb', 'on') && $Form->Equal('thread', 'on')) {
		return $ZP::E_PAGE_THREADMOBILE;
	}
	
	# form����key�����݂����烌�X��������
	if ($Form->IsExist('key'))	{ $Sys->Set('MODE', 2); }
	else						{ $Sys->Set('MODE', 1); }
	
	# �X���b�h�쐬���[�h��MESSAGE�������F�X���b�h�쐬���
	if ($Sys->Equal('MODE', 1)) {
		if (!$Form->IsExist('MESSAGE')) {
			return $ZP::E_PAGE_THREAD;
		}
		$Form->Set('key', time);
		$Sys->Set('KEY', $Form->Get('key'));
	}
	
	# cookie�̑��݃`�F�b�N(PC�̂�)
	if ($client & $ZP::C_PC) {
		if ($Set->Equal('SUBBBS_CGI_ON', 1)) {
			# ���ϐ��擾���s
			if (!$Cookie->Init()) {
				return $ZP::E_PAGE_COOKIE;
			}
			
			# ���O��cookie
			if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked') && !$Cookie->IsExist('NAME')) {
				return $ZP::E_PAGE_COOKIE;
			}
			# ���[����cookie
			if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked') && !$Cookie->IsExist('MAIL')) {
				return $ZP::E_PAGE_COOKIE;
			}
		}
	}
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�X���b�h�쐬�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSThreadCreate
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	my $Form = $CGI->{'FORM'};
	my $Cookie = $CGI->{'COOKIE'};
	
	require './module/legolas.pl';
	my $Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	my $title = $Set->Get('BBS_TITLE');
	my $link = $Set->Get('BBS_TITLE_LINK');
	my $image = $Set->Get('BBS_TITLE_PICTURE');
	my $code = $Sys->Get('ENCODE');
	my $cgipath = $Sys->Get('CGIPATH');
	
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
		$work[0] = $Set->Get('BBS_BG_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		$work[5] = $Set->Get('BBS_BG_PICTURE');
		
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
	$Caption->Load($Sys, 'HEAD');
	$Caption->Print($Page, $Set);
	
	# �X���b�h�쐬�t�H�[���̕\��
	{
		my $tblCol = $Set->Get('BBS_MAKETHREAD_COLOR');
		my $name = $Cookie->Get('NAME', '');
		my $mail = $Cookie->Get('MAIL', '');
		my $bbs = $Form->Get('bbs');
		my $tm = $Form->Get('time');
		my $ver = $Sys->Get('VERSION');
		
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
$ver
</p>
HTML
	}

	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�X���b�h�쐬�y�[�W(�g��)�\��
#	-------------------------------------------------------------------------------------
#	@param	$CGI	
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSMobileThreadCreate
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Set = $CGI->{'SET'};
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $title = $Set->Get('BBS_TITLE');
	my $bbs = $Sys->Get('BBS');
	my $tm = time;
	
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
#	@param	$CGI	
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSCookieConfirm
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Form = $CGI->{'FORM'};
	my $Set = $CGI->{'SET'};
	my $Cookie = $CGI->{'COOKIE'};
	
	my $sanitize = sub {
		$_ = shift;
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/"/&#34;/g;
		return $_;
	};
	my $code = $Sys->Get('ENCODE');
	my $bbs = &$sanitize($Form->Get('bbs'));
	my $tm = &$sanitize($Form->Get('time'));
	my $name = &$sanitize($Form->Get('FROM'));
	my $mail = &$sanitize($Form->Get('mail'));
	my $msg = &$sanitize($Form->Get('MESSAGE'));
	my $subject = &$sanitize($Form->Get('subject'));
	my $key = &$sanitize($Form->Get('key'));
	
	# cookie���̏o��
	$Cookie->Set('NAME', $name)	if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
	$Cookie->Set('MAIL', $mail)	if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
	$Cookie->Out($Page, $Set->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
	
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
		$work[0] = $Set->Get('BBS_THREAD_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		
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
	if ($Sys->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $key);
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
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSWriteConfirm
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Form = $CGI->{'FORM'};
	my $Set = $CGI->{'SET'};
	
	my $sanitize = sub {
		$_ = shift;
		s/&/&amp;/g;
		s/</&lt;/g;
		s/>/&gt;/g;
		s/"/&#34;/g;
		return $_;
	};
	my $bbs = &$sanitize($Form->Get('bbs'));
	my $tm = &$sanitize($Form->Get('time'));
	my $name = &$sanitize($Form->Get('FROM'));
	my $mail = &$sanitize($Form->Get('mail'));
	my $msg = &$sanitize($Form->Get('MESSAGE'));
	my $subject = &$sanitize($Form->Get('subject'));
	my $key = &$sanitize($Form->Get('key'));
	
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
		$work[0] = $Set->Get('BBS_THREAD_COLOR');
		$work[1] = $Set->Get('BBS_TEXT_COLOR');
		$work[2] = $Set->Get('BBS_LINK_COLOR');
		$work[3] = $Set->Get('BBS_ALINK_COLOR');
		$work[4] = $Set->Get('BBS_VLINK_COLOR');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\">\n");
	}
	
	$msg =~ s/\n/<br>/g;
	
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
	if ($Sys->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $key);
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
#	@param	$CGI
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($CGI, $Page) = @_;
	
	my $Sys = $CGI->{'SYS'};
	my $Form = $CGI->{'FORM'};
	my $Set = $CGI->{'SET'};
	my $Conv = $CGI->{'CONV'};
	my $Cookie = $CGI->{'COOKIE'};
	
	# �g�їp�\��
	if ($Form->Equal('mb', 'on') || ($Sys->Get('CLIENT') & $ZP::C_MOBILEBROWSER) ) {
		my $bbsPath = $Conv->MakePath($Sys->Get('CGIPATH').'/r.cgi/'.$Form->Get('bbs').'/'.$Form->Get('key').'/l10');
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>�������݊����ł�<br>');
		$Page->Print("<a href=\"$bbsPath\">������</a>");
		$Page->Print("����f���֖߂��Ă��������B\n");
	}
	# PC�p�\��
	else {
		my $bbsPath = $Conv->MakePath($Sys->Get('BBS_REL'));
		my $name = $Form->Get('NAME', '');
		my $mail = $Form->Get('MAIL', '');
		
		$Cookie->Set('NAME', $name)	if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$Cookie->Set('MAIL', $mail)	if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$Cookie->Out($Page, $Set->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
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
		my $Banner = DENETHOR->new;
		$Banner->Load($Sys);
		$Banner->Print($Page, 100, 0, $Sys->Get('AGENT'));
	}
	$Page->Print("\n</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi�G���[�y�[�W�\��
#	-------------------------------------------------------------------------------------
#	@param	$CGI
#	@param	$Page
#	@param	$err
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($CGI, $Page, $err) = @_;
	
	require './module/orald.pl';
	my $Error = ORALD->new;
	$Error->Load($CGI->{'SYS'});
	
	$Error->Print($CGI, $Page, $err, $CGI->{'SYS'}->Get('AGENT'));
}


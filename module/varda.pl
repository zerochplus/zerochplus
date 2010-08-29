#============================================================================================================
#
#	bbs.cgi�x�����W���[��(VARDA)
#	varda.pl
#	---------------------------------------------
#	2003.02.06 start
#	2004.03.31 ���e�ύX
#
#	���낿���˂�v���X
#	2010.08.12 �V�X�e�����ςɔ����ύX
#
#============================================================================================================
package	VARDA;

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
	my $obj = {};
	
	$obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'BANNER'	=> undef,
		'CODE'		=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	������
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$Setting	ISILDUR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Setting) = @_;
	
	require './module/baggins.pl';
	require './module/galadriel.pl';
	require './module/denethor.pl';
	
	# �g�p���W���[����ݒ�
	$this->{'SYS'}		= $Sys;
	$this->{'THREADS'}	= BILBO->new;
	$this->{'CONV'}		= GALADRIEL->new;
	$this->{'BANNER'}	= DENETHOR->new;
	$this->{'CODE'}		= 'sjis';
	
	if (! defined $Setting) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	else {
		$this->{'SET'} = $Setting;
	}
	
	# ���̓ǂݍ���
	$this->{'THREADS'}->Load($Sys);
	$this->{'BANNER'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�������ꂽ��1��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub CreateIndex
{
	my $this = shift;
	my ($Sys, $Threads, $bbsSetting, $Index, $Caption);
	my ($path, $i);
	
	$Sys		= $this->{'SYS'};
	$Threads 	= $this->{'THREADS'};
	$bbsSetting	= $this->{'SET'};
	
	# CREATE���[�h�A�܂��̓X���b�h��index�\���͈͓��̏ꍇ�̂�index���X�V����
	if ($Sys->Equal('MODE', 'CREATE')
		|| ($Threads->GetPosition($Sys->Get('KEY')) < $bbsSetting->Get('BBS_MAX_MENU_THREAD'))) {
		
		require './module/thorin.pl';
		require './module/legolas.pl';
		$Index = THORIN->new;
		$Caption = LEGOLAS->new;
		
		PrintIndexHead($this, $Index, $Caption);
		PrintIndexMenu($this, $Index);
		PrintIndexPreview($this, $Index);
		PrintIndexFoot($this, $Index, $Caption);
		
		$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/index.html';
		$Index->Flush(1, $Sys->Get('PM-TXT'), $path);
		
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	i/index.html����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub CreateIIndex
{
	my $this = shift;
	my ($Sys, $Threads, $bbsSetting, $oConv, $Page);
	my ($path, $i, $name, $key, $res, $cgiPath, $title, $menuNum, $code, $bbs);
	my (@threadSet);
	
	require './module/thorin.pl';
	$Page = THORIN->new;
	
	# �O����
	$Sys		= $this->{'SYS'};
	$Threads 	= $this->{'THREADS'};
	$bbsSetting	= $this->{'SET'};
	$oConv		= $this->{'CONV'};
	
	$cgiPath	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	$title		= $bbsSetting->Get('BBS_TITLE');
	$menuNum	= $bbsSetting->Get('BBS_MAX_MENU_THREAD');
	$code		= $this->{'CODE'};
	$i			= 1;
	$bbs		= $Sys->Get('BBS');
	
	# �S�X���b�h���擾
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# HTML�w�b�_�̏o��
	$Page->Print("<html><!--nobanner--><head><title>$title</title>");
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print("</head><body><center>$title</center>");
	
	# �o�i�[�\��
	$this->{'BANNER'}->Print($Page, 100, 1, 1);
	$Page->Print('<hr></center>');
	
	# �X���b�h���������[�v���܂킷
	foreach $key (@threadSet) {
		if ($i > $menuNum) {
			last;
		}
		$name = $Threads->Get('SUBJECT', $key);
		$res = $Threads->Get('RES', $key);
		$path = $oConv->CreatePath($Sys, 1, $bbs, $key, 'l10');
		
		$Page->Print("<a href=\"$path\">$i: $name($res)</a><br> \n");
		$i++;
	}
	
	# �t�b�^�����̏o��
	$path = "$cgiPath/p.cgi?bbs=$bbs&st=$i";
	$Page->Print("<hr><a href=\"$cgiPath/bbs.cgi?bbs=$bbs&mobile=true\">");
	$Page->Print("�X���b�h�쐬</a> <a href=\"$path\">����</a><hr></body></html>\n");
	
	# i/index.html�ɏ�������
	$path = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$path/i/index.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	subback.html����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> ���m���\�����C�Ӑݒ�ł���悤�ɂȂ����̂ŕύX
#
#------------------------------------------------------------------------------------------------------------
sub CreateSubback
{
	my $this = shift;
	my ($Sys, $Threads, $bbsSetting, $oConv, $Page);
	my ($path, $i, $name, $key, $res, $cgiPath, $title, $code, $bbs);
	my (@threadSet, $max, $Caption, $version);
	
	require './module/thorin.pl';
	$Page = THORIN->new;
	
	$Sys		= $this->{'SYS'};
	$Threads 	= $this->{'THREADS'};
	$bbsSetting	= $this->{'SET'};
	$oConv		= $this->{'CONV'};
	
	$cgiPath	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	$title		= $bbsSetting->Get('BBS_TITLE');
	$code		= $this->{'CODE'};
	$i			= 1;
	$bbs		= $Sys->Get('BBS');
	$max		= $Sys->Get('SUBMAX');
	$version	= $Sys->Get('VERSION');
	
	# �S�X���b�h���擾
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# HTML�w�b�_�̏o��
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title - �X���b�h�ꗗ</title>\n\n");
	$Page->Print("</head>\n<body>\n\n");
	
	# �o�i�[�\��
	$this->{'BANNER'}->Print($Page, 100, 2, 0) if ($Sys->Get('BANNER'));
	
	$Page->Print("<div class=\"threads\">");
	$Page->Print("<small>\n");
	
	# �X���b�h���������[�v���܂킷
	foreach $key (@threadSet) {
		if ($i > $max) {
			last;
		}
		$name = $Threads->Get('SUBJECT', $key);
		$res = $Threads->Get('RES', $key);
		$path = $oConv->CreatePath($Sys, 0, $bbs, $key, 'l50');
		
		$Page->Print("<a href=\"$path\" target=\"_blank\">$i: $name($res)</a>&nbsp;&nbsp;\n");
		$i++;
	}
	
	# �t�b�^�����̏o��
	$Page->Print(<<HTML);
</small>
</div>

<div align="right" style="margin-top:1em;">
<small><a href="./kako/index.html" target="_blank"><b>�ߋ����O�q�ɂ͂�����</b></a></small>
</div>

<hr>

<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$version
</div>

</body>
</html>
HTML
	
	# subback.html�ɏ�������
	$path = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$path/subback.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�w�b�_����)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexHead
{
	my ($this, $Page, $Caption) = @_;
	my ($title, $link, $image, $code);
	
	$Caption->Load($this->{'SYS'}, 'META');
	$title	= $this->{'SET'}->Get('BBS_TITLE');
	$link	= $this->{'SET'}->Get('BBS_TITLE_LINK');
	$image	= $this->{'SET'}->Get('BBS_TITLE_PICTURE');
#	$code	= $this->{'CODE'};
	
	# HTML�w�b�_�̏o��
	$Page->Print(<<HEAD);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 
HEAD
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title</title>\n\n");
	
	# cookie�pscript�̏o��
	if ($this->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
		require './module/radagast.pl';
		RADAGAST::Print(undef, $Page);
	}
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>�^�O�o��
	{
		my @work;
		$work[0] = $this->{'SET'}->Get('BBS_BG_COLOR');
		$work[1] = $this->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $this->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $this->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $this->{'SET'}->Get('BBS_VLINK_COLOR');
		$work[5] = $this->{'SET'}->Get('BBS_BG_PICTURE');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\" background=\"$work[5]\">\n");

	}
	$Page->Print("<a name=\"top\"></a>\n<div align=\"center\">");
	
	# �Ŕ摜�\������
	if ($image ne '') {
		# �Ŕ摜����̃����N����
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$link\"></a></div>\n");
		}
		# �Ŕ摜�Ƀ����N�͂Ȃ�
		else {
			$Page->Print("<img src=\"$image\" border=\"0\" alt\"$link\"></div>\n");
		}
	}
	
	# �w�b�_�e�[�u���̕\��
	$Caption->Load($this->{'SYS'}, 'HEAD');
	$Caption->Print($Page, $this->{'SET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�X���b�h���j���[����)
#	-------------------------------------------------------------------------------------
#	@param	$Page
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexMenu
{
	my ($this, $Page) = @_;
	my ($Conv, $menuCol, $menuNum, $prevNum, $i);
	my (@threadSet, $key, $name, $res, $path, $max);
	
	$Conv		= $this->{'CONV'};
	$menuCol	= $this->{'SET'}->Get('BBS_MENU_COLOR');
	$menuNum	= $this->{'SET'}->Get('BBS_MAX_MENU_THREAD');
	$prevNum	= $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	$i			= 1;
	$max		= $this->{'SYS'}->Get('SUBMAX');
	
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# �o�i�[�̕\��
	$this->{'BANNER'}->Print($Page, 95, 0, 0);
	
	$Page->Print(<<MENU);

<a name="menu"></a>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$menuCol" style="margin:1.2em auto;" align="center">
 <tr>
  <td>
  <small>
MENU
	
	# �X���b�h���������[�v���܂킷
	foreach $key (@threadSet) {
		if (($i > $menuNum) || ($i > $max)) {
			last;
		}
		$name = $this->{'THREADS'}->Get('SUBJECT', $key);
		$res = $this->{'THREADS'}->Get('RES', $key);
		$path = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		
		# �v���r���[�X���b�h�̏ꍇ�̓v���r���[�ւ̃����N��\��
		if ($i < $prevNum) {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i:</a> ");
			$Page->Print("<a href=\"#$i\">$name($res)</a>�@\n");
		}
		else {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i: $name($res)</a>�@\n");
		}
		$i++;
	}
	$Page->Print(<<MENU);
  </small>
  <div align="right"><small><b><a href="./subback.html">�X���b�h�ꗗ�͂�����</a></b></small></div>
  </td>
 </tr>
</table>

MENU
	
	# �T�u�o�i�[�̕\��(�\���������s���ЂƂ}��)
	if ($this->{'BANNER'}->PrintSub($Page)) {
		$Page->Print("\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�X���b�h�v���r���[����)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexPreview
{
	my ($this, $Page) = @_;
	my ($oDat, $oConv, @threadSet, $Plugin);
	my ($prevNum, $threadNum, $prevT, $nextT, $tblCol, $ttlCol);
	my ($basePath, $datPath, $cnt, $subject, $res, $key, $max);
	
	# �g���@�\���[�h
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($this->{'SYS'});
	
	# �L���Ȋg���@�\�ꗗ���擾
	my (@pluginSet, @commands, $id, $count);
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	$count = 0;
	foreach $id (@pluginSet) {
		# �^�C�v��read.cgi�̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & 8) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = PLUGINCONF->new($Plugin, $id);
				$commands[$count] = $className->new($Config);
				$count++;
			}
		}
	}
	
	require './module/gondor.pl';
	$oDat = ARAGORN->new;
	
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# �O����
	$prevNum	= $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	$threadNum	= (@threadSet > $prevNum ? $prevNum : @threadSet);
	$tblCol		= $this->{'SET'}->Get('BBS_THREAD_COLOR');
	$ttlCol		= $this->{'SET'}->Get('BBS_SUBJECT_COLOR');
	$prevT		= $threadNum;
	$nextT		= ($threadNum > 1 ? 2 : 1);
	$oConv		= $this->{'CONV'};
	$basePath	= $this->{'SYS'}->Get('BBSPATH') . '/' . $this->{'SYS'}->Get('BBS');
	$cnt		= 1;
	$max		= $this->{'SYS'}->Get('SUBMAX');
	
	foreach $key (@threadSet) {
		if ($cnt > $prevNum || $cnt > $max) {
			last;
		}
		$subject	= $this->{'THREADS'}->Get('SUBJECT', $key);
		$res		= $this->{'THREADS'}->Get('RES', $key);
		$nextT		= 1 if ($cnt == $threadNum);
		
		# �w�b�_�����̕\��
		$Page->Print(<<THREAD);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <a name="$cnt"></a>
  <div align="right"><a href="#menu">��</a><a href="#$prevT">��</a><a href="#$nextT">��</a></div>
  <div style="font-weight:bold;margin-bottom:0.2em;">�y$cnt:$res�z<font size="+2" color="$ttlCol">$subject</font></div>
  <dl style="margin-top:0px;">
THREAD
		
		# �v���r���[�̕\��
		$datPath = "$basePath/dat/$key.dat";
		$oDat->Load($this->{'SYS'}, $datPath, 1);
		$this->{'SYS'}->Set('KEY', $key);
		PrintThreadPreviewOne($this, $Page, $oDat, \@commands);
		$oDat->Close();
		
		# �t�b�^�����̕\��
		{
			my ($allPath, $lastPath, $numPath);
			
			$allPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '');
			$lastPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
			$numPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '1-100');
			$Page->Print(<<KAKIKO);
    <div style="font-weight:bold;">
     <a href="$allPath">�S���ǂ�</a>
     <a href="$lastPath">�ŐV50</a>
     <a href="$numPath">1-100</a>
     <a href="#top">�̃g�b�v</a>
     <a href="./index.html">�����[�h</a>
    </div>
    </blockquote>
   </blockquote>
  </form>
  </td>
 </tr>
</table>

KAKIKO
			
		}
		
		# �J�E���^�̍X�V
		$nextT++;
		$prevT++;
		$prevT = 1 if ($cnt == 1);
		$cnt++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�t�b�^����)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> Samba�l�̕\��
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexFoot
{
	my ($this, $Page, $Caption) = @_;
	my ($SYS, $tblCol, $cgiPath, $bbs, $ver, $tm, $samba);
	
	$SYS		= $this->{'SYS'};
	$tblCol		= $this->{'SET'}->Get('BBS_MAKETHREAD_COLOR');
	$cgiPath	= $SYS->Get('SERVER') . $SYS->Get('CGIPATH');
	$bbs		= $SYS->Get('BBS');
	$ver		= $SYS->Get('VERSION');
	$samba		= $SYS->Get('SAMBATM');
	$tm			= time;
	
	# �X���b�h�쐬��ʂ�ʉ�ʂŕ\��
	if ($this->{'SET'}->Equal('BBS_PASSWORD_CHECK', 'checked')) {
		$Page->Print(<<FORM);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <form method="POST" action="$cgiPath/bbs.cgi" style="margin:1.2em 0;">
  <input type="submit" value="�V�K�X���b�h�쐬��ʂ�"><br>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </form>
  </td>
 </tr>
</table>
FORM
	}
	# �X���b�h�쐬�t�H�[����index�Ɠ�����ʂɕ\��
	else {
		$Page->Print(<<FORM);
<form method="POST" action="$cgiPath/bbs.cgi">
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#CCFFCC" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td></td>
  <td nowrap>
  �^�C�g���F<input type="text" name="subject" size="40"><input type="submit" value="�V�K�X���b�h�쐬"><br>
  ���O�F<input type="text" name="FROM" size="19"> E-mail�F<input type="text" name="mail" size="19"><br>
  ���e�F<textarea rows="5" cols="60" name="MESSAGE"></textarea>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </td>
 </tr>
</table>
</form>
FORM
	}
	
	# foot�̕\��
	$Caption->Load($this->{'SYS'}, 'FOOT');
	$Caption->Print($Page, $this->{'SET'});
	
	$Page->Print(<<FOOT);
<div style="margin-top:1.2em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">���낿���˂�</a> <a href="http://zerochplus.sourceforge.jp/">�v���X</a>
BBS.CGI - $ver (Perl)
+<a href="http://bbq.uso800.net/" target="_blank">BBQ</a>
+BBX
+<a href="http://spam-champuru.livedoor.com/dnsbl/" target="_blank">�X�p�������Ղ�[</a>
+Samba24=$samba<br>
�y�[�W�̂����܂�����B�B��</div>

FOOT
	
	$Page->Print("</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�X���b�h�v���r���[����)
#	-------------------------------------------------------------------------------------
#	@param	$this	
#	@param	$Page	
#	@param	$oDat	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadPreviewOne
{
	my ($this, $Page, $oDat, $commands) = @_;
	my ($pDat, $contNum, $start, $end, $i, $cgiPath, $bbs, $tm, $key);
	
	# �O����
	$contNum	= $this->{'SET'}->Get('BBS_CONTENTS_NUMBER');
	$cgiPath	= $this->{'SYS'}->Get('SERVER') . $this->{'SYS'}->Get('CGIPATH');
	$bbs		= $this->{'SYS'}->Get('BBS');
	$key		= $this->{'SYS'}->Get('KEY');
	$tm			= time;
	
	# �\�����̐��K��
	($start, $end) = $this->{'CONV'}->RegularDispNum(
						$this->{'SYS'}, $oDat, 1, $contNum, $contNum);
	if ($start == 1) {
		$start++;
	}
	
	# 1�̕\��
	PrintResponse($this, $Page, $oDat, $commands, 1);
	# �c��̕\��
	for ($i = $start ; $i <= $end ; $i++) {
		PrintResponse($this, $Page, $oDat, $commands, $i);
	}
	
	# �������݃t�H�[���̕\��
	$Page->Print(<<KAKIKO);
  </dl>
  <form method="POST" action="$cgiPath/bbs.cgi">
   <blockquote>
   <input type="hidden" name="bbs" value="$bbs">
   <input type="hidden" name="key" value="$key">
   <input type="hidden" name="time" value="$tm">
   <input type="submit" value="��������" name="submit"> 
   ���O�F<input type="text" name="FROM" size="19">
   E-mail�F<input type="text" name="mail" size="19"><br>
   <blockquote style="margin-top:0px;">
    <textarea rows="5" cols="64" name="MESSAGE"></textarea>
KAKIKO
	
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(���X�\������)
#	-------------------------------------------------------------------------------------
#	@param	$this	
#	@param	$Page	
#	@param	$oDat	
#	@param	$n		
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($this, $Page, $oDat, $commands, $n) = @_;
	my ($oConv, @elem, $contLen, $contLine, $nameCol, $dispLine);
	my ($pDat, $command);
	
	$oConv		= $this->{'CONV'};
	$pDat		= $oDat->Get($n - 1);
	return if (! defined $pDat);
	@elem		= split(/<>/, $$pDat);
	$contLen	= length $elem[3];
	$contLine	= $oConv->GetTextLine(\$elem[3]);
	$nameCol	= $this->{'SET'}->Get('BBS_NAME_COLOR');
	$dispLine	= $this->{'SET'}->Get('BBS_LINE_NUMBER');
	
	# URL�ƈ��p���̓K��
	$oConv->ConvertURL($this->{'SYS'}, $this->{'SET'}, 0, \$elem[3]);
	$oConv->ConvertQuotation($this->{'SYS'}, \$elem[3], 0);
	
	# �g���@�\�����s
	$this->{'SYS'}->Set('_DAT_', \@elem);
	$this->{'SYS'}->Set('_NUM_', $n);
	foreach $command (@$commands) {
		$command->execute($this->{'SYS'}, undef, 8);
	}
	
	$Page->Print("   <dt>$n ���O�F");
	
	# ���[�����L��
	if ($elem[1] eq '') {
		$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
	}
	# ���[��������
	else {
		$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
	}
	
	# �\���s�����Ȃ炷�ׂĕ\������
	if ($contLine <= $dispLine || $n == 1) {
		$Page->Print("�F$elem[2]</dt>\n    <dd>$elem[3]<br><br></dd>\n");
	}
	# �\���s���𒴂�����ȗ��\����t������
	else {
		my (@dispBuff, $path, $k);
		
		@dispBuff = split(/<br>|<BR>/, $elem[3]);
		$path = $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'),
											$this->{'SYS'}->Get('KEY'), "${n}n");
		
		$Page->Print("�F$elem[2]</dt>\n    <dd>");
		for ($k = 0 ; $k < $dispLine ; $k++) {
			$Page->Print("$dispBuff[$k]<br>");
		}
		$Page->Print("<font color=\"green\">�i�ȗ�����܂����E�E�S�Ă�ǂނɂ�");
		$Page->Print("<a href=\"$path\" target=\"_blank\">����</a>");
		$Page->Print("�������Ă��������j</font><br><br></dd>\n");
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

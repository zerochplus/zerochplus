#============================================================================================================
#
#	bbs.cgi�x�����W���[��
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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'BANNER'	=> undef,
		'CODE'		=> undef,
	};
	bless $obj, $class;
	
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
	$this->{'SYS'} = $Sys;
	$this->{'THREADS'} = BILBO->new;
	$this->{'CONV'} = GALADRIEL->new;
	$this->{'BANNER'} = DENETHOR->new;
	$this->{'CODE'} = 'sjis';
	
	if (!defined $Setting) {
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
	
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $bbsSetting = $this->{'SET'};
	
	# CREATE���[�h�A�܂��̓X���b�h��index�\���͈͓��̏ꍇ�̂�index���X�V����
	if ($Sys->Equal('MODE', 'CREATE')
		|| ($Threads->GetPosition($Sys->Get('KEY')) < $bbsSetting->Get('BBS_MAX_MENU_THREAD'))) {
		
		require './module/thorin.pl';
		require './module/legolas.pl';
		my $Index = THORIN->new;
		my $Caption = LEGOLAS->new;
		
		PrintIndexHead($this, $Index, $Caption);
		PrintIndexMenu($this, $Index);
		PrintIndexPreview($this, $Index);
		PrintIndexFoot($this, $Index, $Caption);
		
		my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/index.html';
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
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	# �O����
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $bbsSetting = $this->{'SET'};
	my $oConv = $this->{'CONV'};
	my $bbs = $Sys->Get('BBS');
	
	# HTML�w�b�_�̏o��
	my $title = $bbsSetting->Get('BBS_TITLE');
	my $code = $this->{'CODE'};
	$Page->Print("<html><!--nobanner--><head><title>$title</title>");
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print("</head><body><center>$title</center>");
	
	# �o�i�[�\��
	$this->{'BANNER'}->Print($Page, 100, 1, 1);
	$Page->Print('<hr></center>');
	
	# �S�X���b�h���擾
	my @threadSet = ();
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# �X���b�h���������[�v���܂킷
	my $menuNum = $bbsSetting->Get('BBS_MAX_MENU_THREAD');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if (++$i > $menuNum);
		
		my $name = $Threads->Get('SUBJECT', $key);
		my $res = $Threads->Get('RES', $key);
		my $path = $oConv->CreatePath($Sys, 'O', $bbs, $key, 'l10');
		
		$Page->Print("<a href=\"$path\">$i: $name($res)</a><br> \n");
	}
	
	# �t�b�^�����̏o��
	my $cgiPath = $Sys->Get('CGIPATH');
	my $pathf = "$cgiPath/p.cgi" . ($Sys->Get('PATHKIND') ? "?bbs=$bbs&st=$i" : "/$bbs/$i");
	$Page->Print("<hr>");
	$Page->Print("<a href=\"$pathf\">����</a>\n");
	$Page->Print("<form action=\"$cgiPath/bbs.cgi\" method=\"POST\" utn>");
	$Page->Print("<input type=hidden name=bbs value=$bbs>");
	$Page->Print("<input type=hidden name=mb value=on>");
	$Page->Print("<input type=hidden name=thread value=on>");
	$Page->Print("<input type=submit value=\"�X���b�h�쐬\">");
	$Page->Print("</form><hr></body></html>\n");
	
	# i/index.html�ɏ�������
	my $pathi = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$pathi/i/index.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	subback.html����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub CreateSubback
{
	my $this = shift;
	
	require './module/thorin.pl';
	my $Page = THORIN->new;
	
	my $Sys = $this->{'SYS'};
	my $Threads = $this->{'THREADS'};
	my $bbsSetting = $this->{'SET'};
	my $oConv = $this->{'CONV'};
	
	require './module/legolas.pl';
	my $Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# HTML�w�b�_�̏o��
	my $title = $bbsSetting->Get('BBS_TITLE');
	my $code = $this->{'CODE'};
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
	if ($Sys->Get('BANNER')) {
		$this->{'BANNER'}->Print($Page, 100, 2, 0);
	}
	
	$Page->Print("<div class=\"threads\">");
	$Page->Print("<small>\n");
	
	# �S�X���b�h���擾
	my @threadSet = ();
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# �X���b�h���������[�v���܂킷
	my $bbs = $Sys->Get('BBS');
	my $max = $Sys->Get('SUBMAX');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if (++$i > $max);
		
		my $name = $Threads->Get('SUBJECT', $key);
		my $res = $Threads->Get('RES', $key);
		my $path = $oConv->CreatePath($Sys, 0, $bbs, $key, 'l50');
		
		$Page->Print("<a href=\"$path\" target=\"_blank\">$i: $name($res)</a>&nbsp;&nbsp;\n");
	}
	
	# �t�b�^�����̏o��
	my $cgipath = $Sys->Get('CGIPATH');
	my $version = $Sys->Get('VERSION');
	$Page->Print(<<HTML);
</small>
</div>

<div align="right" style="margin-top:1em;">
<small><a href="./kako/" target="_blank"><b>�ߋ����O�q�ɂ͂�����</b></a></small>
</div>

<hr>

<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$version
</div>

</body>
</html>
HTML
	
	# subback.html�ɏ�������
	my $paths = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$paths/subback.html");
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
	my $this = shift;
	my ($Page, $Caption) = @_;
	
	$Caption->Load($this->{'SYS'}, 'META');
	my $title = $this->{'SET'}->Get('BBS_TITLE');
	my $link = $this->{'SET'}->Get('BBS_TITLE_LINK');
	my $image = $this->{'SET'}->Get('BBS_TITLE_PICTURE');
#	my $code = $this->{'CODE'};
	
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
		my @work = ();
		$work[0] = $this->{'SET'}->Get('BBS_BG_COLOR');
		$work[1] = $this->{'SET'}->Get('BBS_TEXT_COLOR');
		$work[2] = $this->{'SET'}->Get('BBS_LINK_COLOR');
		$work[3] = $this->{'SET'}->Get('BBS_ALINK_COLOR');
		$work[4] = $this->{'SET'}->Get('BBS_VLINK_COLOR');
		$work[5] = $this->{'SET'}->Get('BBS_BG_PICTURE');
		
		$Page->Print("<body bgcolor=\"$work[0]\" text=\"$work[1]\" link=\"$work[2]\" ");
		$Page->Print("alink=\"$work[3]\" vlink=\"$work[4]\" background=\"$work[5]\">\n");

	}
	$Page->Print("<a name=\"top\"></a>\n");
	
	# �Ŕ摜�\������
	if ($image ne '') {
		$Page->Print("<div align=\"center\">");
		# �Ŕ摜����̃����N����
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$link\"></a>");
		}
		# �Ŕ摜�Ƀ����N�͂Ȃ�
		else {
			$Page->Print("<img src=\"$image\" border=\"0\" alt=\"$link\">");
		}
		$Page->Print("</div>\n");
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
	my $this = shift;
	my ($Page) = @_;
	
	my $Conv = $this->{'CONV'};
	my $menuCol = $this->{'SET'}->Get('BBS_MENU_COLOR');
	
	# �o�i�[�̕\��
	$this->{'BANNER'}->Print($Page, 95, 0, 0);
	
	$Page->Print(<<MENU);

<a name="menu"></a>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$menuCol" style="margin:1.2em auto;" align="center">
 <tr>
  <td>
  <small>
MENU
	
	my @threadSet = ();
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# �X���b�h���������[�v���܂킷
	my $prevNum = $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	my $menuNum = $this->{'SET'}->Get('BBS_MAX_MENU_THREAD');
	my $max = $this->{'SYS'}->Get('SUBMAX');
	my $i = 0;
	foreach my $key (@threadSet) {
		last if ((++$i > $menuNum) || ($i > $max));
		
		my $name = $this->{'THREADS'}->Get('SUBJECT', $key);
		my $res = $this->{'THREADS'}->Get('RES', $key);
		my $path = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		
		# �v���r���[�X���b�h�̏ꍇ�̓v���r���[�ւ̃����N��\��
		if ($i <= $prevNum) {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i:</a> ");
			$Page->Print("<a href=\"#$i\">$name($res)</a>�@\n");
		}
		else {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i: $name($res)</a>�@\n");
		}
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
	my $this = shift;
	my ($Page) = @_;
	
	# �g���@�\���[�h
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($this->{'SYS'});
	
	# �L���Ȋg���@�\�ꗗ���擾
	my @commands = ();
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	my $count = 0;
	foreach my $id (@pluginSet) {
		# �^�C�v��read.cgi�̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & 8) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			if (-e "./plugin/$file") {
				require "./plugin/$file";
				my $Config = PLUGINCONF->new($Plugin, $id);
				$commands[$count++] = $className->new($Config);
			}
		}
	}
	
	require './module/gondor.pl';
	my $oDat = ARAGORN->new;
	
	my @threadSet = ();
	$this->{'THREADS'}->GetKeySet('ALL', '', \@threadSet);
	
	# �O����
	my $prevNum = $this->{'SET'}->Get('BBS_THREAD_NUMBER');
	my $threadNum = (scalar(@threadSet) > $prevNum ? $prevNum : scalar(@threadSet));
	my $tblCol = $this->{'SET'}->Get('BBS_THREAD_COLOR');
	my $ttlCol = $this->{'SET'}->Get('BBS_SUBJECT_COLOR');
	my $prevT = $threadNum;
	my $nextT = ($threadNum > 1 ? 2 : 1);
	my $oConv = $this->{'CONV'};
	my $basePath = $this->{'SYS'}->Get('BBSPATH') . '/' . $this->{'SYS'}->Get('BBS');
	my $max = $this->{'SYS'}->Get('SUBMAX');
	
	my $cnt = 0;
	foreach my $key (@threadSet) {
		last if (++$cnt > $prevNum || $cnt > $max);
		
		my $subject = $this->{'THREADS'}->Get('SUBJECT', $key);
		my $res = $this->{'THREADS'}->Get('RES', $key);
		$nextT = 1 if ($cnt == $threadNum);
		
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
		my $datPath = "$basePath/dat/$key.dat";
		$oDat->Load($this->{'SYS'}, $datPath, 1);
		$this->{'SYS'}->Set('KEY', $key);
		PrintThreadPreviewOne($this, $Page, $oDat, \@commands);
		$oDat->Close();
		
		# �t�b�^�����̕\��
		my $allPath = $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '');
		my $lastPath = $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		my $numPath = $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '1-100');
		$Page->Print(<<KAKIKO);
    <div style="font-weight:bold;">
     <a href="$allPath">�S���ǂ�</a>
     <a href="$lastPath">�ŐV50</a>
     <a href="$numPath">1-100</a>
     <a href="#top">�̃g�b�v</a>
     <a href="./">�����[�h</a>
    </div>
    </blockquote>
   </blockquote>
  </form>
  </td>
 </tr>
</table>

KAKIKO
		
		# �J�E���^�̍X�V
		$nextT++;
		$prevT++;
		$prevT = 1 if ($cnt == 1);
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
#------------------------------------------------------------------------------------------------------------
sub PrintIndexFoot
{
	my $this = shift;
	my ($Page, $Caption) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $tblCol = $Set->Get('BBS_MAKETHREAD_COLOR');
	my $cgipath = $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS');
	my $ver = $Sys->Get('VERSION');
	my $samba = int ($Set->Get('BBS_SAMBATIME', '') eq ''
					? $Sys->Get('DEFSAMBA') : $Set->Get('BBS_SAMBATIME'));
	my $tm = time;
	
	# �X���b�h�쐬��ʂ�ʉ�ʂŕ\��
	if ($Set->Equal('BBS_PASSWORD_CHECK', 'checked')) {
		$Page->Print(<<FORM);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <form method="POST" action="$cgipath/bbs.cgi" style="margin:1.2em 0;">
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
<form method="POST" action="$cgipath/bbs.cgi">
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#CCFFCC" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>&lrm;</td>
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
	$Caption->Load($Sys, 'FOOT');
	$Caption->Print($Page, $Set);
	
	$Page->Print(<<FOOT);
<div style="margin-top:1.2em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">���낿���˂�</a> <a href="http://zerochplus.sourceforge.jp/">�v���X</a>
BBS.CGI - $ver (Perl)
@{[ $Sys->Get('BBQ') ? '+<a href="http://bbq.uso800.net/" target="_blank">BBQ</a>' : '' ]}
@{[ $Sys->Get('BBX') ? '+BBX' : '' ]}
@{[ $Sys->Get('SPAMCH') ? '+<a href="http://spam-champuru.livedoor.com/dnsbl/" target="_blank">�X�p�������Ղ�[</a>' : '' ]}
+Samba24=$samba<br>
�y�[�W�̂����܂�����B�B��</div>

FOOT
	
	$Page->Print("</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html����(�X���b�h�v���r���[����)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$oDat		
#	@param	$commands	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadPreviewOne
{
	my $this = shift;
	my ($Page, $oDat, $commands) = @_;
	
	my $Sys = $this->{'SYS'};
	
	# �O����
	my $contNum = $this->{'SET'}->Get('BBS_CONTENTS_NUMBER');
	my $cgiPath = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	my $bbs = $Sys->Get('BBS');
	my $key = $Sys->Get('KEY');
	my $tm = time;
	
	# �\�����̐��K��
	my ($start, $end) = $this->{'CONV'}->RegularDispNum($Sys, $oDat, 1, $contNum, $contNum);
	$start++ if ($start == 1);
	
	# 1�̕\��
	PrintResponse($this, $Page, $oDat, $commands, 1);
	# �c��̕\��
	for (my $i = $start; $i <= $end; $i++) {
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
#	@param	$Page		
#	@param	$oDat		
#	@param	$commands	
#	@param	$n			
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my $this = shift;
	my ($Page, $oDat, $commands, $n) = @_;
	
	my $Sys = $this->{'SYS'};
	my $oConv = $this->{'CONV'};
	
	my $pDat = $oDat->Get($n - 1);
	return if (!defined $pDat);
	
	my @elem = split(/<>/, $$pDat, -1);
	my $contLen = length $elem[3];
	my $contLine = $oConv->GetTextLine(\$elem[3]);
	my $nameCol = $this->{'SET'}->Get('BBS_NAME_COLOR');
	my $dispLine = $this->{'SET'}->Get('BBS_LINE_NUMBER');
	
	# URL�ƈ��p���̓K��
	$oConv->ConvertURL($Sys, $this->{'SET'}, 0, \$elem[3]);
	$oConv->ConvertQuotation($Sys, \$elem[3], 0);
	
	# �g���@�\�����s
	$Sys->Set('_DAT_', \@elem);
	$Sys->Set('_NUM_', $n);
	foreach my $command (@$commands) {
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
		my @dispBuff = split(/<br>/i, $elem[3]);
		my $path = $oConv->CreatePath($Sys, 0, $Sys->Get('BBS'), $Sys->Get('KEY'), "${n}n");
		
		$Page->Print("�F$elem[2]</dt>\n    <dd>");
		for (my $k = 0; $k < $dispLine; $k++) {
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

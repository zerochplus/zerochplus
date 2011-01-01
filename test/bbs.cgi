#!/usr/bin/perl
#============================================================================================================
#
#	書き込み用CGI
#	bbs.cgi
#	-------------------------------------------------------------------------------------
#	2002.12.07 start
#	2003.02.06 共通部分をモジュール化
#	2004.04.10 システム変更に伴う改変
#
#============================================================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);

push @INC, 'perllib';

# CGIの実行結果を終了コードとする
exit(BBSCGI());

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub BBSCGI
{
	my (%SYS, $Page, $err);
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# 初期化に成功したら書き込み処理を開始
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		require './module/vara.pl';
		my $WriteAid = new VARA;
		$WriteAid->Init($SYS{'SYS'}, $SYS{'FORM'}, $SYS{'SET'}, undef, $SYS{'CONV'});
		
		# 書き込みに成功したら掲示板構成要素を更新する
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
		# スレッド作成画面表示
		if ($err == 9000) {
			PrintBBSThreadCreate(\%SYS, $Page);
			$err = 0;
		}
		# cookie確認画面表示
		elsif ($err == 9001) {
			PrintBBSCookieConfirm(\%SYS, $Page);
			$err = 0;
		}
		# 書き込み確認画面表示
		elsif ($err == 9002) {
			PrintBBSWriteConfirm(\%SYS, $Page);
			$err = 0;
		}
		# 携帯からのスレッド作成画面表示
		elsif ($err == 9003) {
			PrintBBSMobileThreadCreate($SYS{'SYS'}, $Page, $SYS{'SET'});
			$err = 0;
		}
		# エラー画面表示
		else {
			PrintBBSError(\%SYS, $Page, $err);
		}
	}
	
	# 結果の表示
	$Page->Flush('', 0, 0);
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi初期化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#	2010.08.23 windyakin ★
#	 -> クッキーとスレッド作成の順序を変更
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($Sys, $Page) = @_;
	
	# 使用モジュールの初期化
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
	
	# システム情報設定
	if ($Sys->{'SYS'}->Init()) {
		return 990;
	}
	
	$Sys->{'FORM'} = SAMWISE->new($Sys->{'SYS'}->Get('BBSGET')),
	
	# form情報設定
	$Sys->{'FORM'}->DecodeForm(1);
	
	# 夢が広がりんぐ
	$Sys->{'SYS'}->{'MainCGI'} = $Sys;
	
	# ホスト情報設定(DNS逆引き)
	$ENV{'REMOTE_HOST'} = $Sys->{'CONV'}->GetRemoteHost() unless ($ENV{'REMOTE_HOST'});
	$Sys->{'FORM'}->Set('HOST', $ENV{'REMOTE_HOST'});
	
	$Sys->{'SYS'}->Set('ENCODE', 'Shift_JIS');
	$Sys->{'SYS'}->Set('BBS', $Sys->{'FORM'}->Get('bbs', ''));
	$Sys->{'SYS'}->Set('KEY', $Sys->{'FORM'}->Get('key', ''));
	$Sys->{'SYS'}->Set('AGENT', $Sys->{'CONV'}->GetAgentMode($ENV{'HTTP_USER_AGENT'}));
	$Sys->{'SYS'}->Set('KOYUU', $ENV{'REMOTE_HOST'});
	
	# 携帯の場合は機種情報を設定
	if ($Sys->{'SYS'}->Get('AGENT') !~ /^[0P]$/) {
		my $product = GetProductInfo($Sys->{'CONV'}, $ENV{'HTTP_USER_AGENT'}, $ENV{'REMOTE_HOST'});
		
		if (! defined  $product) {
			return 950;
		}
		else {
			$Sys->{'SYS'}->Set('KOYUU', $product);
		}
	}
	
	# SETTING.TXTの読み込み
	if (! $Sys->{'SET'}->Load($Sys->{'SYS'})) {
		return 999;
	}
	
	# 携帯からのスレッド作成フォーム表示
	# $Sys->{'SYS'}->Equal('AGENT', 'O') && 
	if ($Sys->{'FORM'}->Equal('mb', 'on') && ! $Sys->{'FORM'}->IsExist('time')) {
		return 9003;
	}
	
	# form情報にkeyが存在したらレス書き込み
	if ($Sys->{'FORM'}->IsExist('key'))	{ $Sys->{'SYS'}->Set('MODE', 2); }
	else								{ $Sys->{'SYS'}->Set('MODE', 1); }
	
	# スレッド作成モードでMESSAGEが無い：スレッド作成画面
	if ($Sys->{'SYS'}->Equal('MODE', 1)) {
		if (! $Sys->{'FORM'}->IsExist('MESSAGE')) {
			return 9000;
		}
		$Sys->{'FORM'}->Set('key', time);
		$Sys->{'SYS'}->Set('KEY', $Sys->{'FORM'}->Get('key'));
	}
	
	# cookieの存在チェック(PCのみ)
	if (! $Sys->{'SYS'}->Equal('AGENT', 'O')) {
		if ($Sys->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
			# 環境変数取得失敗
			return 9001	if (!$Sys->{'COOKIE'}->Init());
			
			# 名前欄cookie
			if ($Sys->{'SET'}->Equal('BBS_NAMECOOKIE_CHECK', 'checked')
				&& ! $Sys->{'COOKIE'}->IsExist('NAME')) {
				return 9001;
			}
			# メール欄cookie
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
#	bbs.cgiスレッド作成ページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
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
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print("<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\" \"http://www.w3.org/TR/html4/loose.dtd\">\n");
	$Page->Print("<html lang=\"ja\">\n");
	$Page->Print("<head>\n");
	$Page->Print(' <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">'."\n\n");
	$Caption->Print($Page, undef);
	$Page->Print(" <title>$title</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>タグ出力
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
	# 看板画像表示あり
	if ($image ne '') {
		# 看板画像からのリンクあり
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$image\"></a><br>");
		}
		# 看板画像にリンクはなし
		else {
			$Page->Print("<img src=\"$image\" border=\"0\"><br>");
		}
	}
	$Page->Print("</div>");

	# ヘッダテーブルの表示
	$Caption->Load($Sys->{'SYS'}, 'HEAD');
	$Caption->Print($Page, $SET);
	
	# スレッド作成フォームの表示
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
  <b>スレッド新規作成</b><br>
  <center>
  <form method="POST" action="./bbs.cgi">
  <input type="hidden" name="bbs" value="$bbs"><input type="hidden" name="time" value="$tm">
  <table border="0">
   <tr>
    <td align="left">
    タイトル：<input type="text" name="subject" size="25">　<input type="submit" value="新規スレッド作成"><br>
    名前：<input type="text" name="FROM" size="19" value="$name">
    E-mail<font size="1">（省略可）</font>：<input type="text" name="mail" size="19" value="$mail"><br>
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
#	bbs.cgiスレッド作成ページ(携帯)表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Page	THORIN
#	@param	$Set	ISILDUR
#	@return	なし
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
	$Page->Print("タイトル<br><input type=text name=subject><br>");
	$Page->Print("名前<br><input type=text name=FROM><br>");
	$Page->Print("メール<br><input type=text name=mail><br>");
	$Page->Print("<textarea name=MESSAGE></textarea><br>");
	$Page->Print("<input type=hidden name=bbs value=$bbs>");
	$Page->Print("<input type=hidden name=time value=$tm>");
	$Page->Print("<input type=hidden name=mb value=on>");
	$Page->Print("<input type=submit value=\"スレッド作成\">");
	$Page->Print("</form></body></html>");
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiクッキー確認ページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
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
	
	# cookie情報の出力
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

 <title>■ 書き込み確認 ■</title>

</head>
<!--nobanner-->
HTML
	
	# <body>タグ出力
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
<font size="4" color="#FF0000"><b>書きこみ＆クッキー確認</b></font>
<blockquote style="margin-top:4em;">
 名前： $name<br>
 E-mail： $mail<br>
 内容：<br>
 $msg<br>
</blockquote>

<div style="font-weight:bold;">
投稿確認<br>
・投稿者は、投稿に関して発生する責任が全て投稿者に帰すことを承諾します。<br>
・投稿者は、話題と無関係な広告の投稿に関して、相応の費用を支払うことを承諾します<br>
・投稿者は、投稿された内容について、掲示板運営者がコピー、保存、引用、転載等の利用することを許諾します。<br>
　また、掲示板運営者に対して、著作者人格権を一切行使しないことを承諾します。<br>
・投稿者は、掲示板運営者が指定する第三者に対して、著作物の利用許諾を一切しないことを承諾します。<br>
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
	
	# レス書き込みモードの場合はkeyを設定する
	if ($Sys->{'SYS'}->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $Form->Get('key'));
	}
	
	$Page->Print(<<HTML);
<input type="submit" value="上記全てを承諾して書き込む"><br>
</form>

<p>
変更する場合は戻るボタンで戻って書き直して下さい。
</p>

<p>
現在、荒らし対策でクッキーを設定していないと書きこみできないようにしています。<br>
<font size="2">(cookieを設定するとこの画面はでなくなります。)</font><br>
</p>

</body>
</html>
HTML
}

#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgi書き込み確認ページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
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
	<title>■ 書き込み確認 ■</title>
<META http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
</head>
<!--nobanner-->
HTML

	# <body>タグ出力
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
<font size="+1" color="#FF0000">書き込み確認。</font><br>
<br>
書き込みに関して様々なログ情報が記録されています。<br>
公序良俗に反したり、他人に迷惑をかける書き込みは控えて下さい<br>
<form method="POST" action="./subbbs.cgi">
タイトル：$subject<br>
名前：$name<br>
E-mail ： $mail<br>
内容：
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
	
	# レス書き込みモードの場合はkeyを設定する
	if ($Sys->{'SYS'}->Equal('MODE', 2)) {
		$Page->HTMLInput('hidden', 'key', $Form->Get('key'));
	}
	$Page->Print(<<HTML);
<br>
<br>
<input type="submit" value="全責任を負うことを承諾して書き込む"><br>
変更する場合は戻るボタンで戻って書き直して下さい。<br>
</form>
</body>
</html>
HTML
}


#------------------------------------------------------------------------------------------------------------
#
#	bbs.cgiジャンプページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($Sys, $Page) = @_;
	my ($SYS, $Form, $bbsPath);
	
	$SYS		= $Sys->{'SYS'};
	$Form		= $Sys->{'FORM'};
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	
	# 携帯用表示
	if ( $Form->Equal('mb', 'on') || $SYS->Equal('AGENT', 'O') ) {
		$bbsPath = $SYS->Get('CGIPATH').'/r.cgi/'.$Form->Get('bbs').'/'.$Form->Get('key').'/l10';
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>書き込み完了です<br>');
		$Page->Print("<a href=\"$bbsPath\">こちら</a>");
		$Page->Print("から掲示板へ戻ってください。\n");
	}
	# PC用表示
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
	<title>書きこみました。</title>
<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
<meta http-equiv="Refresh" content="5;URL=$bbsPath/">
</head>
<!--nobanner-->
<body>
書きこみが終わりました。<br>
<br>
画面を切り替えるまでしばらくお待ち下さい。<br>
<br>
<br>
<br>
<br>
<hr>
HTML
	
	}
	# 告知欄表示(表示させたくない場合はコメントアウトか条件を0に)
	if (0) {
		require './module/denethor.pl';
		my $BANNER = new DENETHOR;
		$BANNER->Load($SYS);
		$BANNER->Print($Page, 100, 0, $SYS->Get('AGENT'));
	}
	# デバッグ用表示
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
#	bbs.cgiエラーページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
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
#	携帯機種情報取得
#	-------------------------------------------------------------------------------------
#	@param	$oConv	GARADRIEL
#	@param	$agent	HTTP_USER_AGENT値
#	@return	個体識別番号
#
#	2010.08.14 windyakin ★
#	 -> 主要3キャリア+公式p2を取れるように変更
#
#------------------------------------------------------------------------------------------------------------
sub GetProductInfo
{
	my ($oConv, $agent, $host) = @_;
	my $product = undef;
	
	# docomo
	if ( $host =~ /\.docomo.ne.jp$/ ) {
		# $ENV{'HTTP_X_DCMGUID'} - 端末製造番号, 個体識別情報, ユーザID, iモードID
		$product = $ENV{'HTTP_X_DCMGUID'};
		$product =~ s/^X-DCMGUID: ([a-zA-Z0-9]+)$/$1/i;
	}
	# SoftBank
	elsif ( $host =~ /\.(?:jp-.|vodafone|softbank).ne.jp$/ ) {
		# USERAGENTに含まれる15桁の数字 - 端末シリアル番号
		$product = $agent;
		$product =~ s/.+\/SN([A-Za-z0-9]+)\ .+/$1/;
	}
	# au
	elsif ( $host =~ /\.ezweb.ne.jp$/ ) {
		# $ENV{'HTTP_X_UP_SUBNO'} - サブスクライバID, EZ番号
		$product = $ENV{'HTTP_X_UP_SUBNO'};
		$product =~ s/([A-Za-z0-9_]+).ezweb.ne.jp/$1/i;
	}
	# e-mobile(音声端末)
	elsif ( $host =~ /\.emobile.ad.jp$/ ) {
		# $ENV{'X-EM-UID'} - 
		$product = $ENV{'X-EM-UID'};
		$product =~ s/x-em-uid: (.+)/$1/i;
	}
	# 公式p2
	elsif ( $host =~ /(?:cw43|p202).razil.jp$/ ) {
		# $ENV{'HTTP_X_P2_CLIENT_HOST'} - (発言者のホスト)
		# $ENV{'HTTP_X_P2_CLIENT_IP'} - (発言者のIP)
		# $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} - (発言者の固体識別番号)
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


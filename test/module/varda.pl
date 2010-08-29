#============================================================================================================
#
#	bbs.cgi支援モジュール(VARDA)
#	varda.pl
#	---------------------------------------------
#	2003.02.06 start
#	2004.03.31 内容変更
#
#	ぜろちゃんねるプラス
#	2010.08.12 システム改変に伴う変更
#
#============================================================================================================
package	VARDA;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
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
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$Setting	ISILDUR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Setting) = @_;
	
	require './module/baggins.pl';
	require './module/galadriel.pl';
	require './module/denethor.pl';
	
	# 使用モジュールを設定
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
	
	# 情報の読み込み
	$this->{'THREADS'}->Load($Sys);
	$this->{'BANNER'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	生成されたら1を返す
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
	
	# CREATEモード、またはスレッドがindex表示範囲内の場合のみindexを更新する
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
#	i/index.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
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
	
	# 前準備
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
	
	# 全スレッドを取得
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	# HTMLヘッダの出力
	$Page->Print("<html><!--nobanner--><head><title>$title</title>");
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print("</head><body><center>$title</center>");
	
	# バナー表示
	$this->{'BANNER'}->Print($Page, 100, 1, 1);
	$Page->Print('<hr></center>');
	
	# スレッド分だけループをまわす
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
	
	# フッタ部分の出力
	$path = "$cgiPath/p.cgi?bbs=$bbs&st=$i";
	$Page->Print("<hr><a href=\"$cgiPath/bbs.cgi?bbs=$bbs&mobile=true\">");
	$Page->Print("スレッド作成</a> <a href=\"$path\">続き</a><hr></body></html>\n");
	
	# i/index.htmlに書き込み
	$path = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$path/i/index.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	subback.html生成
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#	2010.08.12 windyakin ★
#	 -> 告知欄表示が任意設定できるようになったので変更
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
	
	# 全スレッドを取得
	$Threads->GetKeySet('ALL', '', \@threadSet);
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# HTMLヘッダの出力
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title - スレッド一覧</title>\n\n");
	$Page->Print("</head>\n<body>\n\n");
	
	# バナー表示
	$this->{'BANNER'}->Print($Page, 100, 2, 0) if ($Sys->Get('BANNER'));
	
	$Page->Print("<div class=\"threads\">");
	$Page->Print("<small>\n");
	
	# スレッド分だけループをまわす
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
	
	# フッタ部分の出力
	$Page->Print(<<HTML);
</small>
</div>

<div align="right" style="margin-top:1em;">
<small><a href="./kako/index.html" target="_blank"><b>過去ログ倉庫はこちら</b></a></small>
</div>

<hr>

<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$version
</div>

</body>
</html>
HTML
	
	# subback.htmlに書き込み
	$path = $Sys->Get('BBSPATH') . "/$bbs";
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$path/subback.html");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(ヘッダ部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	なし
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
	
	# HTMLヘッダの出力
	$Page->Print(<<HEAD);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 
HEAD
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>$title</title>\n\n");
	
	# cookie用scriptの出力
	if ($this->{'SET'}->Equal('SUBBBS_CGI_ON', 1)) {
		require './module/radagast.pl';
		RADAGAST::Print(undef, $Page);
	}
	$Page->Print("</head>\n<!--nobanner-->\n");
	
	# <body>タグ出力
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
	
	# 看板画像表示あり
	if ($image ne '') {
		# 看板画像からのリンクあり
		if ($link ne '') {
			$Page->Print("<a href=\"$link\"><img src=\"$image\" border=\"0\" alt=\"$link\"></a></div>\n");
		}
		# 看板画像にリンクはなし
		else {
			$Page->Print("<img src=\"$image\" border=\"0\" alt\"$link\"></div>\n");
		}
	}
	
	# ヘッダテーブルの表示
	$Caption->Load($this->{'SYS'}, 'HEAD');
	$Caption->Print($Page, $this->{'SET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドメニュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page
#	@return	なし
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
	
	# バナーの表示
	$this->{'BANNER'}->Print($Page, 95, 0, 0);
	
	$Page->Print(<<MENU);

<a name="menu"></a>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$menuCol" style="margin:1.2em auto;" align="center">
 <tr>
  <td>
  <small>
MENU
	
	# スレッド分だけループをまわす
	foreach $key (@threadSet) {
		if (($i > $menuNum) || ($i > $max)) {
			last;
		}
		$name = $this->{'THREADS'}->Get('SUBJECT', $key);
		$res = $this->{'THREADS'}->Get('RES', $key);
		$path = $Conv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
		
		# プレビュースレッドの場合はプレビューへのリンクを貼る
		if ($i < $prevNum) {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i:</a> ");
			$Page->Print("<a href=\"#$i\">$name($res)</a>　\n");
		}
		else {
			$Page->Print("  <a href=\"$path\" target=\"body\">$i: $name($res)</a>　\n");
		}
		$i++;
	}
	$Page->Print(<<MENU);
  </small>
  <div align="right"><small><b><a href="./subback.html">スレッド一覧はこちら</a></b></small></div>
  </td>
 </tr>
</table>

MENU
	
	# サブバナーの表示(表示したら空行をひとつ挿入)
	if ($this->{'BANNER'}->PrintSub($Page)) {
		$Page->Print("\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドプレビュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintIndexPreview
{
	my ($this, $Page) = @_;
	my ($oDat, $oConv, @threadSet, $Plugin);
	my ($prevNum, $threadNum, $prevT, $nextT, $tblCol, $ttlCol);
	my ($basePath, $datPath, $cnt, $subject, $res, $key, $max);
	
	# 拡張機能ロード
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($this->{'SYS'});
	
	# 有効な拡張機能一覧を取得
	my (@pluginSet, @commands, $id, $count);
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	$count = 0;
	foreach $id (@pluginSet) {
		# タイプがread.cgiの場合はロードして実行
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
	
	# 前準備
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
		
		# ヘッダ部分の表示
		$Page->Print(<<THREAD);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <a name="$cnt"></a>
  <div align="right"><a href="#menu">■</a><a href="#$prevT">▲</a><a href="#$nextT">▼</a></div>
  <div style="font-weight:bold;margin-bottom:0.2em;">【$cnt:$res】<font size="+2" color="$ttlCol">$subject</font></div>
  <dl style="margin-top:0px;">
THREAD
		
		# プレビューの表示
		$datPath = "$basePath/dat/$key.dat";
		$oDat->Load($this->{'SYS'}, $datPath, 1);
		$this->{'SYS'}->Set('KEY', $key);
		PrintThreadPreviewOne($this, $Page, $oDat, \@commands);
		$oDat->Close();
		
		# フッタ部分の表示
		{
			my ($allPath, $lastPath, $numPath);
			
			$allPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '');
			$lastPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, 'l50');
			$numPath	= $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'), $key, '1-100');
			$Page->Print(<<KAKIKO);
    <div style="font-weight:bold;">
     <a href="$allPath">全部読む</a>
     <a href="$lastPath">最新50</a>
     <a href="$numPath">1-100</a>
     <a href="#top">板のトップ</a>
     <a href="./index.html">リロード</a>
    </div>
    </blockquote>
   </blockquote>
  </form>
  </td>
 </tr>
</table>

KAKIKO
			
		}
		
		# カウンタの更新
		$nextT++;
		$prevT++;
		$prevT = 1 if ($cnt == 1);
		$cnt++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(フッタ部分)
#	-------------------------------------------------------------------------------------
#	@param	$Page		
#	@param	$Caption	
#	@return	なし
#
#	2010.08.12 windyakin ★
#	 -> Samba値の表示
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
	
	# スレッド作成画面を別画面で表示
	if ($this->{'SET'}->Equal('BBS_PASSWORD_CHECK', 'checked')) {
		$Page->Print(<<FORM);
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tblCol" align="center">
 <tr>
  <td>
  <form method="POST" action="$cgiPath/bbs.cgi" style="margin:1.2em 0;">
  <input type="submit" value="新規スレッド作成画面へ"><br>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </form>
  </td>
 </tr>
</table>
FORM
	}
	# スレッド作成フォームはindexと同じ画面に表示
	else {
		$Page->Print(<<FORM);
<form method="POST" action="$cgiPath/bbs.cgi">
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="#CCFFCC" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td></td>
  <td nowrap>
  タイトル：<input type="text" name="subject" size="40"><input type="submit" value="新規スレッド作成"><br>
  名前：<input type="text" name="FROM" size="19"> E-mail：<input type="text" name="mail" size="19"><br>
  内容：<textarea rows="5" cols="60" name="MESSAGE"></textarea>
  <input type="hidden" name="bbs" value="$bbs">
  <input type="hidden" name="time" value="$tm">
  </td>
 </tr>
</table>
</form>
FORM
	}
	
	# footの表示
	$Caption->Load($this->{'SYS'}, 'FOOT');
	$Caption->Print($Page, $this->{'SET'});
	
	$Page->Print(<<FOOT);
<div style="margin-top:1.2em;">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">ぜろちゃんねる</a> <a href="http://zerochplus.sourceforge.jp/">プラス</a>
BBS.CGI - $ver (Perl)
+<a href="http://bbq.uso800.net/" target="_blank">BBQ</a>
+BBX
+<a href="http://spam-champuru.livedoor.com/dnsbl/" target="_blank">スパムちゃんぷるー</a>
+Samba24=$samba<br>
ページのおしまいだよ。。と</div>

FOOT
	
	$Page->Print("</body>\n</html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(スレッドプレビュー部分)
#	-------------------------------------------------------------------------------------
#	@param	$this	
#	@param	$Page	
#	@param	$oDat	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadPreviewOne
{
	my ($this, $Page, $oDat, $commands) = @_;
	my ($pDat, $contNum, $start, $end, $i, $cgiPath, $bbs, $tm, $key);
	
	# 前準備
	$contNum	= $this->{'SET'}->Get('BBS_CONTENTS_NUMBER');
	$cgiPath	= $this->{'SYS'}->Get('SERVER') . $this->{'SYS'}->Get('CGIPATH');
	$bbs		= $this->{'SYS'}->Get('BBS');
	$key		= $this->{'SYS'}->Get('KEY');
	$tm			= time;
	
	# 表示数の正規化
	($start, $end) = $this->{'CONV'}->RegularDispNum(
						$this->{'SYS'}, $oDat, 1, $contNum, $contNum);
	if ($start == 1) {
		$start++;
	}
	
	# 1の表示
	PrintResponse($this, $Page, $oDat, $commands, 1);
	# 残りの表示
	for ($i = $start ; $i <= $end ; $i++) {
		PrintResponse($this, $Page, $oDat, $commands, $i);
	}
	
	# 書き込みフォームの表示
	$Page->Print(<<KAKIKO);
  </dl>
  <form method="POST" action="$cgiPath/bbs.cgi">
   <blockquote>
   <input type="hidden" name="bbs" value="$bbs">
   <input type="hidden" name="key" value="$key">
   <input type="hidden" name="time" value="$tm">
   <input type="submit" value="書き込む" name="submit"> 
   名前：<input type="text" name="FROM" size="19">
   E-mail：<input type="text" name="mail" size="19"><br>
   <blockquote style="margin-top:0px;">
    <textarea rows="5" cols="64" name="MESSAGE"></textarea>
KAKIKO
	
}

#------------------------------------------------------------------------------------------------------------
#
#	index.html生成(レス表示部分)
#	-------------------------------------------------------------------------------------
#	@param	$this	
#	@param	$Page	
#	@param	$oDat	
#	@param	$n		
#	@return	なし
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
	
	# URLと引用個所の適応
	$oConv->ConvertURL($this->{'SYS'}, $this->{'SET'}, 0, \$elem[3]);
	$oConv->ConvertQuotation($this->{'SYS'}, \$elem[3], 0);
	
	# 拡張機能を実行
	$this->{'SYS'}->Set('_DAT_', \@elem);
	$this->{'SYS'}->Set('_NUM_', $n);
	foreach $command (@$commands) {
		$command->execute($this->{'SYS'}, undef, 8);
	}
	
	$Page->Print("   <dt>$n 名前：");
	
	# メール欄有り
	if ($elem[1] eq '') {
		$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>");
	}
	# メール欄無し
	else {
		$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>");
	}
	
	# 表示行数内ならすべて表示する
	if ($contLine <= $dispLine || $n == 1) {
		$Page->Print("：$elem[2]</dt>\n    <dd>$elem[3]<br><br></dd>\n");
	}
	# 表示行数を超えたら省略表示を付加する
	else {
		my (@dispBuff, $path, $k);
		
		@dispBuff = split(/<br>|<BR>/, $elem[3]);
		$path = $oConv->CreatePath($this->{'SYS'}, 0, $this->{'SYS'}->Get('BBS'),
											$this->{'SYS'}->Get('KEY'), "${n}n");
		
		$Page->Print("：$elem[2]</dt>\n    <dd>");
		for ($k = 0 ; $k < $dispLine ; $k++) {
			$Page->Print("$dispBuff[$k]<br>");
		}
		$Page->Print("<font color=\"green\">（省略されました・・全てを読むには");
		$Page->Print("<a href=\"$path\" target=\"_blank\">ここ</a>");
		$Page->Print("を押してください）</font><br><br></dd>\n");
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

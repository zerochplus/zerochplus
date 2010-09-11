#!/usr/bin/perl
#============================================================================================================
#
#	読み出し専用CGI
#	r.cgi
#	-------------------------------------------------------------------------------------
#	2004.04.08 システム改変に伴う新規作成
#
#============================================================================================================

use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);

# CGIの実行結果を終了コードとする
exit(ReadCGI());

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadCGI
{
	my (%SYS, $Page, $err);
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# 初期化・準備に成功したら内容表示
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		# ヘッダ表示
		PrintReadHead(\%SYS, $Page);
		
		# メニュー表示
		PrintReadMenu(\%SYS, $Page);
		
		# 内容表示
		PrintReadContents(\%SYS, $Page);
		
		# フッタ表示
		PrintReadFoot(\%SYS, $Page);
	}
	# 初期化に失敗したらエラー表示
	else {
		# 対象スレッドが見つからなかった場合は探索画面を表示する
		if ($err == 1003) {
			PrintReadSearch(\%SYS, $Page, $err);
		}
		# それ以外は通常エラー
		else {
			PrintReadError(\%SYS, $Page, $err);
		}
	}
	
	# 表示結果を出力
	$Page->Flush(0, 0, '');
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi初期化・前準備
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($pSYS, $Page) = @_;
	my (@elem, @regs, $path);
	
	# 各使用モジュールの生成と初期化
	require './module/melkor.pl';
	require './module/isildur.pl';
	require './module/gondor.pl';
	require './module/galadriel.pl';
	
	my ($oSYS, $oSET, $oCONV, $oDAT);
	
	$oSYS	= new MELKOR;
	$oSET	= new ISILDUR;
	$oCONV	= new GALADRIEL;
	$oDAT	= new ARAGORN;
	
	%$pSYS = (
		'SYS'	=> $oSYS,
		'SET'	=> $oSET,
		'CONV'	=> $oCONV,
		'DAT'	=> $oDAT,
		'PAGE'	=> $Page,
		'CODE'	=> 'sjis'
	);
	
	# システム初期化
	$pSYS->{'SYS'}->Init();
	
	# 夢が広がりんぐ
	$pSYS->{'SYS'}->{'MainCGI'} = $pSYS;
	
	# 起動パラメータの解析
	@elem = $pSYS->{'CONV'}->GetArgument(\%ENV);
	
	# BBS指定がおかしい
	if ($elem[0] eq '') {
		return 1001;
	}
	# スレッドキー指定がおかしい
	elsif ($elem[1] eq '' || $elem[1] =~ /[^0-9]/ || length($elem[1]) != 10) {
		return 1002;
	}
	
	# システム変数設定
	$pSYS->{'SYS'}->Set('MODE', 0);
	$pSYS->{'SYS'}->Set('BBS', $elem[0]);
	$pSYS->{'SYS'}->Set('KEY', $elem[1]);
	$pSYS->{'SYS'}->Set('AGENT', $elem[7]);
	
	$path = $pSYS->{'SYS'}->Get('BBSPATH') . "/$elem[0]/dat/$elem[1].dat";
	
	# datファイルの読み込みに失敗
	if ($pSYS->{'DAT'}->Load($pSYS->{'SYS'}, $path, 1) == 0) {
		return 1003;
	}
	$pSYS->{'DAT'}->Close();
	
	# 設定ファイルの読み込みに失敗
	if ($pSYS->{'SET'}->Load($pSYS->{'SYS'}) == 0) {
		return 1004;
	}
	
	# 表示開始終了位置の設定
	@regs = $pSYS->{'CONV'}->RegularDispNum(
				$pSYS->{'SYS'}, $pSYS->{'DAT'}, $elem[2], $elem[3], $elem[4]);
	$pSYS->{'SYS'}->SetOption($elem[2], $regs[0], $regs[1], $elem[5], $elem[6]);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiヘッダ出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadHead
{
	my ($Sys, $Page) = @_;
	my ($Caption, $Banner, $code, $title);
	
	require './module/denethor.pl';
	$Banner = new DENETHOR;
	$Banner->Load($Sys->{'SYS'});
	
	$code	= $Sys->{'CODE'};
	$title	= $Sys->{'DAT'}->GetSubject();
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="ja">
<head>
 
 <meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">
 <meta http-equiv="Cache-Control" content="no-cache">
 
 <title>$title</title>
 
</head>
<!--nobanner-->
HTML
	
	# <body>タグ出力
	{
		$Page->Print('<body>'."\n");
	}
	
	# バナー出力
	$Banner->Print($Page, 100, 2, 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiメニュー出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadMenu
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $bbs, $key, $baseBBS, $resNum);
	my ($pathBBS, $pathAll, $pathLast, $pathMenu, $pathNext, $pathPrev);
	
	# 前準備
	$oSYS		= $Sys->{'SYS'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$baseBBS	= $oSYS->Get('SERVER') . '/' . $bbs;
	$pathBBS	= $baseBBS . '/i/index.html';
	$pathAll	= $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, '1-10n');
	$pathLast	= $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, 'l10');
	$resNum		= $Sys->{'DAT'}->Size();
	
	# 前、次番号の取得
	{
		my ($st, $ed, $b1, $b2, $f1, $f2);
		
		$st = $oSYS->GetOption(2);
		$ed = $oSYS->GetOption(3);
		$b1 = ($st - 11 > 0) ? ($st - 11) : 1;
		$b2 = ($b1 == 1) ? 10 : ($b1 + 10);
		$f1 = ($ed + 1 < $resNum) ? ($ed + 1) : $resNum;
		$f2 = ($ed + 10 < $resNum) ? ($ed + 10) : $resNum;
		
		$pathNext = $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, "${f1}-${f2}n");
		$pathPrev = $Sys->{'CONV'}->CreatePath($oSYS, 1, $bbs, $key, "${b1}-${b2}n");
	}
	
	# メニューの表示
	$Page->Print("<a href=\"$pathBBS\" accesskey=\"5\">板</a>");
	$Page->Print("<a href=\"$pathAll\" accesskey=\"1\">1-</a>");
	$Page->Print("<a href=\"$pathPrev\" accesskey=\"4\">前</a>");
	$Page->Print("<a href=\"$pathNext\" accesskey=\"6\">次</a>");
	$Page->Print("<a href=\"$pathLast?guid=ON\" accesskey=\"3\">新</a>");
	$Page->Print("<a href=\"#res\" accesskey=\"7\">ﾚｽ</a>\n");
	
	# スレッドタイトル表示
	{
		my $title	= $Sys->{'DAT'}->GetSubject();
		my $ttlCol	= $Sys->{'SET'}->Get('BBS_SUBJECT_COLOR');
		$Page->Print("<hr>\n<font color=$ttlCol size=+1>$title</font><br>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi内容出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadContents
{
	my ($Sys, $Page) = @_;
	my ($work, @elem, $i);
	
	$work = $Sys->{'SYS'}->Get('OPTION');
	@elem = split(/\,/, $work);
	
	# 1表示フラグがTRUEで開始が1でなければ1を表示する
	if ($elem[3] == 0 && $elem[1] != 1) {
		PrintResponse($Sys, $Page, 1);
	}
	# 残りのレスを表示する
	for ($i = $elem[1] ; $i <= $elem[2] ; $i++) {
		PrintResponse($Sys, $Page, $i);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiフッタ出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadFoot
{
	my ($Sys, $Page) = @_;
	my ($oSYS, $Conv, $bbs, $key, $ver, $rmax, $pathNext, $pathPrev);
	
	# 前準備
	$oSYS		= $Sys->{'SYS'};
	$Conv		= $Sys->{'CONV'};
	$bbs		= $oSYS->Get('BBS');
	$key		= $oSYS->Get('KEY');
	$ver		= $oSYS->Get('VERSION');
	$rmax		= $oSYS->Get('RESMAX');
	
	# 前、次番号の取得
	{
		my ($st, $ed, $b1, $b2, $f1, $f2);
		
		$st = $oSYS->GetOption(2);
		$ed = $oSYS->GetOption(3);
		$b1 = ($st - 11 > 0) ? ($st - 11) : 1;
		$b2 = ($b1 == 1) ? 10 : ($b1 + 10);
		$f1 = ($ed + 1 < $rmax) ? ($ed + 1) : $rmax;
		$f2 = ($ed + 10 < $rmax) ? ($ed + 10) : $rmax;
		
		$pathNext = $Conv->CreatePath($oSYS, 1, $bbs, $key, "${f1}-${f2}n");
		$pathPrev = $Conv->CreatePath($oSYS, 1, $bbs, $key, "${b1}-${b2}n");
	}
	$Page->Print('<hr>');
	$Page->Print("<a href=\"$pathPrev\">前</a> ");
	$Page->Print("<a href=\"$pathNext\">次</a><hr><a name=res></a>");
	
	# 投稿フォームの表示
	# レス最大数を超えている場合はフォーム表示しない
	if ($rmax > $Sys->{'DAT'}->Size()) {
		my ($tm, $cgiPath);
		
		$tm			= time;
		$cgiPath	= $oSYS->Get('SERVER') . $oSYS->Get('CGIPATH');
		
		$Page->Print("<form method=\"POST\" action=\"$cgiPath/bbs.cgi?guid=ON\" utn>\n");
		$Page->Print("<input type=hidden name=bbs value=$bbs>");
		$Page->Print("<input type=hidden name=key value=$key>");
		$Page->Print("<input type=hidden name=time value=$tm>");
		$Page->Print("\n名前<br><input type=text name=\"FROM\"><br>");
		$Page->Print('E-mail<br><input type=text name="mail"><br>');
		$Page->Print('<textarea rows=3 wrap=off name="MESSAGE"></textarea>');
		$Page->Print('<br><input type=submit value="書き込む"><br>');
	}
	$Page->Print("<small>$ver</small></form></body></html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiレス表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($Sys, $Page, $n) = @_;
	my ($oSYS, $oConv, $pDat, @elem, $maxLen, $len);
	
	$oSYS	= $Sys->{'SYS'};
	$oConv	= $Sys->{'CONV'};
	$pDat	= $Sys->{'DAT'}->Get($n -1);
	@elem	= split(/<>/, $$pDat);
	$len	= length $elem[3];
	$maxLen	= $Sys->{'SET'}->Get('BBS_LINE_NUMBER');
	$maxLen	= int($maxLen * 5);
	
	# 表示範囲内か指定表示ならすべて表示する
	if ($oSYS->GetOption(5) == 1 || $len <= $maxLen) {
		$oConv->ConvertURL($oSYS, $Sys->{'SET'}, 1, \$elem[3]);
		$oConv->ConvertQuotation($oSYS, \$elem[3], 1);
	}
	# 表示範囲を超えていたら省略表示をする
	else {
		my ($bbs, $key, $path);
		
		$bbs		= $oSYS->Get('BBS');
		$key		= $oSYS->Get('KEY');
		$elem[3]	= $oConv->DeleteText(\$elem[3], $maxLen);
		$maxLen		= (($_ = $len - length($elem[3])) + 20 - ($_ % 20 || 20)) / 20;
		$path		= $oConv->CreatePath($oSYS, 1, $bbs, $key, "${n}n");
		
		$oConv->ConvertURL($oSYS, $Sys->{'SET'}, 1, \$elem[3]);
		$oConv->ConvertQuotation($oSYS, \$elem[3], 1);
		
		#if ($maxLen) {
			$elem[3] .= " <a href=\"$path\">省$maxLen</a>";
		#}
	}
	$Page->Print("<hr>[$n]$elem[0]</b>：$elem[2]<br>$elem[3]<br>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgi探索画面表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadSearch
{
	my ($Sys, $Page) = @_;
}

#------------------------------------------------------------------------------------------------------------
#
#	r.cgiエラー表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintReadError
{
	my ($Sys, $Page, $err) = @_;
	my $code;
	
	$code = 'Shift_JIS';
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>ＥＲＲＯＲ！！</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}


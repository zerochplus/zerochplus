#!/usr/bin/perl
#============================================================================================================
#
#	検索用CGI(まちがえてすみません)
#	search.cgi
#	-----------------------------------------------------
#	2003.11.22 star
#	2004.09.16 システム改変に伴う変更
#
#============================================================================================================

# CGIの実行結果を終了コードとする
exit(SearchCGI());

#------------------------------------------------------------------------------------------------------------
#
#	CGIメイン処理 - SearchCGI
#	------------------------------------------------
#	引　数：なし
#	戻り値：なし
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
	
	# 検索ワードがある場合は検索を実行する
	if	(!$Form->Equal('WORD','')){
		Search($Sys,$Form,$Page,$BBS);
	}
	PrintFoot($Page);
	$Page->Flush(0,0,'');
}

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダ出力 - PrintHead
#	------------------------------------------------
#	引　数：なし
#	戻り値：なし
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
	
	# バナーの読み込み
	require('./module/denethor.pl');
	$Banner = new DENETHOR;
	$Banner->Load($Sys);
	
	$Page->Print("Content-type: text/html\n\n<html><!--nobanner--><head>");
	$Page->Print("<style type=\"text/css\">.res{background-color:yellow;font-");
	$Page->Print("weight:bold;}</style><title>検索＠0ch</title><body ");
	$Page->Print("bgcolor=#aaaaff background=\"./datas/default_bac.gif\">");
	$Page->Print("<form action=\"./search.cgi\" method=\"POST\">");
	$Page->Print("<table border=1 cellspacing=7 cellpadding=3 width=95% ");
	$Page->Print("bgcolor=#ccffcc align=center><tr><td><font size=+1 face=");
	$Page->Print("Arial><b>検索＠0chスクリプ㌧</b></font><center><br><table ");
	$Page->Print("boder=0><tr><td>検索モード</td><td><select name=MODE>\n");
	
	if	($sMODE eq 'ALL'){
		$Page->Print("<option value=ALL selected>鯖内全検索</option>\n");
		$Page->Print("<option value=BBS>BBS指定全検索</option>\n");
		$Page->Print("<option value=THREAD>スレッド指定全検索</option>\n");
	}
	elsif	($sMODE eq 'BBS' || $sMODE eq ''){
		$Page->Print("<option value=ALL>鯖内全検索</option>\n");
		$Page->Print("<option value=BBS selected>BBS指定全検索</option>\n");
		$Page->Print("<option value=THREAD>スレッド指定全検索</option>\n");
	}
	elsif	($sMODE eq 'THREAD'){
		$Page->Print("<option value=ALL>鯖内全検索</option>\n");
		$Page->Print("<option value=BBS>BBS指定全検索</option>\n");
		$Page->Print("<option value=THREAD selected>スレッド指定全検索</option>\n");
	}
	$Page->Print("</select></td></tr>\n");
	$Page->Print("<tr><td>指定BBS</td><td><select name=BBS>");
	
	# BBSセットの取得
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
	$Page->Print("<tr><td>指定スレッドキー</td><td><input type=text size=20 ");
	$Page->Print("name=KEY value=\"$sKEY\"></td></tr><tr><td>検索ワード</td>");
	$Page->Print("<td><input type=text size=40 name=WORD value=\"$sWORD\">");
	$Page->Print("</td></tr><tr><td>検索種別</td><td>");
	$Page->Print("<input type=checkbox name=TYPE value=1 $cTYPE[0]>名前検索<br>");
	$Page->Print("<input type=checkbox name=TYPE value=4 $cTYPE[2]>ID・日付検索<br>");
	$Page->Print("<input type=checkbox name=TYPE value=2 $cTYPE[1]>本文検索<br>");
	$Page->Print("</td></tr><tr><td colspan=2 align=right><hr>\n");
	$Page->Print("<input type=submit value=\"　検索　\"></td></tr></table><br>");
	$Page->Print("</td></tr></table><br>");
	
	$Banner->Print($Page,95,0,0);
}

#------------------------------------------------------------------------------------------------------------
#
#	フッタ出力 - PrintHead
#	------------------------------------------------
#	引　数：なし
#	戻り値：なし
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
#	検索結果出力 - Search
#	------------------------------------------------
#	引　数：なし
#	戻り値：なし
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
	
	# 検索オブジェクトの設定と検索の実行
	eval{
		$Search->Create($Sys,$Mode,$Type,$Form->Get('BBS'),$Form->Get('KEY'));
		$Search->Run($Form->Get('WORD'));
	};
	if	($@ ne ''){
		PrintSystemError($Page,$@);
		return;
	}
	
	# 検索結果セット取得
	$Result = $Search->GetResultSet();
	$n		= @$Result;
	$base	= $Sys->Get('BBSPATH');
	$word	= $Form->Get('WORD');
	
	PrintResultHead($Page,$n);
	
	# 検索ヒットが1件以上あり
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
	# 検索ヒット無し
	else{
		PrintNoHit($Page);
	}
	
	PrintResultFoot($Page);
}

#------------------------------------------------------------------------------------------------------------
#
#	検索結果ヘッダ出力 - PrintResultHead
#	------------------------------------------------
#	引　数：Page : 出力モジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultHead
{
	my		($Page,$n) = @_;
	
	$Page->Print("<br><table border=1 cellspacing=7 cellpadding=3 width=95%");
	$Page->Print(" bgcolor=#efefef align=center><tr><td><dl><b><small>");
	$Page->Print("【ヒット数：$n】</b></small><font size=+2 color=red>検索結果");
	$Page->Print("</font><br>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	検索結果内容出力
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResult
{
	my		($Page,$BBS,$Conv,$n,$base,$pResult) = @_;
	my		($name,@bbsSet);
	
	$BBS->GetKeySet('DIR',$$pResult[0],\@bbsSet);
	
	if	(@bbsSet > 0){
		$name = $BBS->Get('NAME',$bbsSet[0]);
		
		$Page->Print("<dt>$n 名前：<b>");
		if	($$pResult[4] eq ''){
			$Page->Print("<font color=forestgreen>$$pResult[3]</font>");
		}
		else{
			$Page->Print("<a href=\"mailto:$$pResult[4]\">$$pResult[3]</a>");
		}
		$Page->Print("</b>：$$pResult[5]</dt><dd>$$pResult[6]<br><hr>");
		$Page->Print("<a target=_blank href=\"$base/$$pResult[0]/\">【$name】</a>");
		$Page->Print("<a target=_blank href=\"./read.cgi/$$pResult[0]/$$pResult[1]/\">【スレッド】</a>");
		$Page->Print("<a target=_blank href=\"./read.cgi/$$pResult[0]/$$pResult[1]/$$pResult[2]\">【レス】</a>");
		$Page->Print("<br><br></dd>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	検索結果フッタ出力
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintResultFoot
{
	my		($Page) = @_;
	
	$Page->Print("</dl></td></tr></table>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	NoHit出力
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoHit
{
	my		($Page) = @_;
	
	$Page->Print("<dt>0 名前：<font color=forestgreen><b>検索エンジソ\＠");
	$Page->Print("ぜろちゃんねる</b></font>：No Hit</dt><dd><br><br>");
	$Page->Print("＿|￣|○　一件もヒットしませんでした。。<br><br></dd>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	システムエラー出力
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$msg	エラーメッセージ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemError
{
	my		($Page,$msg) = @_;
	
	$Page->Print("<br><table border=1 cellspacing=7 cellpadding=3 width=95%");
	$Page->Print(" bgcolor=#efefef align=center><tr><td><dl><b><small>");
	$Page->Print("【ヒット数：0】</b></small><font size=+2 color=red>システムエラー");
	$Page->Print("</font><br>\n");
	$Page->Print("<dt>0 名前：<font color=forestgreen><b>検索エンジソ\＠");
	$Page->Print("ぜろちゃんねる</b></font>：System Error</dt><dd><br><br>");
	$Page->Print("$msg<br><br></dd>\n");
	$Page->Print("</dl></td></tr></table>\n");
}

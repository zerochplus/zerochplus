#!/usr/bin/perl
#============================================================================================================
#
#	携帯用ページ表示専用CGI
#	p.cgi
#	---------------------------------------------
#	2004.09.15 システム改変に伴う新規作成
#
#============================================================================================================

# CGIの実行結果を終了コードとする
exit(PCGI());

#------------------------------------------------------------------------------------------------------------
#
#	p.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PCGI
{
	my		($Sys,$Thread,$Set,$Page,$Form,$Conv);
	my		(%pPath,@tList);
	my		($base,$max);
	
	require('./module/baggins.pl');
	require('./module/isildur.pl');
	require('./module/galadriel.pl');
	require('./module/melkor.pl');
	require('./module/samwise.pl');
	require('./module/thorin.pl');
	
	$Threads	= new BILBO;
	$Conv		= new GALADRIEL;
	$Set		= new ISILDUR;
	$Sys		= new MELKOR;
	$Form		= new SAMWISE;
	$Page		= new THORIN;
	
	# urlからパスを解析
	GetPathData(\%pPath);
	
	# モジュールの初期化
	$Form->DecodeForm(1);
	$Sys->Init();
	$Sys->Set('BBS',$pPath{'bbs'});
	$Set->Load($Sys);
	$Threads->Load($Sys);
	
	# r.cgiベースパスの設定
	$base = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	$base = $base . "/r.cgi/$pPath{'bbs'}/";
	
	# スレッドリストの作成
	if	($Form->Equal('method','')){
		# 検索無し
		$max = CreateThreadList($Threads,$Set,\@tList,\%pPath,'');
	}
	else{
		# 検索あり
		$max = CreateThreadList($Threads,$Set,\@tList,\%pPath,$Form->Get('word'));
	}
	
	# ページの出力
	PrintHead($Page,$Sys,$Set,$pPath{'st'},$max);
	PrintThreadList($Page,$Sys,$Conv,\@tList,$base);
	PrintFoot($Page,$Sys,$Set,$pPath{'st'},$max);
	
	# 画面へ出力
	$Page->Flush(0,0,"");
}

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダ部分出力
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$num	表示数
#	@param	$last	最終数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my		($Page,$Sys,$Set,$start,$last) = @_;
	my		($path,$st,$bbs,$code);
	
	$path	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . '/p.cgi';
	$bbs	= $Sys->Get('BBS');
	$start	= $start - $Set->Get('BBS_MAX_MENU_THREAD');
	$st		= $start < 1 ? 1 : $start;
	$code	= 'Shift_JIS';
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><!--nobanner--><head><title>i-mode 0ch</title>');
	$Page->Print('<meta http-equiv=Content-Type content="text/html;charset=' . $code . '">');
	$Page->Print('</head>');
	$Page->Print("<body><form action=\"$path/$bbs\" method=\"POST\" utn>");
	
	if	($Sys->Get('PATHKIND')){
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$st\">前</a> ");
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$last\">次</a><br>\n");
	}
	else{
		$Page->Print("<a href=\"$path/$bbs/$st\">前</a> ");
		$Page->Print("<a href=\"$path/$bbs/$last\">次</a><br>\n");
	}
	$Page->Print("<input type=hidden name=method value=search>");
	$Page->Print("<input type=text name=word><input type=submit value=\"検索\"><hr>");
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドリストの表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$Conv	GALADRIEL
#	@param	$pList	リスト格納バッファ
#	@param	$base	ベースパス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadList
{
	my		($Page,$Sys,$Conv,$pList,$bpath) = @_;
	my		(@elem,$path);
	
	foreach	(@{$pList}){
		@elem = split(/<>/,$_);
		$path = $Conv->CreatePath($Sys,1,$Sys->Get('BBS'),$elem[1],'l10');
		$Page->Print("$elem[0]: <a href=\"$path\">$elem[2]($elem[3])</a><br>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	フッタ部分出力 - PrintHead
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$num	表示数
#	@param	$last	最終数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my		($Page,$Sys,$Set,$start,$last) = @_;
	my		($ver,$path,$st,$bbs);
	
	$path	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . '/p.cgi';
	$bbs	= $Sys->Get('BBS');
	$ver	= $Sys->Get('VERSION');
	$start	= $start - $Set->Get('BBS_MAX_MENU_THREAD');
	$st		= $start < 1 ? 1 : $start;
	
	if	($Sys->Get('PATHKIND')){
		$Page->Print("<hr><a href=\"$path?bbs=$bbs&st=$st\">前</a> ");
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$last\">次</a><br>\n");
	}
	else{
		$Page->Print("<hr><a href=\"$path/$bbs/$st\">前</a> ");
		$Page->Print("<a href=\"$path/$bbs/$last\">次</a><br>\n");
	}
	$Page->Print("<hr>$ver</form></body></html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	パスデータ解析
#	-------------------------------------------------------------------------------------
#	@param	$pHash	ハッシュの参照
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetPathData
{
	my		($pHash) = @_;
	my		(@plist,$var,$val);
	
	if	($ENV{'PATH_INFO'}){
		@plist = split(/\//,$ENV{'PATH_INFO'});
		$pHash->{'bbs'} = $plist[1];
		$pHash->{'st'} = $plist[2];
	}
	else{
		@plist = split(/&/,$ENV{'QUERY_STRING'});
		foreach	(@plist){
			($var,$val) = split(/=/,$_);
			$pHash->{$var} = $val;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドリストの生成
#	-------------------------------------------------------------------------------------
#	@param	$Threads	BILBO
#	@param	$Set		ISILDUR
#	@param	$pList		結果格納用配列
#	@param	$pHash		情報ハッシュ
#	@param	$keyWord	検索ワード
#	@return	リスト最後のインデクス
#
#------------------------------------------------------------------------------------------------------------
sub CreateThreadList
{
	my		($Threads,$Set,$pList,$pHash,$keyWord) = @_;
	my		(@threadSet,$threadNum,$max,$start);
	my		($key,$subject,$res,$i);
	
	# スレッド一覧の取得
	$Threads->GetKeySet('ALL','',\@threadSet);
	$threadNum = @threadSet;
	
	# 検索ワード無しの場合は開始からスレッド表示最大数までのリストを作成
	if	($keyWord eq ''){
		$start	= $pHash->{'st'} > $threadNum ? $threadNum : $pHash->{'st'};
		$start	= $start < 1 ? 1 : $start;
		$max	= $start + $Set->Get('BBS_MAX_MENU_THREAD');
		$max	= $max < $threadNum ? $max : $threadNum + 1;
		$max	= $max == $start ? $max + 1 : $max;
		for	($i = $start;$i < $max;$i++){
			$key		= $threadSet[$i - 1];
			$subject	= $Threads->Get('SUBJECT',$key);
			$res		= $Threads->Get('RES',$key);
			$data		= "$i<>$key<>$subject<>$res";
			push(@{$pList},$data);
		}
	}
	# 検索ワードがある場合は検索ワードを含む全てのスレッドのリストを作成
	else{
		my	$nextNum = 1;
		$max	= $threadNum;
		$start	= 1;
		for	($i = $start;$i < $max + 1;$i++){
			$key		= $threadSet[$i - 1];
			$subject	= $Threads->Get('SUBJECT',$key);
			if	($subject =~ /$keyWord/){
				$res	= $Threads->Get('RES',$key);
				$data	= "$i<>$key<>$subject<>$res";
				push(@{$pList},$data);
				$nextNum = $i;
			}
		}
		$max = $nextNum + 1;
	}
	return $max;
}


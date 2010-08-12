#============================================================================================================
#
#	管理CGIベースモジュール
#	sauron.pl
#	---------------------------------------------------------------------------
#	2003.10.12 start
#
#============================================================================================================
package	SAURON;

require('./module/thorin.pl');

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my		$this = shift;
	my		($obj,@MnuStr,@MnuUrl);
	
	$obj = {
		'SYS'		=> undef,														# MELKOR保持
		'FORM'		=> undef,														# SAMWISE保持
		'INN'		=> undef,														# THORIN保持
		'MNUSTR'	=> \@MnuStr,													# 機能リスト文字列
		'MNUURL'	=> \@MnuUrl,													# 機能リストURL
		'MNUNUM'	=> 0															# 機能リスト数
	};
	bless $obj,$this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	オブジェクト生成 - Create
#	-------------------------------------------------------------------------------------
#	引　数：$M : MELKORモジュール
#			$S : SAMWISEモジュール
#	戻り値：THORINモジュール
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my		$this = shift;
	my		($Sys,$Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= new THORIN;
	$this->{'MNUNUM'}	= 0;
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューの設定 - SetMenu
#	-------------------------------------------------------------------------------------
#	引　数：$str : 表示文字列
#			$url : ジャンプURL
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my		$this = shift;
	my		($str,$url) = @_;
	
	push(@{$this->{'MNUSTR'}},$str);
	push(@{$this->{'MNUURL'}},$url);
	
	$this->{'MNUNUM'} ++;
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ出力 - Print
#	-------------------------------------------------------------------------------------
#	引　数：$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my		$this = shift;
	my		($ttl,$mode) = @_;
	my		($Tad,$Tin,$TPlus);
	
	$Tad	= new THORIN;
	$Tin	= $this->{'INN'};
	
	PrintHTML($Tad,$ttl);															# HTMLヘッダ出力
	PrintCSS($Tad,$this->{'SYS'});													# CSS出力
	PrintHead($Tad,$ttl,$mode);														# ヘッダ出力
	PrintList($Tad,$this->{'MNUNUM'},$this->{'MNUSTR'},$this->{'MNUURL'});			# 機能リスト出力
	PrintInner($Tad,$Tin,$ttl);														# 機能内容出力
	PrintCommonInfo($Tad,$this->{'FORM'});
	PrintFoot($Tad,$this->{'FORM'}->Get('UserName'),$this->{'SYS'}->Get('VERSION'));# フッタ出力
	
	$Tad->Flush(0,0,'');															# 画面出力
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ出力(メニューリストなし) - PrintNoList
#	-------------------------------------------------------------------------------------
#	引　数：$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoList
{
	my		$this = shift;
	my		($ttl,$mode) = @_;
	my		($Tad,$Tin);
	
	$Tad = new THORIN;
	$Tin = $this->{'INN'};
	
	PrintHTML($Tad,$ttl);															# HTMLヘッダ出力
	PrintCSS($Tad,$this->{'SYS'});													# CSS出力
	PrintHead($Tad,$ttl,$mode);														# ヘッダ出力
	PrintInner($Tad,$Tin,$ttl);														# 機能内容出力
	PrintFoot($Tad,'NONE',$this->{'SYS'}->Get('VERSION'));	# フッタ出力
	
	$Tad->Flush(0,0,'');															# 画面出力
}

#------------------------------------------------------------------------------------------------------------
#
#	HTMLヘッダ出力 - PrintHTML
#	-------------------------------------------
#	引　数：$T   : THORINモジュール
#			$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHTML
{
	my		($Page,$ttl) = @_;
	
	$Page->Print("Content-type: text/html\n\n<html><head><title>ぜろちゃんねる管理");
	$Page->Print(" - [ $ttl ]</title>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	スタイルシート出力 - PrintCSS
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCSS
{
	my		($Page,$Sys) = @_;
	my		($data);
	
	$data = $Sys->Get('DATA');
	
	$Page->Print('<meta http-equiv=Content-Type content="text/html;charset=Shift_JIS">');
	$Page->Print("<link rel=stylesheet href=\".$data/admin.css\" type=text/css>");
	$Page->Print("<script language=javascript src=\".$data/admin.js\"></script>");
	$Page->Print("</head><!--nobanner-->\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	ページヘッダ出力 - PrintHead
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#			$ttl : ページタイトル
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my		($Page,$ttl,$mode) = @_;
	my		($common);
	
	$common = '<a href="javascript:DoSubmit';
	
	$Page->Print("<body>");
	$Page->Print("<form name=ADMIN action=\"./admin.cgi\" method=\"POST\">");
	$Page->Print("<div class=\"MainMenu\" align=right>");
	
	# システム管理メニュー
	if	($mode == 1){
		$Page->Print("$common('sys.top','DISP','NOTICE');\">トップ</a> | ");
		$Page->Print("$common('sys.bbs','DISP','LIST');\">掲示板</a> | ");
		$Page->Print("$common('sys.user','DISP','LIST');\">ユーザー</a> | ");
		$Page->Print("$common('sys.cap','DISP','LIST');\">キャップ</a> | ");
		$Page->Print("$common('sys.setting','DISP','INFO');\">システム設定</a> | ");
		$Page->Print("$common('sys.edit','DISP','BANNER_PC');\">各種編集</a> | ");
	}
	# 掲示板管理メニュー
	elsif	($mode == 2){
		$Page->Print("$common('bbs.thread','DISP','LIST');\">スレッド</a> | ");
		$Page->Print("$common('bbs.pool','DISP','LIST');\">プール</a> | ");
		$Page->Print("$common('bbs.kako','DISP','LIST');\">過去ログ</a> | ");
		$Page->Print("$common('bbs.setting','DISP','SETINFO');\">掲示板設定</a> | ");
		$Page->Print("$common('bbs.edit','DISP','HEAD');\">各種編集</a> | ");
		$Page->Print("$common('bbs.user','DISP','LIST');\">管理グループ</a> | ");
		$Page->Print("$common('bbs.cap','DISP','LIST');\">キャップグループ</a> | ");
		$Page->Print("$common('bbs.log','DISP','INFO');\">ログ閲覧</a> | ");
	}
	# スレッド管理メニュー
	elsif	($mode == 3){
		$Page->Print("$common('thread.res','DISP','LIST');\">レス一覧</a> | ");
		$Page->Print("$common('thread.del','DISP','LIST');\">削除レス一覧</a> ");
	}
	$Page->Print("<a $common('login','','');\">ログオフ</a>");
	$Page->Print("</div>\n<div class=\"MainHead\" align=right>0ch BBS System Manager</div>");
	$Page->Print("<table cellspacing=0 width=100%><tr style=\"height:400px\">");
}

#------------------------------------------------------------------------------------------------------------
#
#	機能リスト出力 - PrintList
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#			$str : 機能タイトル配列
#			$url : 機能URL配列
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintList
{
	my		($Page,$n,$str,$url) = @_;
	my		($i);
	
	$Page->Print("<td align=center valign=top class=\"Content\">");
	$Page->Print("<table width=95% cellspacing=0><tr><td class=\"FunctionList\">\n");
	
	for	($i = 0;$i < $n;$i++){
		$strURL = $$url[$i];
		$strTXT = $$str[$i];
		if	($strURL eq ''){
			$Page->Print("<font color=gray>$strTXT</font>\n");
			if($strTXT ne '<hr>'){
				$Page->Print('<br>');
			}
		}
		else{
			$Page->Print("<a href=\"javascript:DoSubmit($$url[$i]);\" >");
			$Page->Print("$$str[$i]</a><br>\n");
		}
	}
	$Page->Print("</td></tr></table></td>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	機能内容出力 - PrintInner
#	-------------------------------------------
#	引　数：$Page1 : THORINモジュール(MAIN)
#			$Page2 : THORINモジュール(内容)
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintInner
{
	my		($Page1,$Page2,$ttl) = @_;
	
	$Page1->Print("<td width=80% valign=top class=\"Function\">\n");
	$Page1->Print("<div class=\"FuncTitle\">$ttl</div><br>");
	$Page1->Merge($Page2);
	$Page1->Print("</td>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	共通情報出力 - PrintCommonInfo
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintCommonInfo
{
	my		($Page,$Form) = @_;
	
	$Page->HTMLInput('hidden','MODULE',"");
	$Page->HTMLInput('hidden','MODE',"");
	$Page->HTMLInput('hidden','MODE_SUB',"");
	
	$Page->HTMLInput('hidden','UserName',$Form->Get('UserName'));
	$Page->HTMLInput('hidden','PassWord',$Form->Get('PassWord'));
}

#------------------------------------------------------------------------------------------------------------
#
#	フッタ出力 - PrintFoot
#	-------------------------------------------
#	引　数：$Page   : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my		($Page,$user,$ver) = @_;
	
	$Page->Print("</tr></table>");
	$Page->Print("<div class=\"MainFoot\">");
	$Page->Print("Copyright 2001 - 2005 0ch BBS : Loggin User - <b>$user</b><br>");
	$Page->Print("Build Version:<b>$ver</b>");
	$Page->Print("</div></form></body></html>");
}

#------------------------------------------------------------------------------------------------------------
#
#	完了画面の出力
#	-------------------------------------------------------------------------------------
#	@param	$processName	処理名
#	@param	$pLog	処理ログ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintComplete
{
	my		$this = shift;
	my		($processName,$pLog) = @_;
	my		($Page,$text);
	
	$Page = $this->{'INN'};
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td><b>$processNameを正常に完了しました。</b><br><br>");
	$Page->Print("<small>処理ログ<hr><blockquote>");
	
	# ログの表示
	foreach	$text (@$pLog){
		$Page->Print("$text<br>\n");
	}
	$Page->Print("</blockquote><hr></small></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	エラーの表示
#	-------------------------------------------------------------------------------------
#	@param	$pLog	ログ用
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintError
{
	my		$this = shift;
	my		($pLog) = @_;
	my		($Page,$ecode);
	
	$Page = $this->{'INN'};
	
	# エラーコードの抽出
	$ecode = pop(@$pLog);
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td><br><font color=red><b>");
	$Page->Print("ERROR:$ecode<hr><blockquote>\n");
	
	if		($ecode == 1000){
		$Page->Print("本機能の処理を実行する権限がありません。");
	}
	elsif	($ecode == 1001){
		$Page->Print("入力必須項目が空欄になっています。");
	}
	elsif	($ecode == 1002){
		$Page->Print("設定項目に規定外の文字が使用されています。");
	}
	elsif	($ecode == 2000){
		$Page->Print("掲示板ディレクトリの作成に失敗しました。<br>");
		$Page->Print("パーミッション、または既に同名の掲示板が作成されていないかを確認してください。");
	}
	elsif	($ecode == 2001){
		$Page->Print("SETTING.TXTの生成に失敗しました。");
	}
	elsif	($ecode == 2002){
		$Page->Print("掲示板構\成要素の生成に失敗しました。");
	}
	elsif	($ecode == 2003){
		$Page->Print("過去ログ初期情報の生成に失敗しました。");
	}
	elsif	($ecode == 2004){
		$Page->Print("掲示板情報の更新に失敗しました。");
	}
	else{
		$Page->Print("不明なエラーが発生しました。");
	}
	
	# エラーログがあれば出力する
	if	(@$pLog){
		$Page->Print('<hr>');
		foreach	(@$pLog){
			$Page->Print("$_<br>\n");
		}
	}
	
	$Page->Print("</blockquote><hr></b></font>");
	$Page->Print("</td></tr></table>");
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

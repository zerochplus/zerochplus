#============================================================================================================
#
#	システム管理 - 設定 モジュール
#	sys.setting.pl
#	---------------------------------------------------------------------------
#	2004.02.14 start
#
#	ぜろちゃんねるプラス
#	2010.08.12 設定項目追加による改変
#
#============================================================================================================
package	MODULE;

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
	my ($obj, @LOG);
	
	$obj = {
		'LOG' => \@LOG
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $BASE, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE, $pSys);
	
	if ($subMode eq 'INFO') {														# システム情報画面
		PrintSystemInfo($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'BASIC') {													# 基本設定画面
		PrintBasicSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PERMISSION') {												# パーミッション設定画面
		PrintPermissionSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'LIMITTER') {												# リミッタ設定画面
		PrintLimitterSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'OTHER') {													# その他設定画面
		PrintOtherSetting($Page, $Sys, $Form);
	}
=pod
	elsif ($subMode eq 'PLUS') {													# ぜろプラスオリジナル
		PrintPlusSetting($Page, $Sys, $Form);
	}
=cut
	elsif ($subMode eq 'VIEW') {													# 表示設定
		PrintPlusViewSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'SEC') {														# 規制設定
		PrintPlusSecSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'PLUGIN') {													# 拡張機能設定画面
		PrintPluginSetting($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# システム設定完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('システム設定処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# システム設定失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'), 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($subMode, $err);
	
	# 管理情報を登録
	$Sys->Set('ADMIN', $pSys);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'BASIC') {														# 基本設定
		$err = FunctionBasicSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'PERMISSION') {												# パーミッション設定
		$err = FunctionPermissionSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'LIMITTER') {												# 制限設定
		$err = FunctionLimitterSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'OTHER') {													# その他設定
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
=pod
	elsif ($subMode eq 'PLUS') {													# ぜろプラスオリジナル
		$err = FunctionPlusSetting($Sys, $Form, $this->{'LOG'});
	}
=cut
	elsif ($subMode eq 'VIEW') {													# 表示設定
		$err = FunctionPlusViewSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SEC') {														# 規制設定
		$err = FunctionPlusSecSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'SET_PLUGIN') {												# 拡張機能情報設定
		$err = FunctionPluginSetting($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE_PLUGIN') {											# 拡張機能情報更新
		$err = FunctionPluginUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys) = @_;
	
	$Base->SetMenu('情報', "'sys.setting','DISP','INFO'");
	
	# システム管理権限のみ
	if ($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'}, 0, '*')) {
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('基本設定', "'sys.setting','DISP','BASIC'");
		$Base->SetMenu('パーミッション設定', "'sys.setting','DISP','PERMISSION'");
		$Base->SetMenu('リミッタ設定', "'sys.setting','DISP','LIMITTER'");
		$Base->SetMenu('その他設定', "'sys.setting','DISP','OTHER'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('表示設定', "'sys.setting','DISP','VIEW'");
		$Base->SetMenu('規制設定', "'sys.setting','DISP','SEC'");
		$Base->SetMenu('<hr>', '');
		$Base->SetMenu('拡張機能\設定', "'sys.setting','DISP','PLUGIN'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	システム情報画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintSystemInfo
{
	my ($Page, $SYS, $Form) = @_;
	
	$SYS->Set('_TITLE', '0ch+ Administrator Information');
	
	$Page->Print("<br><b>0ch+ BBS - Administrator Script</b>");
}

#------------------------------------------------------------------------------------------------------------
#
#	システム基本設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBasicSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($server, $cgi, $bbs, $info, $data, $common);
	
	$SYS->Set('_TITLE', 'System Base Setting');
	
	$server	= $SYS->Get('SERVER');
	$cgi	= $SYS->Get('CGIPATH');
	$bbs	= $SYS->Get('BBSPATH');
	$info	= $SYS->Get('INFO');
	$data	= $SYS->Get('DATA');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','BASIC');\"";
	$server = 'http://' . $ENV{'SERVER_NAME'}	if ($server eq '');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">稼動サーバ</td>");
	$Page->Print("<td><input type=text size=60 name=SERVER value=\"$server\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">CGI設置ディレクトリ（相対パス）</td>");
	$Page->Print("<td><input type=text size=60 name=CGIPATH value=\"$cgi\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">掲示板配置ディレクトリ（相対パス）</td>");
	$Page->Print("<td><input type=text size=60 name=BBSPATH value=\"$bbs\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">システム情報ディレクトリ（相対パス）</td>");
	$Page->Print("<td><input type=text size=60 name=INFO value=\"$info\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">システムデータディレクトリ（相対パス）</td>");
	$Page->Print("<td><input type=text size=60 name=DATA value=\"$data\" ></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPermissionSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($datP, $txtP, $logP, $admP, $stopP, $admDP, $bbsDP, $logDP);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Permission Setting');
	
	$datP	= sprintf("%o", $SYS->Get('PM-DAT'));
	$txtP	= sprintf("%o", $SYS->Get('PM-TXT'));
	$logP	= sprintf("%o", $SYS->Get('PM-LOG'));
	$admP	= sprintf("%o", $SYS->Get('PM-ADM'));
	$stopP	= sprintf("%o", $SYS->Get('PM-STOP'));
	$admDP	= sprintf("%o", $SYS->Get('PM-ADIR'));
	$bbsDP	= sprintf("%o", $SYS->Get('PM-BDIR'));
	$logDP	= sprintf("%o", $SYS->Get('PM-LDIR'));
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','PERMISSION');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。<br>");
	$Page->Print("<b>（8進値で設定すること）</b></td></tr>\n");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">datファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_DAT value=\"$datP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">テキストファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_TXT value=\"$txtP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ログファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG value=\"$logP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理ファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN value=\"$admP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">停止スレッドファイルパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_STOP value=\"$stopP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_ADMIN_DIR value=\"$admDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">掲示板ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_BBS_DIR value=\"$bbsDP\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">ログ保存ディレクトリパーミッション</td>");
	$Page->Print("<td><input type=text size=10 name=PERM_LOG_DIR value=\"$logDP\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	制限設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.08.12 windyakin ★
#	 -> システム変更に伴う設定項目の追加
#
#------------------------------------------------------------------------------------------------------------
sub PrintLimitterSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@vSYS, $common);
	
	$SYS->Set('_TITLE', 'System Limitter Setting');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','LIMITTER');\"";
	$vSYS[0] = $SYS->Get('RESMAX');
	$vSYS[1] = $SYS->Get('SUBMAX');
	$vSYS[2] = $SYS->Get('ANKERS');
	$vSYS[3] = $SYS->Get('ERRMAX');
	$vSYS[4] = $SYS->Get('HISMAX');
	$vSYS[5] = $SYS->Get('ADMMAX');
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">1掲示板のsubject最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=SUBMAX value=\"$vSYS[1]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1スレッドのレス最大数</td>");
	$Page->Print("<td><input type=text size=10 name=RESMAX value=\"$vSYS[0]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">1レスのアンカー最大数(0で無制限)</td>");
	$Page->Print("<td><input type=text size=10 name=ANKERS value=\"$vSYS[2]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">エラーログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=ERRMAX value=\"$vSYS[3]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">書き込み履歴最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=HISMAX value=\"$vSYS[4]\" ></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">管理操作ログ最大保持数</td>");
	$Page->Print("<td><input type=text size=10 name=ADMMAX value=\"$vSYS[5]\" ></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintOtherSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($urlLink, $linkSt, $linkEd, $pathKind, $headText, $headUrl, $FastMode, $BBSGET);
	my ($linkChk, $pathInfo, $pathQuery, $fastMode, $bbsget);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Other Setting');
	
	$urlLink	= $SYS->Get('URLLINK');
	$linkSt		= $SYS->Get('LINKST');
	$linkEd		= $SYS->Get('LINKED');
	$pathKind	= $SYS->Get('PATHKIND');
	$headText	= $SYS->Get('HEADTEXT');
	$headUrl	= $SYS->Get('HEADURL');
	$FastMode	= $SYS->Get('FASTMODE');
	$BBSGET		= $SYS->Get('BBSGET');
	
	$linkChk	= ($urlLink eq 'TRUE' ? 'checked' : '');
	$fastMode	= ($FastMode == 1 ? 'checked' : '');
	$pathInfo	= ($pathKind == 0 ? 'checked' : '');
	$pathQuery	= ($pathKind == 1 ? 'checked' : '');
	$bbsget		= ($BBSGET == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','OTHER');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">ヘッダ関連</td></tr>\n");
	$Page->Print("<tr><td>ヘッダ下部に表\示するテキスト</td>");
	$Page->Print("<td><input type=text size=60 name=HEADTEXT value=\"$headText\" ></td></tr>\n");
	$Page->Print("<tr><td>上記テキストに貼\るリンクのURL</td>");
	$Page->Print("<td><input type=text size=60 name=HEADURL value=\"$headUrl\" ></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">本文中のURL</td></tr>\n");
	$Page->Print("<tr><td colpan=2><input type=checkbox name=URLLINK $linkChk value=on>");
	$Page->Print("本文中URLへの自動リンク</td>");
	$Page->Print("<tr><td colspan=2><b>以下自動リンクOFF時のみ有効</b></td></tr>\n");
	$Page->Print("<tr><td>　　リンク禁止時間帯</td>");
	$Page->Print("<td><input type=text size=2 name=LINKST value=\"$linkSt\" >時 ～ ");
	$Page->Print("<input type=text size=2 name=LINKED value=\"$linkEd\" >時</td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">動作モード(read.cgi)</td></tr>\n");
	$Page->Print("<tr><td>PATH種別</td>");
	$Page->Print("<td><input type=radio name=PATHKIND value=\"0\" $pathInfo>PATHINFO　");
	$Page->Print("<input type=radio name=PATHKIND value=\"1\" $pathQuery>QUERYSTRING</td></tr>\n");
	
	$Page->Print("<tr><td colpan=2><input type=checkbox name=FASTMODE $fastMode value=on>");
	$Page->Print("高速書き込みモード</td>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">bbs.cgiのGETメソッド</td></tr>\n");
	$Page->Print("<tr><td>bbs.cgiでGETメソ\ッドを使用する</td>");
	$Page->Print("<td><input type=checkbox name=BBSGET $bbsget value=on></td></tr>\n");
	
	
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定画面の表示(ぜろちゃんねるプラスオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusViewSetting
{
	my ($Page, $SYS, $Form) = @_;
	my ($Banner, $Counter, $Prtext, $Prlink, $Msec);
	my ($banner, $msec);
	my ($common);
	
	$SYS->Set('_TITLE', 'System View Setting');
	
	$Banner		= $SYS->Get('BANNER');
	$Counter	= $SYS->Get('COUNTER');
	$Prtext		= $SYS->Get('PRTEXT');
	$Prlink		= $SYS->Get('PRLINK');
	$Msec		= $SYS->Get('MSEC');
	
	$banner		= ($Banner == 1 ? 'checked' : '');
	$msec		= ($Msec == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','VIEW');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">Read.cgi関連</td></tr>\n");
	$Page->Print("<tr><td>ofuda.ccのアカウント名を入力</td>");
	$Page->Print("<td><input type=text size=60 name=COUNTER value=\"$Counter\"></td></tr>\n");
	$Page->Print("<tr><td>PR欄の表\示文字列</td>");
	$Page->Print("<td><input type=text size=60 name=PRTEXT value=\"$Prtext\"></td></tr>\n");
	$Page->Print("<tr><td>PR欄のリンクURL</td>");
	$Page->Print("<td><input type=text size=60 name=PRLINK value=\"$Prlink\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">告知欄表\示</td></tr>\n");
	$Page->Print("<tr><td>index.html以外の告知欄を表\示する</td>");
	$Page->Print("<td><input type=checkbox name=BANNER $banner value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">msec表\示</td></tr>\n");
	$Page->Print("<tr><td>ミリ秒まで表\示する</small></td>");
	$Page->Print("<td><input type=checkbox name=MSEC $msec value=on></td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定画面の表示(ぜろちゃんねるプラスオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub PrintPlusSecSetting
{
	
	my ($Page, $SYS, $Form) = @_;
	my ($Kakiko, $Samba, $isSamba, $Houshi, $Trip12, $BBQ, $BBX, $SpamCh);
	my ($kakiko, $trip12, $issamba, $bbq, $bbx, $spamch);
	my ($common);
	
	$SYS->Set('_TITLE', 'System Regulation Setting');
	
	$Kakiko		= $SYS->Get('KAKIKO');
	$Samba		= $SYS->Get('SAMBATM');
	$Trip12		= $SYS->Get('TRIP12');
	$BBQ		= $SYS->Get('BBQ');
	$BBX		= $SYS->Get('BBX');
	$SpamCh		= $SYS->Get('SPAMCH');

	$kakiko		= ($Kakiko == 1 ? 'checked' : '');
	$trip12		= ($Trip12 == 1 ? 'checked' : '');
	$bbq		= ($BBQ == 1 ? 'checked' : '');
	$bbx		= ($BBX == 1 ? 'checked' : '');
	$spamch		= ($SpamCh == 1 ? 'checked' : '');
	
	$common = "onclick=\"DoSubmit('sys.setting','FUNC','SEC');\"";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2>各項目を設定して[設定]ボタンを押してください。</td></tr>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">２重かきこですか？？</td></tr>\n");
	$Page->Print("<tr><td>同じIPからの書き込みの文字数が変化しない場合規制する</td>");
	$Page->Print("<td><input type=checkbox name=KAKIKO $kakiko value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">連続投稿規制</td></tr>\n");
	$Page->Print("<tr><td>連続投稿規制秒数を入力(0で規制無効)</td>");
	$Page->Print("<td><input type=text size=60 name=SAMBATM value=\"$Samba\"></td></tr>\n");
	$Page->Print("<tr><td>※Sambaの設定が優先されます。Sambaの設定は板別です</td>");
#	$Page->Print("<tr><td>Sambaにする</td>");
#	$Page->Print("<td><input type=checkbox name=ISSAMBA $issamba value=on></td></tr>\n");
#	$Page->Print("<tr><td>Samba規制分数を入力(0で規制無効)</td>");
#	$Page->Print("<td><input type=text size=60 name=HOUSHI value=\"$Houshi\"></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">新仕様トリップ</td></tr>\n");
	$Page->Print("<tr><td>新仕様トリップ(12桁 =SHA-1)を有効にする<br><small>要Digest::SHA1モジュール</small></td>");
	$Page->Print("<td><input type=checkbox name=TRIP12 $trip12 value=on></td></tr>\n");
	
	$Page->Print("<tr bgcolor=silver><td colspan=2 class=\"DetailTitle\">DNSBL設定</td></tr>\n");
	$Page->Print("<tr><td colspan=2>適用するDNSBLにチェックをいれてください<br>\n");
	$Page->Print("<input type=checkbox name=BBQ $bbq value=on>");
	$Page->Print("<a href=\"http://bbq.uso800.net/\" target=\"_blank\">BBQ</a>\n");
	$Page->Print("<input type=checkbox name=BBX $bbx value=on>BBX\n");
	$Page->Print("<input type=checkbox name=SPAMCH $spamch value=on>");
	$Page->Print("<a href=\"http://spam-champuru.livedoor.com/dnsbl/\" target=\"_blank\">スパムちゃんぷるー</a>\n");
	$Page->Print("</td></tr>\n");
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　設定　\" $common></td></tr>\n");
	$Page->Print("</table>");
	
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintPluginSetting
{
	my ($Page, $SYS, $Form) = @_;
	my (@pluginSet, $num, $common, $Plugin);
	
	$SYS->Set('_TITLE', 'System Plugin Setting');
	$common = "onclick=\"DoSubmit('sys.setting','FUNC'";
	
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($SYS);
	$num = $Plugin->GetKeySet('ALL', '', \@pluginSet);
	
	# 拡張機能が存在する場合は有効・無効設定画面を表示
	if ($num > 0) {
		my ($id, $file, $class, $name, $expl, $valid);
		
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td colspan=4>有効にする機能\にチェックを入れてください。</td></tr>\n");
		$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
		$Page->Print("<tr>");
		$Page->Print("<td class=\"DetailTitle\">Function Name</td>");
		$Page->Print("<td class=\"DetailTitle\">Explanation</td>");
		$Page->Print("<td class=\"DetailTitle\">File</td>");
		$Page->Print("<td class=\"DetailTitle\">Class Name</td></tr>\n");
		
		foreach $id (@pluginSet) {
			$file = $Plugin->Get('FILE', $id);
			$class = $Plugin->Get('CLASS', $id);
			$name = $Plugin->Get('NAME', $id);
			$expl = $Plugin->Get('EXPL', $id);
			$valid = $Plugin->Get('VALID', $id) == 1 ? 'checked' : '';
			$Page->Print("<tr><td><input type=checkbox name=PLUGIN_VALID value=$id $valid>");
			$Page->Print(" $name</td><td>$expl</td><td>$file</td><td>$class</td></tr>\n");
		}
		$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
		$Page->Print("<tr><td colspan=4 align=right>");
		$Page->Print("<input type=button value=\"　設定　\" $common,'SET_PLUGIN');\"> ");
	}
	else {
		$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td><b>プラグインは存在しません。</b></td></tr>\n");
		$Page->Print("<tr><td><hr></td></tr>\n");
		$Page->Print("<tr><td align=right>");
	}
	$Page->Print("<input type=button value=\"　更新　\" $common,'UPDATE_PLUGIN');\">");
	$Page->Print("</td></tr>");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	基本設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBasicSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	# 入力チェック
	{
		my @inList = ('SERVER', 'CGIPATH', 'BBSPATH', 'INFO', 'DATA');
		if (! $Form->IsInput(\@inList)) {
			return 1001;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('SERVER', $Form->Get('SERVER'));
	$SYSTEM->Set('CGIPATH', $Form->Get('CGIPATH'));
	$SYSTEM->Set('BBSPATH', $Form->Get('BBSPATH'));
	$SYSTEM->Set('INFO', $Form->Get('INFO'));
	$SYSTEM->Set('DATA', $Form->Get('DATA'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 サーバ：' . $Form->Get('SERVER');
		push @$pLog, '　　　 CGIパス：' . $Form->Get('CGIPATH');
		push @$pLog, '　　　 掲示板パス：' . $Form->Get('BBSPATH');
		push @$pLog, '　　　 管理データフォルダ：' . $Form->Get('INFO');
		push @$pLog, '　　　 基本データフォルダ：' . $Form->Get('DATA');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPermissionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('PM-DAT', oct($Form->Get('PERM_DAT')));
	$SYSTEM->Set('PM-TXT', oct($Form->Get('PERM_TXT')));
	$SYSTEM->Set('PM-LOG', oct($Form->Get('PERM_LOG')));
	$SYSTEM->Set('PM-ADM', oct($Form->Get('PERM_ADMIN')));
	$SYSTEM->Set('PM-STOP', oct($Form->Get('PERM_STOP')));
	$SYSTEM->Set('PM-ADIR', oct($Form->Get('PERM_ADMIN_DIR')));
	$SYSTEM->Set('PM-BDIR', oct($Form->Get('PERM_BBS_DIR')));
	$SYSTEM->Set('PM-LDIR', oct($Form->Get('PERM_LOG_DIR')));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 datパーミッション：' . $Form->Get('PERM_DAT');
		push @$pLog, '　　　 txtパーミッション：' . $Form->Get('PERM_TXT');
		push @$pLog, '　　　 logパーミッション：' . $Form->Get('PERM_LOG');
		push @$pLog, '　　　 管理ファイルパーミッション：' . $Form->Get('PERM_ADMIN');
		push @$pLog, '　　　 停止スレッドパーミッション：' . $Form->Get('PERM_STOP');
		push @$pLog, '　　　 管理DIRパーミッション：' . $Form->Get('PERM_ADMIN_DIR');
		push @$pLog, '　　　 掲示板DIRパーミッション：' . $Form->Get('PERM_BBS_DIR');
		push @$pLog, '　　　 ログDIRパーミッション：' . $Form->Get('PERM_LOG_DIR');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	制限値設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitterSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('RESMAX', $Form->Get('RESMAX'));
	$SYSTEM->Set('SUBMAX', $Form->Get('SUBMAX'));
	$SYSTEM->Set('ANKERS', $Form->Get('ANKERS'));
	$SYSTEM->Set('ERRMAX', $Form->Get('ERRMAX'));
	$SYSTEM->Set('HISMAX', $Form->Get('HISMAX'));
	$SYSTEM->Set('ADMMAX', $Form->Get('ADMMAX'));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ 基本設定';
		push @$pLog, '　　　 subject最大数：' . $Form->Get('SUBMAX');
		push @$pLog, '　　　 レス最大数：' . $Form->Get('RESMAX');
		push @$pLog, '　　　 アンカー最大数：' . $Form->Get('ANKERS');
		push @$pLog, '　　　 エラーログ最大数：' . $Form->Get('ERRMAX');
		push @$pLog, '　　　 書き込み履歴最大数：' . $Form->Get('HISMAX');
		push @$pLog, '　　　 管理操作ログ最大数：' . $Form->Get('ADMMAX');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('HEADTEXT', $Form->Get('HEADTEXT'));
	$SYSTEM->Set('HEADURL', $Form->Get('HEADURL'));
	$SYSTEM->Set('URLLINK', ($Form->Equal('URLLINK', 'on') ? 'TRUE' : 'FALSE'));
	$SYSTEM->Set('LINKST', $Form->Get('LINKST'));
	$SYSTEM->Set('LINKED', $Form->Get('LINKED'));
	$SYSTEM->Set('PATHKIND', $Form->Get('PATHKIND'));
	$SYSTEM->Set('FASTMODE', ($Form->Equal('FASTMODE', 'on') ? 1 : 0));
	$SYSTEM->Set('BBSGET', ($Form->Equal('BBSGET', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '■ その他設定';
		push @$pLog, '　　　 ヘッダテキスト：' . $SYSTEM->Get('HEADTEXT');
		push @$pLog, '　　　 ヘッダURL：' . $SYSTEM->Get('HEADURL');
		push @$pLog, '　　　 URL自動リンク：' . $SYSTEM->Get('URLLINK');
		push @$pLog, '　　　 　開始時間：' . $SYSTEM->Get('LINKST');
		push @$pLog, '　　　 　終了時間：' . $SYSTEM->Get('LINKED');
		push @$pLog, '　　　 PATH種別：' . $SYSTEM->Get('PATHKIND');
		push @$pLog, '　　　 高速モード：' . $SYSTEM->Get('FASTMODE');
		push @$pLog, '　　　 bbs.cgiのGETメソ\ッド：' . $SYSTEM->Get('BBSGET');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定(ぜろちゃんねるプラスオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusViewSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('COUNTER', $Form->Get('COUNTER'));
	$SYSTEM->Set('PRTEXT', $Form->Get('PRTEXT'));
	$SYSTEM->Set('PRLINK', $Form->Get('PRLINK'));
	$SYSTEM->Set('BANNER', ($Form->Equal('BANNER', 'on') ? 1 : 0));
	$SYSTEM->Set('MSEC', ($Form->Equal('MSEC', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	# ログの設定
	{
		push @$pLog, '　　　 カウンターアカウント：' . $SYSTEM->Get('COUNTER');
		push @$pLog, '　　　 PR欄表\示文字列：' . $SYSTEM->Get('PRTEXT');
		push @$pLog, '　　　 PR欄リンクURL：' . $SYSTEM->Get('PRLINK');
		push @$pLog, '　　　 バナー表\示：' . $SYSTEM->Get('BANNER');
		push @$pLog, '　　　 ミリ秒表示：' . $SYSTEM->Get('MSEC');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定(ぜろちゃんねるプラスオリジナル)
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#	2010.09.08 windyakin ★
#	 -> 表示設定と規制設定の分離
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusSecSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/melkor.pl';
	$SYSTEM = MELKOR->new;
	$SYSTEM->Init();
	
	$SYSTEM->Set('KAKIKO', ($Form->Equal('KAKIKO', 'on') ? 1 : 0));
	$SYSTEM->Set('SAMBATM', $Form->Get('SAMBATM'));
#	$SYSTEM->Set('ISSAMBA', ($Form->Equal('ISSAMBA', 'on') ? 1 : 0));
#	$SYSTEM->Set('HOUSHI', $Form->Get('HOUSHI'));
	$SYSTEM->Set('TRIP12', ($Form->Equal('TRIP12', 'on') ? 1 : 0));
	$SYSTEM->Set('BBQ', ($Form->Equal('BBQ', 'on') ? 1 : 0));
	$SYSTEM->Set('BBX', ($Form->Equal('BBX', 'on') ? 1 : 0));
	$SYSTEM->Set('SPAMCH', ($Form->Equal('SPAMCH', 'on') ? 1 : 0));
	
	$SYSTEM->Save();
	
	{
		push @$pLog, '　　　 2重カキコ規制：' . $SYSTEM->Get('KAKIKO');
		push @$pLog, '　　　 連続投稿規制秒数：' . $SYSTEM->Get('SAMBATM');
#		push @$pLog, '　　　 Samba規制：' . $SYSTEM->Get('ISSAMBA');
#		push @$pLog, '　　　 Samba規制分数：' . $SYSTEM->Get('HOUSHI');
		push @$pLog, '　　　 12桁トリップ：' . $SYSTEM->Get('TRIP12');
		push @$pLog, '　　　 BBQ：' . $SYSTEM->Get('BBQ');
		push @$pLog, '　　　 BBX：' . $SYSTEM->Get('BBX');
		push @$pLog, '　　　 スパムちゃんぷるー：' . $SYSTEM->Get('SPAMCH');
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my (@pluginSet, @validSet, $id, $valid);
	
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	@validSet = $Form->GetAtArray('PLUGIN_VALID');
	
	foreach $id (@pluginSet) {
		$valid = 0;
		foreach (@validSet) {
			if ($_ eq $id) {
				$valid = 1;
				last;
			}
		}
		push @$pLog, $Plugin->Get('NAME', $id) . ' を' . ($valid ? '有効' : '無効') . 'に設定しました。';
		$Plugin->Set($id, 'VALID', $valid);
	}
	$Plugin->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Plugin);
	
	# 権限チェック
	{
		my $SEC = $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID = $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 0, '*')) == 0) {
			return 1000;
		}
	}
	require './module/athelas.pl';
	$Plugin = ATHELAS->new;
	
	# 情報の更新と保存
	$Plugin->Load($Sys);
	$Plugin->Update();
	$Plugin->Save($Sys);
	
	# ログの設定
	{
		push @$pLog, '■ プラグイン情報の更新';
		push @$pLog, '　プラグイン情報の更新を完了しました。';
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

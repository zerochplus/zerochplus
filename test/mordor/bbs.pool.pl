#============================================================================================================
#
#	掲示板管理 - POOLスレッド モジュール
#	bbs.pool.pl
#	---------------------------------------------------------------------------
#	2004.02.07 start
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
		'LOG'	=> \@LOG
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
	my ($subMode, $BASE, $BBS, $Page);
	
	require './mordor/sauron.pl';
	require './module/nazguls.pl';
	$BASE = SAURON->new;
	$BBS = $pSys->{'AD_BBS'};
	
	# 掲示板情報の読み込みとグループ設定
	if (! defined $BBS){
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE);
	
	if ($subMode eq 'LIST') {														# スレッド一覧画面
		PrintThreadList($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'REPARE') {													# スレッド復帰確認画面
		PrintThreadRepare($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'DELETE') {													# スレッド削除確認画面
		PrintThreadDelete($Page, $Sys, $Form);
	}
	elsif ($subMode eq 'COMPLETE') {												# スレッド処理完了画面
		$Sys->Set('_TITLE', 'Process Complete');
		$BASE->PrintComplete('過去ログ処理', $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# スレッド処理失敗画面
		$Sys->Set('_TITLE', 'Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	# 掲示板情報を設定
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS')), 2);
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
	my ($subMode, $err, $BBS);
	
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	
	# 管理情報を登録
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$Sys->Set('ADMIN', $pSys);
	$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if ($subMode eq 'REPARE') {														# 復帰
		$err = FunctionThreadRepare($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'DELETE') {													# 削除
		$err = FunctionThreadDelete($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATE') {													# 情報更新
		$err = FunctionUpdateSubject($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'UPDATEALL') {												# 全更新
		$err = FunctionUpdateSubjectAll($Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'CREATE') {													# 過去ログ生成
		$err = FunctionCreateLogs($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"POOL($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"POOL($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
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
	my ($Base) = @_;
	
	$Base->SetMenu('POOLスレッド一覧', "'bbs.pool','DISP','LIST'");
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('システム管理へ戻る', "'sys.bbs','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadList
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadSet, $ThreadNum, $key, $res, $subj, $i);
	my ($dispSt, $dispEd, $dispNum);
	my ($common, $common2, $n, $Threads, $id);
	
	$SYS->Set('_TITLE', 'Pool Thread List');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	$Threads->GetKeySet('ALL', '', \@threadSet);
	$ThreadNum = $Threads->GetNum();
	
	# 表示数の設定
	$dispNum	= ($Form->Get('DISPNUM') eq '' ? 10 : $Form->Get('DISPNUM'));
	$dispSt		= ($Form->Get('DISPST') eq '' ? 0 : $Form->Get('DISPST'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $ThreadNum ? $ThreadNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('bbs.pool','DISP','LIST');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST', " . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST', ");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td colspan=2 align=right>");
	$Page->Print("表\示数<input type=text name=DISPNUM size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"　表\示　\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\">　</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	# 権限取得
	my ($isRepare, $isDelete, $isUpdate, $isCreate);
	
	$isRepare = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 4, $SYS->Get('BBS'));
	$isDelete = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 5, $SYS->Get('BBS'));
	$isUpdate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 6, $SYS->Get('BBS'));
	$isCreate = $SYS->Get('ADMIN')->{'SECINFO'}->IsAuthority($SYS->Get('ADMIN')->{'USER'}, 7, $SYS->Get('BBS'));
	
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$id		= $threadSet[$i];
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td><input type=checkbox name=THREADS value=$id></td>");
		$Page->Print("<td>$subj</td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
	}
	$common		= "onclick=\"DoSubmit('bbs.pool','DISP'";
	$common2	= "onclick=\"DoSubmit('bbs.pool','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"　更新　\" $common2,'UPDATE')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\" 全更新 \" $common2,'UPDATEALL')\"> ")	if ($isUpdate);
	$Page->Print("<input type=button value=\"　復帰　\" $common,'REPARE')\"> ")		if ($isRepare);
	$Page->Print("<input type=button value=\"　削除　\" $common,'DELETE')\"> ")		if ($isDelete);
	$Page->Print("<input type=button value=\"過去ログ化\" $common2,'CREATE')\"> ")	if ($isCreate);
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	
	$Page->HTMLInput('hidden', 'DISPST', '');
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドDAT落ち復帰確認表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadRepare
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadList, $Threads, $id, $subj, $res, $common);
	
	$SYS->Set('_TITLE', 'Pool Thread Repare');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>以下のPOOLスレッドを復帰します。</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.pool','FUNC','REPARE')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("※注：DAT落ちしたスレッドは[DAT落ちスレッド]画面で復帰できます。</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=right>");
	$Page->Print("<input type=button value=\"　復帰　\" onclick=\"$common\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド削除確認表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadDelete
{
	my ($Page, $SYS, $Form) = @_;
	my (@threadList, $Threads, $id, $subj, $res, $common);
	
	$SYS->Set('_TITLE', 'Pool Thread Delete');
	
	require './module/baggins.pl';
	$Threads = FRODO->new;
	
	$Threads->Load($SYS);
	@threadList = $Form->GetAtArray('THREADS');
	
	$Page->Print("<br><center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=3>以下のスレッドを削除します。</td></tr>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:250\">Thread Title</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:100\">Thread Key</td>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:50\">Res</td></tr>\n");
	
	foreach $id (@threadList) {
		$subj	= $Threads->Get('SUBJECT', $id);
		$res	= $Threads->Get('RES', $id);
		
		$Page->Print("<tr><td>$subj</a></td>");
		$Page->Print("<td align=center>$id</td><td align=center>$res</td></tr>\n");
		$Page->HTMLInput('hidden', 'THREADS', $id);
	}
	$common = "DoSubmit('bbs.pool','FUNC','DELETE')";
	
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td bgcolor=yellow colspan=3><b><font color=red>");
	$Page->Print("※注：削除したスレッドを元に戻すことはできません。</b><br>");
	$Page->Print("<tr><td colspan=3><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=3 align=right>");
	$Page->Print("<input type=button value=\"　削除　\" onclick=\"$common\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドdat落ち復帰
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadRepare
{
	my ($Sys, $Form, $pLog) = @_;
	my (@threadList, $Threads, $Pools, $path, $bbs, $id);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 4, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	require './module/earendil.pl';
	$Threads = BILBO->new;
	$Pools = FRODO->new;
	
	$Threads->Load($Sys);
	$Pools->Load($Sys);
	
	@threadList = $Form->GetAtArray('THREADS');
	$bbs		= $Sys->Get('BBS');
	$path		= $Sys->Get('BBSPATH') . "/$bbs";
	
	foreach $id (@threadList) {
		push @$pLog, '"POOLスレッド「' . $Pools->Get('SUBJECT', $id) . '」を復帰';
		$Threads->Add($id, $Pools->Get('SUBJECT', $id), $Pools->Get('RES', $id));
		$Pools->Delete($id);
		
		EARENDIL::Move("$path/pool/$id.cgi", "$path/dat/$id.dat");
	}
	$Threads->Save($Sys);
	$Pools->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionThreadDelete
{
	my ($Sys, $Form, $pLog) = @_;
	my (@threadList, $Pools, $path, $bbs, $id);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 5, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	
	@threadList = $Form->GetAtArray('THREADS');
	$bbs		= $Sys->Get('BBS');
	$path		= $Sys->Get('BBSPATH') . "/$bbs/dat";
	
	foreach $id (@threadList) {
		push @$pLog, 'POOLスレッド「' . $Pools->Get('SUBJECT', $id) . '」を削除';
		$Pools->Delete($id);
		unlink "$path/$id.dat";
	}
	$Pools->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateSubject
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Pools);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 6, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	$Pools->Update($Sys);
	$Pools->Save($Sys);
	
	push @$pLog, 'POOLスレッド情報(subject.cgi)を更新しました。';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報全更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionUpdateSubjectAll
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Pools);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 6, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	require './module/baggins.pl';
	$Pools = FRODO->new;
	
	$Pools->Load($Sys);
	$Pools->UpdateAll($Sys);
	$Pools->Save($Sys);
	
	push @$pLog, 'POOLスレッド情報(subject.cgi)を再作成しました。';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログの生成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCreateLogs
{
	my ($Sys, $Form, $pLog) = @_;
	my ($Page, $Set, $Banner, $Dat, $Conv, $Logs);
	my (@poolSet, $key, $basePath, $bCreate);
	
	# 権限チェック
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $SEC->IsLogin($Form->Get('UserName'), $Form->Get('PassWord'));
		
		if (($SEC->IsAuthority($chkID, 7, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	@poolSet = $Form->GetAtArray('THREADS');
	
	require './module/gondor.pl';
	require './module/thorin.pl';
	require './module/isildur.pl';
	require './module/galadriel.pl';
	require './module/denethor.pl';
	require './module/celeborn.pl';
	$Dat = ARAGORN->new;
	$Set = ISILDUR->new;
	$Banner = DENETHOR->new;
	$Conv = GALADRIEL->new;
	$Page = THORIN->new;
	$Logs = CELEBORN->new;
	
	$Set->Load($Sys);
	$Banner->Load($Sys);
	$Logs->Load($Sys);
	
	$basePath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/pool';
	$bCreate = 0;
	
#	eval
	{
		foreach $key (@poolSet) {
			if ($Dat->Load($Sys,"$basePath/$key.cgi", 1)) {
				if (CreateKAKOLog($Page, $Sys, $Set, $Banner, $Dat, $Conv, $key)) {
					if ($Logs->Get('KEY', $key, '') eq '') {
						$Logs->Add($key, $Dat->GetSubject(), time, '/' . substr($key, 0, 4) . '/' . substr($key, 0, 5));
					}
					else {
						$Logs->($key, 'SUBJECT', $Dat->GetSubject());
						$Logs->($key, 'DATE', time);
						$Logs->($key, 'PATH', '/' . substr($key, 0, 4) . '/' . substr($key, 0, 5));
					}
					$bCreate = 1;
					push @$pLog, "■$key：過去ログ生成完了";
				}
			}
			if (! $bCreate){
				push @$pLog, "■$key：過去ログ生成失敗";
			}
			$bCreate = 0;
		}
	};
	if ($@ ne '') {
		push @$pLog, $@;
		return 9999;
	}
	$Logs->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログの生成 - 1ファイルの出力
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub CreateKAKOLog
{
	my ($Page, $Sys, $Set, $Banner, $Dat, $Conv, $key) = @_;
	my ($datPath, $logDir, $logPath, $i, @color, $title, $board, $var);
	my ($Caption, $cgipath);
	
	$cgipath	= $Sys->Get('CGIPATH');
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	# 過去ログ生成pooldatパスの生成
	$datPath	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/pool/' . $key . '.cgi';
	$logDir		= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako/' . substr($key, 0, 4) . '/' . substr($key, 0, 5);
	$logPath	= $logDir . '/' . $key . '.html';
	
	$title 		= $Dat->GetSubject();
	$board		= $Sys->Get('SERVER') . '/' . $Sys->Get('BBS');
	$var		= $Sys->Get('VERSION');
	
	# 色情報取得
	$color[0]	= $Set->Get('BBS_THREAD_COLOR');
	$color[1]	= $Set->Get('BBS_SUBJECT_COLOR');
	$color[2]	= $Set->Get('BBS_TEXT_COLOR');
	$color[3]	= $Set->Get('BBS_LINK_COLOR');
	$color[4]	= $Set->Get('BBS_ALINK_COLOR');
	$color[5]	= $Set->Get('BBS_VLINK_COLOR');
	
#	eval
	{
		require './module/earendil.pl';
		
		$Page->Clear();
		
		$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
		
		$Caption->Print($Page, undef);
		
		$Page->Print(<<HTML);
 <title>$title</title>

</head>
<!--nobanner-->
<body bgcolor="$color[0]" text="$color[2]" link="$color[3]" alink="$color[4]" vlink="$color[5]">

HTML

		# 告知欄出力
		$Banner->Print($Page, 100, 2, 0);
		
		$Page->Print(<<HTML);
<div style="margin-top:1em;">
 <a href="$board/">■掲示板に戻る■</a>
 <a href="$board/kako/">■過去ログ倉庫へ戻る■</a>
</div>

<hr style="background-color:#888;color:#888;border-width:0;height:1px;position:relative;top:-.4em;">

<h1 style="color:red;font-size:larger;font-weight:normal;margin:-.5em 0 0;">$title</h1>

HTML
		
		$Page->Print("<dl>\n");
		
		# レスの出力
		for ($i = 0 ; $i < $Dat->Size() ; $i++) {
			PrintResponse($Sys, $Page, $Dat->Get($i), $i + 1, $Conv, $Set);
		}
		
		$Page->Print("</dl>\n");
		
		$Page->Print(<<HTML);

<hr>

<div style="margin-top:1em;">
 <a href="$board/">■掲示板に戻る■</a>
 <a href="$board/kako/">■過去ログ倉庫へ戻る■</a>
</div>
<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$var
</div>


HTML
		
		$Page->Print("</body>\n</html>\n");
		$Dat->Close();
		
		# 過去ログの出力
		EARENDIL::CreateFolderHierarchy($logDir);
		EARENDIL::Copy($datPath, "$logDir/$key.dat");
		$Page->Flush(1, $Sys->Get('PM-TXT'), $logPath);
	};
	if ($@ ne '') {
		$Dat->Close();
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログの生成 - 1レスの出力
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub PrintResponse
{
	my ($Sys, $Page, $pDat, $n, $Conv, $Set) = @_;
	my ($oConv, @elem, $nameCol);
	
	$nameCol	= $Set->Get('BBS_NAME_COLOR');
	@elem		= split(/<>/, $$pDat);
	
	# URLと引用個所の適応
	$Conv->ConvertURL($Sys, $Set, 0, \$elem[3]);
	
	$Page->Print(" <dt><a name=\"$n\">$n</a> ：");
	$Page->Print("<font color=\"$nameCol\"><b>$elem[0]</b></font>")	if ($elem[1] eq '');
	$Page->Print("<a href=\"mailto:$elem[1]\"><b>$elem[0]</b></a>")	if ($elem[1] ne '');
	$Page->Print("：$elem[2]</dt>\n  <dd>$elem[3]<br><br></dd>\n");
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

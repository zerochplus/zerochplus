#============================================================================================================
#
#	システム管理 - ユーザ モジュール
#	sys.top.pl
#	---------------------------------------------------------------------------
#	2004.09.11 start
#
#============================================================================================================
package	MODULE;

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
	my		$this = shift;
	my		($obj,@LOG);
	
	$obj = {
		'LOG'	=> \@LOG
	};
	bless($obj,$this);
	
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
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($subMode,$BASE,$BBS);
	
	require('./mordor/sauron.pl');
	$BASE = new SAURON;
	
	# 管理マスタオブジェクトの生成
	$Page		= $BASE->Create($Sys,$Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($BASE,$pSys);
	
	if		($subMode eq 'NOTICE'){													# 通知一覧画面
		PrintNoticeList($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'NOTICE_CREATE'){											# 通知一覧画面
		PrintNoticeCreate($Page,$Sys,$Form);
	}
	elsif	($subMode eq 'ADMINLOG'){												# ログ閲覧画面
		PrintAdminLog($Page,$Sys,$Form,$pSys->{'LOGGER'});
	}
	elsif	($subMode eq 'COMPLETE'){												# 設定完了画面
		$Sys->Set('_TITLE','Process Complete');
		$BASE->PrintComplete('ユーザ通知処理',$this->{'LOG'});
	}
	elsif	($subMode eq 'FALSE'){													# 設定失敗画面
		$Sys->Set('_TITLE','Process Failed');
		$BASE->PrintError($this->{'LOG'});
	}
	
	$BASE->Print($Sys->Get('_TITLE'),1);
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
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($subMode,$err);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 0;
	
	if		($subMode eq 'CREATE'){													# 通知作成
		$err = FunctionNoticeCreate($Sys,$Form,$this->{'LOG'});
	}
	elsif	($subMode eq 'DELETE'){													# 通知削除
		$err = FunctionNoticeDelete($Sys,$Form,$this->{'LOG'});
	}
	elsif	($subMode eq 'LOG_REMOVE'){												# 操作ログ削除
		$err = FunctionLogRemove($Sys,$Form,$pSys->{'LOGGER'},$this->{'LOG'});
	}
	
	# 処理結果表示
	if	($err){
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_TOP($subMode)",'ERROR:'.$err);
		push(@{$this->{'LOG'}},$err);
		$Form->Set('MODE_SUB','FALSE');
	}
	else{
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_TOP($subMode)",'COMPLETE');
		$Form->Set('MODE_SUB','COMPLETE');
	}
	$this->DoPrint($Sys,$Form,$pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my		($Base,$pSys) = @_;
	
	# 共通表示メニュー
	$Base->SetMenu("ユーザ通知一覧","'sys.top','DISP','NOTICE'");
	$Base->SetMenu("ユーザ通知作成","'sys.top','DISP','NOTICE_CREATE'");
	
	# システム管理権限のみ
	if	($pSys->{'SECINFO'}->IsAuthority($pSys->{'USER'},0,'*')){
		$Base->SetMenu('<hr>','');
		$Base->SetMenu("操作ログ閲覧","'sys.top','DISP','ADMINLOG'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoticeList
{
	my		($Page,$Sys,$Form) = @_;
	my		($Notices,@noticeSet,$from,$subj,$text,$date,$id,$common);
	my		($dispNum,$i,$dispSt,$dispEd,$listNum,$isAuth,$curUser);
	
	$Sys->Set('_TITLE','User Notice List');
	
	require('./module/gandalf.pl');
	require('./module/galadriel.pl');
	$Notices = new GANDALF;
	
	# 通知情報の読み込み
	$Notices->Load($Sys);
	
	# 通知情報を取得
	$Notices->GetKeySet('ALL','',\@noticeSet);
	@noticeSet = sort(@noticeSet);
	@noticeSet = reverse(@noticeSet);
	
	# 表示数の設定
	$listNum	= @noticeSet;
	$dispNum	= ($Form->Get('DISPNUM_NOTICE') eq '' ? 5 : $Form->Get('DISPNUM_NOTICE'));
	$dispSt		= ($Form->Get('DISPST_NOTICE') eq '' ? 0 : $Form->Get('DISPST_NOTICE'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	
	$common		= "DoSubmit('sys.top','DISP','NOTICE');";
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td></td><td><b><a href=\"javascript:SetOption('DISPST_NOTICE'," . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_NOTICE',");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td align=right colspan=2>");
	$Page->Print("表\示数<input type=text name=DISPNUM_NOTICE size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"　表\示　\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td style=\"width:30\"><br></td>");
	$Page->Print("<td colspan=3 class=\"DetailTitle\">Notification</td></tr>\n");
	
	# カレントユーザ
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	# 通知一覧を出力
	for	($i = $dispSt;$i < $dispEd;$i++){
		$id = $noticeSet[$i];
		if	($Notices->IsInclude($id,$curUser) && !$Notices->IsLimitOut($id)){
			if	($Notices->Get('FROM',$id) eq '0000000000'){
				$from = '0ch管理システム';
			}
			else{
				$from = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'}->Get('NAME',$Notices->Get('FROM',$id));
			}
			$subj = $Notices->Get('SUBJECT',$id);
			$text = $Notices->Get('TEXT',$id);
			$date = GALADRIEL::GetDateFromSerial(undef,$Notices->Get('DATE',$id),0);
			
			$Page->Print("<tr><td><input type=checkbox name=NOTICES value=\"$id\"></td>");
			$Page->Print("<td class=\"Response\" colspan=3>");
			$Page->Print("<dt><b>$subj <font color=blue>From：</b>$from</font>　");
			$Page->Print("$date</dt><dd><br>$text<br><br></dd>\n");
		}
		else{
			$dispEd++	if	($dispEd + 1 < $listNum);
		}
	}
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"　削除　\" $common,'DELETE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table></dl><br>");
	$Page->HTMLInput('hidden','DISPST_NOTICE','');
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知作成画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintNoticeCreate
{
	my		($Page,$Sys,$Form) = @_;
	my		($isSysad,$User,@userSet,$id,$name,$full);
	
	$Sys->Set('_TITLE','User Notice Create');
	
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},0,'*');
	$User = $Sys->Get('ADMIN')->{'SECINFO'}->{'USER'};
	$User->GetKeySet('ALL','',\@userSet);
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">タイトル</td><td>");
	$Page->Print("<input type=text size=60 name=NOTICE_TITLE></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">本文</td><td>");
	$Page->Print("<textarea rows=10 cols=70 name=NOTICE_CONTENT wrap=off></textarea></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">通知先ユーザ</td><td>");
	$Page->Print("<table width=100% cellspaing=2>");
	
	if	($isSysad){
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=radio name=NOTICE_KIND value=ALL>全体通知</td>");
		$Page->Print("<td>有効期限：<input type=text name=NOTICE_LIMIT size=10 value=30>日</td></tr>");
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=radio name=NOTICE_KIND value=ONE checked>個別通知</td><td>");
	}
	else{
		$Page->Print("<tr><td class=\"DetailTitle\">");
		$Page->Print("<input type=hidden name=NOTICE_KIND value=ONE>個別通知</td><td>");
	}
	
	# ユーザ一覧を表示
	foreach	$id (@userSet){
		$name = $User->Get('NAME',$id);
		$full = $User->Get('FULL',$id);
		$Page->Print("<input type=checkbox name=NOTICE_USERS value=\"$id\"> $name（$full）<br>");
	}
	$Page->Print("</td></tr></table></td></tr>");
	
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=2 align=right>");
	$Page->Print("<input type=button value=\"　送信　\" $common,'CREATE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	管理操作ログ閲覧画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	ページコンテキスト
#	@param	$SYS	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintAdminLog
{
	my		($Page,$Sys,$Form,$Logger) = @_;
	my		($common);
	my		($dispNum,$i,$dispSt,$dispEd,$listNum,$isSysad,$data,@elem);
	
	$Sys->Set('_TITLE','Operation Log');
	$isSysad = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'},0,'*');
	
	# 表示数の設定
	$listNum	= $Logger->Size();
	$dispNum	= ($Form->Get('DISPNUM_LOG') eq '' ? 10 : $Form->Get('DISPNUM_LOG'));
	$dispSt		= ($Form->Get('DISPST_LOG') eq '' ? 0 : $Form->Get('DISPST_LOG'));
	$dispSt		= ($dispSt < 0 ? 0 : $dispSt);
	$dispEd		= (($dispSt + $dispNum) > $listNum ? $listNum : ($dispSt + $dispNum));
	$common		= "DoSubmit('sys.top','DISP','ADMINLOG');";
	
	$Page->Print("<center><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2><b><a href=\"javascript:SetOption('DISPST_LOG'," . ($dispSt - $dispNum));
	$Page->Print(");$common\">&lt;&lt; PREV</a> | <a href=\"javascript:SetOption('DISPST_LOG',");
	$Page->Print("" . ($dispSt + $dispNum) . ");$common\">NEXT &gt;&gt;</a></b>");
	$Page->Print("</td><td align=right colspan=2>");
	$Page->Print("表\示数<input type=text name=DISPNUM_LOG size=4 value=$dispNum>");
	$Page->Print("<input type=button value=\"　表\示　\" onclick=\"$common\"></td></tr>\n");
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	
	$Page->Print("<tr><td class=\"DetailTitle\">Date</td>");
	$Page->Print("<td class=\"DetailTitle\">User</td>");
	$Page->Print("<td class=\"DetailTitle\">Operation</td>");
	$Page->Print("<td class=\"DetailTitle\">Result</td></tr>\n");
	
	require('./module/galadriel.pl');
	
	# ログ一覧を出力
	for	($i = $dispSt;$i < $dispEd;$i++){
		$data = $Logger->Get($listNum - $i - 1);
		@elem = split(/<>/,$data);
		if	(1){
			$elem[0] = GALADRIEL::GetDateFromSerial(undef,$elem[0],0);
			$Page->Print("<tr><td>$elem[0]</td><td>$elem[1]</td><td>$elem[2]</td><td>$elem[3]</td></tr>\n");
		}
		else{
			$dispEd++	if	($dispEd + 1 < $listNum);
		}
	}
	$common = "onclick=\"DoSubmit('sys.top','FUNC'";
	
	$Page->Print("<tr><td colspan=4><hr></td></tr>\n");
	$Page->Print("<tr><td colspan=4 align=right>");
	$Page->Print("<input type=button value=\"ログの削除\" $common,'LOG_REMOVE')\"> ");
	$Page->Print("</td></tr>\n");
	$Page->Print("</table><br>");
	$Page->HTMLInput('hidden','DISPST_LOG','');
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知作成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeCreate
{
	my		($Sys,$Form,$pLog) = @_;
	my		($Notice,$subject,$content,$date,$limit,$users);
	
	# 権限チェック
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	($chkID eq ''){
			return 1000;
		}
	}
	# 入力チェック
	{
		my	@inList = ('NOTICE_TITLE','NOTICE_CONTENT');
		if	(!$Form->IsInput(@inList)){
			return 1001;
		}
		@inList = ('NOTICE_LIMIT');
		if	($Form->Equal('NOTICE_KIND','ALL') && !$Form->IsInput(@inList)){
			return 1001;
		}
		@inList = ('NOTICE_USERS');
		if	($Form->Equal('NOTICE_KIND','ONE') && !$Form->IsInput(@inList)){
			return 1001;
		}
	}
	require('./module/gandalf.pl');
	$Notice = new GANDALF;
	$Notice->Load($Sys);
	
	$date = time();
	$subject = $Form->Get('NOTICE_TITLE');
	$content = $Form->Get('NOTICE_CONTENT');
	$content =~ s/\r\n|\r|\n/<br>/g;
	
	if	($Form->Equal('NOTICE_KIND','ALL')){
		$users = '*';
		$limit = $Form->Get('NOTICE_LIMIT');
		$limit = $date + ($limit * 24 * 60 * 60);
	}
	else{
		my	@toSet = $Form->GetAtArray('NOTICE_USERS');
		$users = join(',',@toSet);
		$limit = 0;
	}
	# 通知情報を追加
	$Notice->Add($users,$Sys->Get('ADMIN')->{'USER'},$subject,$content,$limit);
	$Notice->Save($Sys);
	
	push(@$pLog,"ユーザへの通知終了");
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeDelete
{
	my		($Sys,$Form,$pLog) = @_;
	my		($Notice,@noticeSet,$curUser,$id);
	
	# 権限チェック
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	($chkID eq ''){
			return 1000;
		}
	}
	require('./module/gandalf.pl');
	$Notice = new GANDALF;
	$Notice->Load($Sys);
	
	@noticeSet = $Form->GetAtArray('NOTICES');
	$curUser = $Sys->Get('ADMIN')->{'USER'};
	
	foreach	$id	(@noticeSet){
		if	($Notice->Get('TO',$id) eq '*'){
			my	$subj = $Notice->Get('SUBJECT',$id);
			push(@$pLog,"通知「$subj」は全体通知なので削除できませんでした。");
		}
		else{
			my	$subj = $Notice->Get('SUBJECT',$id);
			$Notice->RemoveToUser($id,$curUser);
			push(@$pLog,"通知「$subj」を削除しました。");
		}
	}
	$Notice->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	操作ログ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogRemove
{
	my		($Sys,$Form,$Logger,$pLog) = @_;
	my		($Notice,@noticeSet,$curUser,$id);
	
	# 権限チェック
	{
		my	$SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my	$chkID	= $SEC->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'));
		
		if	(($SEC->IsAuthority($chkID,0,'*')) == 0){
			return 1000;
		}
	}
	$Logger->Clear();
	push(@$pLog,"操作ログを削除しました。");
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

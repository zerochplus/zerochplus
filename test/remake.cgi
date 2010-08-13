#!/usr/bin/perl
#============================================================================================================
#
#	index更新用CGI
#	remake.cgi
#	-------------------------------------------------------------------------------------
#	2006.08.05 bbs.cgiから必要な部分だけ抜き出し
#
#============================================================================================================

# CGIの実行結果を終了コードとする
exit(REMAKECGI());

#------------------------------------------------------------------------------------------------------------
#
#	remake.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub REMAKECGI
{
	my (%SYS, $Page, $err);
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# 初期化に成功したら更新処理を開始
	if (($err = Initialize(\%SYS)) == 0) {
				require './module/varda.pl';
				my $BBSAid = new VARDA;
				
				eval {
					$BBSAid->Init($SYS{'SYS'}, $SYS{'SET'});
					$BBSAid->CreateIndex();
					$BBSAid->CreateIIndex();
					$BBSAid->CreateSubback();
				};
			PrintBBSJump(\%SYS, $Page);
	}
	else {
		PrintBBSError(\%SYS, $Page, $err);
	}
	
	# 結果の表示
	$Page->Flush('', 0, 0);
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	remake.cgi初期化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($Sys) = @_;
	
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
		'FORM'		=> new SAMWISE
	);
	
	# form情報設定
	$Sys->{'FORM'}->DecodeForm(1);
	
	# システム情報設定
	if ($Sys->{'SYS'}->Init()) {
		return 990;
	}
	if ($Sys->{'FORM'}->Get('bbs') =~ /\W/) {
		return 999;
	}
	$Sys->{'SYS'}->Set('BBS', $Sys->{'FORM'}->Get('bbs'));
	$Sys->{'SYS'}->Set('AGENT', $Sys->{'CONV'}->GetAgentMode($ENV{'HTTP_USER_AGENT'}));
	$Sys->{'SYS'}->Set('MODE', 'CREATE');
	
	# SETTING.TXTの読み込み
	if (!$Sys->{'SET'}->Load($Sys->{'SYS'})) {
		return 999;
	}
	
	return 0;
}


#------------------------------------------------------------------------------------------------------------
#
#	remake.cgiジャンプページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSJump
{
	my ($Sys, $Page) = @_;
	my ($SYS, $bbsPath);
	
	$SYS		= $Sys->{'SYS'};
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	
	# 携帯用表示
	if (!$SYS->Equal('AGENT', 0)) {
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print('<!--nobanner--><html><body>indexを更新しました。<br>');
		$Page->Print("<a href=\"$bbsPath/i/\">こちら</a>");
		$Page->Print("から掲示板へ戻ってください。\n");
	}
	# PC用表示
	else {
		my $oSET = $Sys->{'SET'};
		
		$Page->Print("Content-type: text/html\n\n<html><head><title>");
		$Page->Print('indexを更新しました。</title><!--nobanner-->');
		$Page->Print('<meta http-equiv="Content-Type" content="text/html; ');
		$Page->Print("charset=Shift_JIS\"><meta content=0;URL=$bbsPath/ ");
		$Page->Print('http-equiv=refresh></head><body>indexを更新しました。');
		$Page->Print('<br><br>画面を切り替えるまでしばらくお待ち下さい。');
		$Page->Print('<br><br><br><br><br><hr>');
		
	}
	# 告知欄表示(表示させたくない場合はコメントアウトか条件を0に)
	if (0) {
		require './module/denethor.pl';
		my $BANNER = new DENETHOR;
		$BANNER->Load($SYS);
		$BANNER->Print($Page, 100, 0, $SYS->Get('AGENT'));
	}
	$Page->Print('</body></html>');
}

#------------------------------------------------------------------------------------------------------------
#
#	remake.cgiエラーページ表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintBBSError
{
	my ($Sys, $Page, $err) = @_;
	
	require './module/orald.pl';
	$ERROR = new ORALD;
	$ERROR->Load($Sys->{'SYS'});
	
	$ERROR->Print($Sys, $Page, $err, $Sys->{'SYS'}->Get('AGENT'));
}


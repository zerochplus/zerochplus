#============================================================================================================
#
#	掲示板書き込み支援モジュール
#	vara.pl
#	-------------------------------------------------------------------------------------
#	2004.03.27 start
#
#	ぜろちゃんねるプラス
#	2010.08.12 規制選択性導入のため仕様変更
#	2010.08.13 ログ保存形式変更による仕様変更
#	2010.08.15 0ch本家プラグインとの互換性復活
#
#============================================================================================================
package	VARA;

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
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR(必須)
#	@param	$Form	SAMWISE(必須)
#	@param	$Set	ISILDUR
#	@param	$Thread	BILBO
#	@param	$Conv	GALADRIEL
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Form, $Set, $Thread, $Conv) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'SET'}		= $Set;
	$this->{'THREADS'}	= $Thread;
	$this->{'CONV'}		= $Conv;
	
	# モジュールが用意されてない場合はここで生成する
	if (! defined $Set) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	if (! defined $Thread) {
		require './module/baggins.pl';
		$this->{'THREADS'} = BILBO->new;
		$this->{'THREADS'}->Load($Sys);
	}
	if (! defined $Conv) {
		require './module/galadriel.pl';
		$this->{'CONV'} = GALADRIEL->new;
	}
	
	# キャップ管理モジュールロード
	require './module/ungoliants.pl';
	$this->{'SECURITY'} = SECURITY->new;
	$this->{'SECURITY'}->Init($Sys);
	$this->{'SECURITY'}->SetGroupInfo($Sys->Get('BBS'));
	
	# 拡張機能情報管理モジュールロード
	require './module/athelas.pl';
	$this->{'PLUGIN'} = ATHELAS->new;
	$this->{'PLUGIN'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み処理 - WriteData
#	-------------------------------------------
#	引　数：$I   : ISILDURオブジェクト
#			$M   : MELKORオブジェクト
#	戻り値：なし
#
#	2010.08.13 windyakin ★
#	 -> ログ保存形式変更による規制チェック位置の変更
#	2010.08.15 色々
#	 -> プラグイン1,2の実行順序変更
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	my ($err);
	
	# 書き込み前準備
	ReadyBeforeCheck($this);
	
	# 入力内容チェック(名前、メール)
	if (($err = NormalizationNameMail($this))) {
		return $err;
	}
	# 入力内容チェック(本文)
	if (($err = NormalizationContents($this))) {
		return $err;
	}
	
	# データの書き込み
	eval {
		my ($oSys, $oSet, $oForm, $oConv);
		my (@elem, $date, $data, $data2, $resNum, $datPath, $id);
		
		require './module/gondor.pl';
		$oSys	= $this->{'SYS'};
		$oSet	= $this->{'SET'};
		$oForm	= $this->{'FORM'};
		$oConv	= $this->{'CONV'};
		
		# 書き込み直前処理
		if ($err = ReadyBeforeWrite($this, ARAGORN::GetNumFromFile($oSys->Get('DATPATH')) + 1)) {
			return $err;
		}
		
		# レス要素の取得
		$oForm->GetListData(\@elem, 'subject', 'FROM', 'mail', 'MESSAGE');
		
		$err		= 0;
		$id			= $oConv->MakeID($oSys->Get('SERVER'), 8);
		$date		= $oConv->GetDate($oSet);
		$date		.= $oConv->GetIDPart($oSet, $oForm, $this->{'SECURITY'}, $id, $oSys->Get('CAPID'), $oSys->Get('AGENT'));
		$data		= join('<>', $elem[1], $elem[2], $date, $elem[3], $elem[0]);
		$data2		= "$data\n";
		$datPath	= $oSys->Get('DATPATH');
		
		# 規制チェック
		# なぜこんなところに？ -> http://yakin.38-ch.net/test/read.cgi/windyakin/1281101424/597
		if ($err = IsRegulation($this, $data)) {
			return $err;
		}
		
		# リモートホスト保存(SETTING.TXT変更により、常に保存)
		SaveHost($oSys, $oForm);
		
		# datファイルへ直接書き込み
		eval {
			if (($err = ARAGORN::DirectAppend($oSys, $datPath, $data2)) == 0) {
				# レス数が最大数を超えたらover設定をする
				if (($resNum = ARAGORN::GetNumFromFile($datPath)) >= $oSys->Get('RESMAX')) {
					# datにOVERスレッドレスを書き込む
					Get1001Data($oSys, \$data2);
					ARAGORN::DirectAppend($oSys, $datPath, $data2);
					$resNum++;
				}
				# 履歴保存
				SaveHistory($oSys, $oForm, ARAGORN::GetNumFromFile($datPath));
			}
			# datファイル追記失敗
			else {
				$err = 999 if ($err == 1);
				$err = 200 if ($err == 2);
			}
		};
		if ($err == 0 && $@ eq '') {
			# subject.txtの更新
			# スレッド作成モードなら新規に追加する
			if ($oSys->Equal('MODE', 1)) {
				$this->{'THREADS'}->Add($oSys->Get('KEY'), $elem[0], 1);
			}
			# 書き込みモードならレス数の更新
			else {
				$this->{'THREADS'}->Set($oSys->Get('KEY'), 'RES', $resNum);
				# sageが入っていなかったらageる
				if (!$oForm->Contain('mail', 'sage')) {
					$this->{'THREADS'}->AGE($oSys->Get('KEY'));
				}
			}
			$this->{'THREADS'}->Save($oSys);
		}
	};
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	前準備
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	なし
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my ($this) = @_;
	my ($Sys, $Form, @pluginSet, $capPass, $capID);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	
	# cookie用にオリジナルを保存する
	my ($from, $mail);
	$from = $Form->Get('FROM');
	$mail = $Form->Get('mail');
	$from =~ s/\n//g;
	$mail =~ s/\n//g;
	$Form->Set('NAME', $from);
	$Form->Set('MAIL', $mail);
	
	# キャップパスの抽出と削除
	if ($mail =~ /(#|＃)(.+)/) {
		$mail =~ s/＃/#/;
		$mail =~ s/#(.+)//;
		$capPass = $1;
		
		# キャップ情報設定
		$capID = $this->{'SECURITY'}->GetCapID($capPass);
		$Form->Set('mail', $mail);
	}
	$capID = '' if (! defined $capID);
	$Sys->Set('CAPID', $capID);
	
	# datパスの生成
	my $datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
	$Sys->Set('DATPATH', $datPath);
	
	# 本文禁則文字変換
	my $text = $Form->Get('MESSAGE');
	$this->{'CONV'}->ConvertCharacter1(\$text, 2);
	$Form->Set('MESSAGE', $text);
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み直前処理
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@param	$res
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeWrite
{
	my ($this, $res) = @_;
	my ($Sys, $Form, @pluginSet, $text, $host, $from);
	
	$Sys	= $this->{'SYS'};
	$Form	= $this->{'FORM'};
	$host	= $this->{'FORM'}->Get('HOST');
	$from	= $this->{'FORM'}->Get('FROM');
	
	# 規制ユーザ・NGワードチェック
	{
		my ($vUser, $ngWord, $check, @checkKey);
		# 規制ユーザ
		require './module/faramir.pl';
		$vUser = FARAMIR->new;
		$vUser->Load($Sys);
		$check = $vUser->Check($host);
		if ($check == 4) {
			return 601;
		}
		if ($check == 2) {
			if ($from =~ /$host/i) {
				$this->{'FORM'}->Set('FROM', "</b>[´･ω･｀] <b>$from");
			}
			else {
				return 601;
			}
		}
		
		# NGワード
		require './module/wormtongue.pl';
		$ngWord = WORMTONGUE->new;
		$ngWord->Load($Sys);
		@checkKey = ('FROM', 'mail', 'MESSAGE');
		$check = $ngWord->Check($this->{'FORM'}, \@checkKey);
		if ($check == 3) {
			return 600;
		}
		if ($check == 1) {
			$ngWord->Method($this->{'FORM'}, \@checkKey);
		}
		if ($check == 2) {
			$this->{'FORM'}->Set('FROM', "$from<font color=\"tomato\">$host</font>");
		}
	}
	
	# pluginに渡す値を設定
	$Sys->Set('_ERR', 0);
	$Sys->Set('_NUM_', $res);
	$Sys->Set('_THREAD_', $this->{'THREADS'});
	$Sys->Set('_SET_', $this->{'SET'});
	
	$this->ExecutePlugin(16);
	
	$text = $Form->Get('MESSAGE');
	$text =~ s/<br>/ <br> /g;
	$Form->Set('MESSAGE', " $text ");
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン処理
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@param	$type
#	@return	なし
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub ExecutePlugin
{
	my ($this, $type) = @_;
	my ($Sys, $Form, $Plugin, $id, @pluginSet, $Config);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	$Plugin = $this->{'PLUGIN'};
	
	# 有効な拡張機能一覧を取得
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	foreach $id (@pluginSet) {
		# タイプが先呼び出しの場合はロードして実行
		if ($Plugin->Get('TYPE', $id) & $type) {
			my ($file, $className, $command, $config);
			$file = $Plugin->Get('FILE', $id);
			$className = $Plugin->Get('CLASS', $id);
			require "./plugin/$file";
			$Config = PLUGINCONF->new($Plugin, $id);
			$command = $className->new($Config);
			$command->execute($Sys, $Form, $type);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	規制チェック
#	-------------------------------------------------------------------------------------
#	@param	$this, $datas
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#	2010.08.12 windyakin ★
#	 -> ２重かきこの規制を選択性にしたので変更
#	 -> 規制ユーザーホスト表示時のの仕様変更
#
#	2010.08.13 windyakin ★
#	 -> ログ出力形式変更による引数の変更
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my ($this, $datas) = @_;
	my ($oSYS, $oSET, $oSEC);
	my ($err, $host, $bbs, $datPath, $capID, $Samba, $from, $mode);
	
	$oSYS		= $this->{'SYS'};
	$oSET		= $this->{'SET'};
	$oSEC		= $this->{'SECURITY'};
	$host		= $this->{'FORM'}->Get('HOST');
	$bbs		= $this->{'FORM'}->Get('bbs');
	$from		= $this->{'FORM'}->Get('FROM');
	$capID		= $oSYS->Get('CAPID');
	$datPath	= $oSYS->Get('DATPATH');
	$Samba		= $oSYS->Get('SAMBA');
	$mode		= $oSYS->Get('AGENT');
	
	# レス書き込みモード時のみ
	if ($oSYS->Equal('MODE', 2)) {
		require './module/gondor.pl';
		
		# 移転スレッド
		if (ARAGORN::IsMoved($datPath)) {
			return 202;
		}
		# レス最大数
		if ($oSYS->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath)) {
			return 201;
		}
		# datファイルサイズ制限
		if ($oSET->Get('BBS_DATMAX')) {
			my $datSize = int((stat $datPath)[7] / 1024);
			if ($oSET->Get('BBS_DATMAX') < $datSize) {
				return 206;
			}
		}
	}
	# REFERERチェック
	if ($oSET->Equal('BBS_REFERER_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsReferer($this->{'SYS'}, \%ENV)) {
			return 998;
		}
	}
	# PROXYチェック
	if ($oSET->Equal('BBS_PROXY_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsProxy(\$host)) {
			$this->{'FORM'}->Set('FROM', "</b> [―{}\@{}\@{}-] <b>$from");
			return 997 if (! $oSEC->IsAuthority($capID, 19, $bbs));
		}
	}
	# 読取専用
	if (!$oSET->Equal('BBS_READONLY', 'none')) {
		if (! $oSEC->IsAuthority($capID, 13, $bbs)) {
			return 203;
		}
	}
	# JPホスト以外規制
	if ($oSET->Equal('BBS_JP_CHECK', 'checked')) {
		unless ($host =~ /\.(jp|JP)$/) {
			return 207;
		}
	}
	
	# スレッド作成モード
	if ($oSYS->Equal('MODE', 1)) {
		# スレッドキーが重複しないようにする
		my $tPath = $oSYS->Get('BBSPATH') . '/' . $oSYS->Get('BBS') . '/dat/';
		my $key = $oSYS->Get('KEY');
		while (-e "$tPath$key.dat") {
			$key++;
		}
		$oSYS->Set('KEY', $key);
		$datPath = "$tPath$key.dat";
		
		# スレッド作成(携帯から)
		if ($oSYS->Get('AGENT') eq "O") {
			if (! $oSEC->IsAuthority($capID, 16, $bbs)) {
				return 204;
			}
		}
		# スレッド作成(キャップのみ)
		if ($oSET->Equal('BBS_THREADCAPONLY', 'checked')) {
			if (! $oSEC->IsAuthority($capID, 9, $bbs)) {
				return 504;
			}
		}
		# スレッド作成(スレッド立てすぎ)
		require './module/peregrin.pl';
		my $LOG = PEREGRIN->new;
		$LOG->Load($oSYS, 'THR');
		if (! $oSEC->IsAuthority($capID, 8, $bbs)) {
			if ($LOG->Search($host, 1)) {
				return 500;
			}
		}
		$LOG->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $host);
		$LOG->Save($oSYS);
	}
	# レス書き込みモード
	else {
		require './module/peregrin.pl';
		my $LOGs = PEREGRIN->new;
		$LOGs->Load($oSYS, 'SMB');
		$LOGs->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $host);
		$LOGs->Save($oSYS);
		
		# SAMBA
		if (! $oSEC->IsAuthority($capID, 12, $bbs)) {
			my ($n, $tm) = $LOGs->IsSamba($Samba, $host);
			if ($tm > 0) {
				$oSYS->Set('WAIT', $tm);
				$oSYS->Set('SAMBA', $n);
				$oSYS->Set('SAMBATM', $Samba);
				return 505;
			}
		}
		
		my $LOG = PEREGRIN->new;
		$LOG->Load($oSYS, 'WRT', $oSYS->Get('KEY'));
		
		# レス書き込み(連続投稿)
		if (! $oSEC->IsAuthority($capID, 10, $bbs)) {
			if ($LOG->Search($host, 2) >= $oSET->Get('timeclose')) {
			#	return 501;
			}
		}
		# レス書き込み(二重投稿)
		if (! $oSEC->IsAuthority($capID, 11, $bbs)) {
			if ($this->{'SYS'}->Get('KAKIKO') eq 1) {
				if ($LOG->Search($host, 1) == length($this->{'FORM'}->Get('MESSAGE'))) {
					return 502;
				}
			}
		}
		
=for
		# 短時間投稿
		if (!$oSEC->IsAuthority($capID, 12, $bbs)) {
			my $tm = $LOG->IsTime($Samba, $host);
			if ($tm > 0) {
				$oSYS->Set('WAIT', $tm);
				return 503;
			}
		}
=cut
		$LOG->Set($oSET, length($this->{'FORM'}->Get('MESSAGE')), $oSYS->Get('VERSION'), $host, $datas, $mode);
		$LOG->Save($oSYS);
	}
	
	# パスを保存
	$oSYS->Set('DATPATH', $datPath);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	名前・メール欄の正規化
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#	2010.08.12 windyakin ★
#	 -> トリップ変換処理の順番を変更(禁則文字,fusianasan変換の前へ)
#	 -> 文字列変換処理の順番を変更(文字数チェックの前へ)
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my ($this) = @_;
	my ($Form, $oSEC, $oSET, $Sys);
	my ($name, $mail, $subject, $bbs, $capName, $capID, $key, $host);
	
	$Sys		= $this->{'SYS'};
	$Form		= $this->{'FORM'};
	$oSEC		= $this->{'SECURITY'};
	$oSET		= $this->{'SET'};
	
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$subject	= $Form->Get('subject');
	$bbs		= $Form->Get('bbs');
	$host		= $Form->Get('HOST');
	
	# キャップ情報取得
	$capID = $Sys->Get('CAPID');
	if ($capID && $oSEC->IsAuthority($capID, 17, $bbs)) {
		$capName = $oSEC->Get($capID, 'NAME', 1);
	}
	
	# トリップキーを切り離す
	if ($name =~ /#(.+)$/) {
		$key = $1;
		
		# トリップ変換
		$key = $this->{'CONV'}->ConvertTrip(\$key, $oSET->Get('BBS_TRIPCOLUMN'), $Sys->Get('TRIP12'));
	}
	else {
		$key = '';
	}
	
	# 特殊文字変換 フォーム情報再設定
	$this->{'CONV'}->ConvertCharacter1(\$name, 0);
	$this->{'CONV'}->ConvertCharacter1(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter1(\$subject, 3);
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	# プラグイン実行 フォーム情報再取得
	$this->ExecutePlugin($Sys->Get('MODE'));
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$subject	= $Form->Get('subject');
	$bbs		= $Form->Get('bbs');
	$host		= $Form->Get('HOST');
	
	# 2ch互換
	$name = substr($name, 1) if (index($name, ' ') == 0);
	
	# 禁則文字変換
	$this->{'CONV'}->ConvertCharacter2(\$name, 0);
	$this->{'CONV'}->ConvertCharacter2(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter2(\$subject, 3);
	
	# トリップと名前を結合する
	$name =~ s|#.+$| </b>◆$key <b>|;
	
	# fusiana変換 2ch互換
	$name =~ s:fusianasan|山崎渉:</b>$host<b>:;
	$name =~ s:fusianasan|山崎渉: </b>$host<b>:g;
	
	# キャップ名結合
	if (defined $capName && $capName ne '') {
		$name = ($Form->Get('NAME') ? "$name＠" : '') . "$capName ★";
	}
	
	
	# スレッド作成時
	if ($Sys->Equal('MODE', 1)) {
		if ($subject eq '') {
			return 150;
		}
		# サブジェクト欄の文字数確認
		if (! $oSEC->IsAuthority($capID, 1, $bbs)) {
			if ($oSET->Get('BBS_SUBJECT_COUNT') < length($subject)) {
				return 101;
			}
		}
	}
	
	# 名前欄の文字数確認
	if (! $oSEC->IsAuthority($capID, 2, $bbs)) {
		if ($oSET->Get('BBS_NAME_COUNT') < length($name)) {
			return 101;
		}
	}
	# メール欄の文字数確認
	if (! $oSEC->IsAuthority($capID, 3, $bbs)) {
		if ($oSET->Get('BBS_MAIL_COUNT') < length($mail)) {
			return 102;
		}
	}
	# 名前欄の入力確認
	if (! $oSEC->IsAuthority($capID, 7, $bbs)) {
		if ($oSET->Equal('NANASHI_CHECK', 'checked') && $name eq '') {
			return 152;
		}
	}
	# 名無し設定
	unless ($name) { $name = $oSET->Get('BBS_NONAME_NAME'); }
	unless ($mail) { $mail = ''; }
	
	# 正規化した内容を再度設定
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	テキスト欄の正規化
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my ($Sys) = @_;
	my ($Form, $oSEC, $oSET);
	my ($text, $bbs, $host, $ln, $cl, $capID);
	
	$Form		= $Sys->{'FORM'};
	$oSEC		= $Sys->{'SECURITY'};
	$oSET		= $Sys->{'SET'};
	$bbs		= $Form->Get('bbs');
	$text		= $Form->Get('MESSAGE');
	$host		= $Form->Get('HOST');
	$capID		= $Sys->{'SYS'}->Get('CAPID');
	
	# 禁則文字変換
	$Sys->{'CONV'}->ConvertCharacter2(\$text, 2);
	
	($ln, $cl)	= $Sys->{'CONV'}->GetTextInfo(\$text);
	
	# 本文が無い
	if ($text eq '') {
		return 151;
	}
	# 本文が長すぎ
	if (! $oSEC->IsAuthority($capID, 4, $bbs)) {
		if ($oSET->Get('BBS_MESSAGE_COUNT') < length($text)) {
			return 103;
		}
	}
	# 改行が多すぎ
	if (! $oSEC->IsAuthority($capID, 5, $bbs)) {
		if (($oSET->Get('BBS_LINE_NUMBER') * 2) < $ln) {
			return 105;
		}
	}
	# 1行が長すぎ
	if (! $oSEC->IsAuthority($capID, 6, $bbs)) {
		if ($oSET->Get('BBS_COLUMN_NUMBER') < $cl) {
			return 104;
		}
	}
	# アンカーが多すぎ
	if ($Sys->{'SYS'}->Get('ANKERS')) {
		if ($Sys->{'CONV'}->IsAnker(\$text, $Sys->{'SYS'}->Get('ANKERS'))) {
			return 106;
		}
	}
	
	# 本文ホスト表示
	if (! $oSEC->IsAuthority($capID, 15, $bbs)) {
		if ($oSET->Equal('BBS_RAWIP_CHECK', 'checked') && $Sys->{'SYS'}->Equal('MODE', 1)) {
			$text .= ' <hr> <font color=tomato face=Arial><b>';
			$text .= "$ENV{'REMOTE_ADDR'} , $host , </b></font><br>";
		}
	}
	
	$Form->Set('MESSAGE', $text);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	1001のレスデータを設定する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001レス格納バッファ
#
#------------------------------------------------------------------------------------------------------------
sub Get1001Data
{
	my ($Sys, $data) = @_;
	my $endPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/1000.txt';
	
	# 1000.txtが存在すればその内容、無ければデフォルトの1001を使用する
	if (-e $endPath) {
		open LAST, $endPath;
		while (<LAST>) {
			$$data = $_;
			last;
		}
		close LAST;
	}
	else {
		$$data = '１００１<><>Over 1000 Thread<>このスレッドは１０００を超えました。<br>';
		$$data .= 'もう書けないので、新しいスレッドを立ててくださいです。。。<>' . "\n";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ホストログを出力する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001レス格納バッファ
#
#------------------------------------------------------------------------------------------------------------
sub SaveHost
{
	my ($Sys, $Form) = @_;
	my ($Logger, $bbs);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/log/HOST", 500, 2 | 4) == 0) {
		$Logger->Put($Form->Get('HOST'), $Sys->Get('KEY'), $Sys->Get('MODE'));
		$Logger->Write();
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	履歴ログを出力する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$resNum	書き込みレス番
#
#------------------------------------------------------------------------------------------------------------
sub SaveHistory
{
	my ($Sys, $Form, $resNum) = @_;
	my ($Logger, $bbs, $threadInfo, $name, $content);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	$threadInfo = $Sys->Get('BBS') . ',' . $Sys->Get('KEY');
	$name = $Form->Get('FROM');
	$content = $Form->Get('MESSAGE');
	
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/info/history", $Sys->Get('HISMAX'), 2 | 4) == 0) {
		$Logger->Put($threadInfo, $resNum, $content, $name);
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

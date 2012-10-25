#============================================================================================================
#
#	掲示板書き込み支援モジュール
#
#============================================================================================================
package	VARA;

use strict;
use warnings;
no warnings qw(once);

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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef,
	};
	bless $obj, $class;
	
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
	
	$this->{'SYS'} = $Sys;
	$this->{'FORM'} = $Form;
	$this->{'SET'} = $Set;
	$this->{'THREADS'} = $Thread;
	$this->{'CONV'} = $Conv;
	
	# モジュールが用意されてない場合はここで生成する
	if (!defined $Set) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	if (!defined $Thread) {
		require './module/baggins.pl';
		$this->{'THREADS'} = BILBO->new;
		$this->{'THREADS'}->Load($Sys);
	}
	if (!defined $Conv) {
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
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	
	# 書き込み前準備
	$this->ReadyBeforeCheck();
	
	my $err = 0;
	
	# 入力内容チェック(名前、メール)
	return $err if ($err = $this->NormalizationNameMail());
	
	# 入力内容チェック(本文)
	return $err if ($err = $this->NormalizationContents());
	
	# 規制チェック
	return $err if ($err = $this->IsRegulation());
	
	
	# データの書き込み
	require './module/gondor.pl';
	my $oSys = $this->{'SYS'};
	my $oSet = $this->{'SET'};
	my $oForm = $this->{'FORM'};
	my $oConv = $this->{'CONV'};
	my $oThread = $this->{'THREADS'};
	
	# 書き込み直前処理
	$err = $this->ReadyBeforeWrite(ARAGORN::GetNumFromFile($oSys->Get('DATPATH')) + 1);
	return $err if ($err);
	
	# レス要素の取得
	my @elem = ();
	$oForm->GetListData(\@elem, 'subject', 'FROM', 'mail', 'MESSAGE');
	
	$err = 0;
	my $id	 = $oConv->MakeID($oSys->Get('SERVER'), $oSys->Get('CLIENT'), $oSys->Get('KOYUU'), $oSys->Get('BBS'), 8);
	my $date = $oConv->GetDate($oSet, $oSys->Get('MSEC'));
	$date .= $oConv->GetIDPart($oSet, $oForm, $this->{'SECURITY'}, $id, $oSys->Get('CAPID'), $oSys->Get('KOYUU'), $oSys->Get('AGENT'));
	
	# プラグイン「 BE(HS)っぽいもの 」ver.0.x.x
	my $beid = $oForm->Get('BEID', '');
	$date .= " $beid" if ($beid ne '');
	
	my $data = join('<>', $elem[1], $elem[2], $date, $elem[3], $elem[0]);
	my $data2 = "$data\n";
	my $datPath = $oSys->Get('DATPATH');
	
	# ログ書き込み
	require './module/peregrin.pl';
	my $LOG = PEREGRIN->new;
	$LOG->Load($oSys, 'WRT', $oSys->Get('KEY'));
	$LOG->Set($oSet, length($oForm->Get('MESSAGE')), $oSys->Get('VERSION'), $oSys->Get('KOYUU'), $data, $oSys->Get('AGENT', 0));
	$LOG->Save($oSys);
	
	# リモートホスト保存(SETTING.TXT変更により、常に保存)
	SaveHost($oSys, $oForm);
	
	# datファイルへ直接書き込み
	my $resNum = 0;
	$err = ARAGORN::DirectAppend($oSys, $datPath, $data2);
	if ($err == 0) {
		# レス数が最大数を超えたらover設定をする
		$resNum = ARAGORN::GetNumFromFile($datPath);
		if ($resNum >= $oSys->Get('RESMAX')) {
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
	
	if ($err == 0) {
		# subject.txtの更新
		# スレッド作成モードなら新規に追加する
		if ($oSys->Equal('MODE', 1)) {
			require './module/earendil.pl';
			my $path = $oSys->Get('BBSPATH') . '/' . $oSys->Get('BBS');
			my $oPools = FRODO->new;
			$oPools->Load($oSys);
			$oThread->Add($oSys->Get('KEY'), $elem[0], 1);
			
			while ($oThread->GetNum() > $oSys->Get('SUBMAX')) {
				my $lid = $oThread->GetLastID();
				$oPools->Add($lid, $oThread->Get('SUBJECT', $lid), $oThread->Get('RES', $lid));
				$oThread->Delete($lid);
				EARENDIL::Copy("$path/dat/$lid.dat", "$path/pool/$lid.cgi");
				unlink "$path/dat/$lid.dat";
			}
			
			$oPools->Save($oSys);
			$oThread->Save($oSys);
		}
		# 書き込みモードならレス数の更新
		else {
			my $sage = (!$oForm->Contain('mail', 'sage') ? 1 : 0);
			$oThread->OnDemand($oSys, $oSys->Get('KEY'), $resNum, $sage);
		}
	}
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	前準備
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my ($this) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	
	# cookie用にオリジナルを保存する
	my $from = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	$from =~ s/[\r\n]//g;
	$mail =~ s/[\r\n]//g;
	$Form->Set('NAME', $from);
	$Form->Set('MAIL', $mail);
	
	# キャップパスの抽出と削除
	$Sys->Set('CAPID', '');
	if ($mail =~ s/(?:#|＃)(.+)//) {
		my $capPass = $1;
		
		# キャップ情報設定
		my $capID = $this->{'SECURITY'}->GetCapID($capPass);
		$Sys->Set('CAPID', $capID);
		$Form->Set('mail', $mail);
	}
	
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
#	@param	なし
#	@param	$res
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeWrite
{
	my $this = shift;
	my ($res) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $from = $Form->Get('FROM');
	my $koyuu = $Sys->Get('KOYUU');
	my $client = $Sys->Get('CLIENT');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	
	# 規制ユーザ・NGワードチェック
	{
		# 規制ユーザ
		require './module/faramir.pl';
		my $vUser = FARAMIR->new;
		$vUser->Load($Sys);
		
		my $koyuu2 = ($client & $ZP::C_MOBILE_IDGET & ~$ZP::C_P2 ? $koyuu : undef);
		my $check = $vUser->Check($host, $addr, $koyuu2);
		return 601 if ($check == 4);
		if ($check == 2) {
			return 601 if ($from !~ /$host/i); # $hostは正規表現
			$Form->Set('FROM', "</b>[´･ω･｀] <b>$from");
		}
		
		# NGワード
		require './module/wormtongue.pl';
		my $ngWord = WORMTONGUE->new;
		$ngWord->Load($Sys);
		my @checkKey = ('FROM', 'mail', 'MESSAGE');
		
		$check = $ngWord->Check($this->{'FORM'}, \@checkKey);
		return 600 if ($check == 3);
		$ngWord->Method($Form, \@checkKey) if ($check == 1);
		$Form->Set('FROM', "</b>[´+ω+｀] $host <b>$from") if ($check == 2);
	}
	
	# pluginに渡す値を設定
	$Sys->Set('_ERR', 0);
	$Sys->Set('_NUM_', $res);
	$Sys->Set('_THREAD_', $this->{'THREADS'});
	$Sys->Set('_SET_', $this->{'SET'});
	
	$this->ExecutePlugin(16);
	
	my $text = $Form->Get('MESSAGE');
	$text =~ s/<br>/ <br> /g;
	$Form->Set('MESSAGE', " $text ");
	
	# 名無し設定
	$from = $Form->Get('FROM');
	unless ($from) {
		$from = $this->{'SET'}->Get('BBS_NONAME_NAME');
		$Form->Set('FROM', $from);
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン処理
#	-------------------------------------------------------------------------------------
#	@param	$type
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub ExecutePlugin
{
	my $this = shift;
	my ($type) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Plugin = $this->{'PLUGIN'};
	
	# 有効な拡張機能一覧を取得
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	foreach my $id (@pluginSet) {
		# タイプが先呼び出しの場合はロードして実行
		if ($Plugin->Get('TYPE', $id) & $type) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			require "./plugin/$file";
			my $Config = PLUGINCONF->new($Plugin, $id);
			my $command = $className->new($Config);
			$command->execute($Sys, $Form, $type);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	規制チェック
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my $this = shift;
	
	my $oSYS = $this->{'SYS'};
	my $oSET = $this->{'SET'};
	my $oSEC = $this->{'SECURITY'};
	
	my $bbs = $this->{'FORM'}->Get('bbs');
	my $from = $this->{'FORM'}->Get('FROM');
	my $capID = $oSYS->Get('CAPID', '');
	my $datPath = $oSYS->Get('DATPATH');
	my $client = $oSYS->Get('CLIENT');
	my $mode = $oSYS->Get('AGENT');
	my $koyuu = $oSYS->Get('KOYUU');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	my $islocalip = 0;
	
	$islocalip = 1 if ($addr =~ /^(127|172|192|10)\./);
	
	# レス書き込みモード時のみ
	if ($oSYS->Equal('MODE', 2)) {
		require './module/gondor.pl';
		
		# 移転スレッド
		return 202 if (ARAGORN::IsMoved($datPath));
		
		# レス最大数
		return 201 if ($oSYS->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath));
		
		# datファイルサイズ制限
		if ($oSET->Get('BBS_DATMAX')) {
			my $datSize = int((stat $datPath)[7] / 1024);
			return 206 if ($oSET->Get('BBS_DATMAX') < $datSize);
		}
	}
	# REFERERチェック
	if ($oSET->Equal('BBS_REFERER_CHECK', 'checked')) {
		return 998 if ($this->{'CONV'}->IsReferer($this->{'SYS'}, \%ENV));
	}
	# PROXYチェック
	if (!$islocalip && !$oSET->Equal('BBS_PROXY_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsProxy($this->{'SYS'}, $this->{'FORM'}, $from, $mode)) {
			#$this->{'FORM'}->Set('FROM', "</b> [―\{}\@{}\@{}-] <b>$from");
			return 997 if (!$oSEC->IsAuthority($capID, 19, $bbs));
		}
	}
	# 読取専用
	if (!$oSET->Equal('BBS_READONLY', 'none')) {
		return 203 if (!$oSEC->IsAuthority($capID, 13, $bbs));
	}
	# JPホスト以外規制
	if (!$islocalip && $oSET->Equal('BBS_JP_CHECK', 'checked')) {
		return 207 unless ($host =~ /\.jp$/i);
	}
	
	# スレッド作成モード
	if ($oSYS->Equal('MODE', 1)) {
		# スレッドキーが重複しないようにする
		my $tPath = $oSYS->Get('BBSPATH') . '/' . $oSYS->Get('BBS') . '/dat/';
		my $key = $oSYS->Get('KEY');
		$key++ while (-e "$tPath$key.dat");
		$oSYS->Set('KEY', $key);
		$datPath = "$tPath$key.dat";
		
		# スレッド作成(携帯から)
		if ($client & $ZP::C_MOBILE) {
			return 204 if (!$oSEC->IsAuthority($capID, 16, $bbs));
		}
		# スレッド作成(キャップのみ)
		if ($oSET->Equal('BBS_THREADCAPONLY', 'checked')) {
			return 504 if (!$oSEC->IsAuthority($capID, 9, $bbs));
		}
		# スレッド作成(スレッド立てすぎ)
		require './module/peregrin.pl';
		my $LOG = PEREGRIN->new;
		$LOG->Load($oSYS, 'THR');
		if (!$oSEC->IsAuthority($capID, 8, $bbs)) {
			my $tateHour = $oSET->Get('BBS_TATESUGI_HOUR', '0') - 0;
			my $tateCount = $oSET->Get('BBS_TATESUGI_COUNT', '0') - 0;
			my $checkCount = $oSET->Get('BBS_THREAD_TATESUGI', '0') - 0;
			return 500 if ($tateHour ne 0 && $LOG->IsTatesugi($tateHour) ge $tateCount);
			return 500 if ($LOG->Search($koyuu, 3, $mode, $host, $checkCount));
		}
		$LOG->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $koyuu, undef, $mode);
		$LOG->Save($oSYS);
		
		# Sambaログ
		if (!$oSEC->IsAuthority($capID, 18, $bbs) || !$oSEC->IsAuthority($capID, 12, $bbs)) {
			my $LOGs = PEREGRIN->new;
			$LOGs->Load($oSYS, 'SMB');
			$LOGs->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $koyuu);
			$LOGs->Save($oSYS);
		}
	}
	# レス書き込みモード
	else {
		require './module/peregrin.pl';
		
		if (!$oSEC->IsAuthority($capID, 18, $bbs) || !$oSEC->IsAuthority($capID, 12, $bbs)) {
			my $LOGs = PEREGRIN->new;
			$LOGs->Load($oSYS, 'SMB');
			
			my $LOGh = PEREGRIN->new;
			$LOGh->Load($oSYS, 'SBH');
			
			my $n = 0;
			my $tm = 0;
			my $Samba = int($oSET->Get('BBS_SAMBATIME', '') eq '' ? $oSYS->Get('DEFSAMBA') : $oSET->Get('BBS_SAMBATIME'));
			my $Houshi = int($oSET->Get('BBS_HOUSHITIME', '') eq '' ? $oSYS->Get('DEFHOUSHI') : $oSET->Get('BBS_HOUSHITIME'));
			my $Holdtm = int($oSYS->Get('SAMBATM'));
			
			# Samba
			if ($Samba && !$oSEC->IsAuthority($capID, 18, $bbs)) {
				if ($Houshi) {
					my ($ishoushi, $htm) = $LOGh->IsHoushi($Houshi, $koyuu);
					if ($ishoushi) {
						$oSYS->Set('WAIT', $htm);
						return 507;
					}
				}
				
				($n, $tm) = $LOGs->IsSamba($Samba, $koyuu);
			}
				
			# 短時間投稿 (Samba優先)
			if (!$n && $Holdtm && !$oSEC->IsAuthority($capID, 12, $bbs)) {
				$tm = $LOGs->IsTime($Holdtm, $koyuu);
			}
			
			$LOGs->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $koyuu);
			$LOGs->Save($oSYS);
			
			if ($n >= 6 && $Houshi) {
				$LOGh->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $koyuu);
				$LOGh->Save($oSYS);
				$oSYS->Set('WAIT', $Houshi);
				return 507;
			}
			elsif ($n) {
				$oSYS->Set('SAMBATIME', $Samba);
				$oSYS->Set('WAIT', $tm);
				$oSYS->Set('SAMBA', $n);
				return ($n > 3 && $Houshi ? 506 : 505);
			}
			elsif ($tm > 0) {
				$oSYS->Set('WAIT', $tm);
				return 503;
			}
		}
		
		# レス書き込み(連続投稿)
		if (!$oSEC->IsAuthority($capID, 10, $bbs)) {
			if ($oSET->Get('timeclose') && $oSET->Get('timecount') ne '') {
				my $LOG = PEREGRIN->new;
				$LOG->Load($oSYS, 'HST');
				my $cnt = $LOG->Search($koyuu, 2, $mode, $host, $oSET->Get('timecount'));
				return 501 if ($cnt >= $oSET->Get('timeclose'));
			}
		}
		# レス書き込み(二重投稿)
		if (!$oSEC->IsAuthority($capID, 11, $bbs)) {
			if ($this->{'SYS'}->Get('KAKIKO') eq 1) {
				my $LOG = PEREGRIN->new;
				$LOG->Load($oSYS, 'WRT', $oSYS->Get('KEY'));
				return 502 if ($LOG->Search($koyuu, 1) - 2 == length($this->{'FORM'}->Get('MESSAGE')));
			}
		}
		
		#$LOG->Set($oSET, length($this->{'FORM'}->Get('MESSAGE')), $oSYS->Get('VERSION'), $koyuu, $datas, $mode);
		#$LOG->Save($oSYS);
	}
	
	# パスを保存
	$oSYS->Set('DATPATH', $datPath);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	名前・メール欄の正規化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $oSEC = $this->{'SECURITY'};
	my $oSET = $this->{'SET'};
	
	my $name = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	my $subject = $Form->Get('subject');
	my $bbs = $Form->Get('bbs');
	my $host = $ENV{'REMOTE_HOST'};
	
	# キャップ情報取得
	my $capID = $Sys->Get('CAPID', '');
	my $capName = '';
	my $capColor = '';
	if ($capID && $oSEC->IsAuthority($capID, 17, $bbs)) {
		$capName = $oSEC->Get($capID, 'NAME', 1, '');
		$capColor = $oSEC->Get($oSEC->{'GROUP'}->GetBelong($capID), 'COLOR', 0, '');
		$capColor = $oSET->Get('BBS_CAP_COLOR', '') if ($capColor eq '');
	}
	
	# ＃ -> #
	$this->{'CONV'}->ConvertCharacter0(\$name);
	
	# トリップ変換
	my $trip = '';
	if ($name =~ /\#(.*)$/x) {
		$trip = $this->{'CONV'}->ConvertTrip(\$1, $oSET->Get('BBS_TRIPCOLUMN'), $Sys->Get('TRIP12'));
	}
	
	# 特殊文字変換 フォーム情報再設定
	$this->{'CONV'}->ConvertCharacter1(\$name, 0);
	$this->{'CONV'}->ConvertCharacter1(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter1(\$subject, 3);
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	$Form->Set('TRIPKEY', $trip);
	
	# プラグイン実行 フォーム情報再取得
	$this->ExecutePlugin($Sys->Get('MODE'));
	$name = $Form->Get('FROM', '');
	$mail = $Form->Get('mail', '');
	$subject = $Form->Get('subject', '');
	$bbs = $Form->Get('bbs');
	$host = $Form->Get('HOST');
	$trip = $Form->Get('TRIPKEY', '???');
	
	# 2ch互換
	$name =~ s/^ //;
	
	# 禁則文字変換
	$this->{'CONV'}->ConvertCharacter2(\$name, 0);
	$this->{'CONV'}->ConvertCharacter2(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter2(\$subject, 3);
	
	# トリップと名前を結合する
	$name =~ s|\#.*$| </b>◆$trip <b>|x if ($trip ne '');
	
	# fusiana変換 2ch互換
	$this->{'CONV'}->ConvertFusianasan(\$name, $host);
	
	# キャップ名結合
	if ($capName ne '') {
		$name = ($name ne '' ? "$name＠" : '');
		if ($capColor eq '') {
			$name .= "$capName ★";
		}
		else {
			$name .= "<font color=\"$capColor\">$capName ★</font>";
		}
	}
	
	
	# スレッド作成時
	if ($Sys->Equal('MODE', 1)) {
		return 150 if ($subject eq '');
		# サブジェクト欄の文字数確認
		if (!$oSEC->IsAuthority($capID, 1, $bbs)) {
			return 101 if ($oSET->Get('BBS_SUBJECT_COUNT') < length($subject));
		}
	}
	
	# 名前欄の文字数確認
	if (! $oSEC->IsAuthority($capID, 2, $bbs)) {
		return 101 if ($oSET->Get('BBS_NAME_COUNT') < length($name));
	}
	# メール欄の文字数確認
	if (! $oSEC->IsAuthority($capID, 3, $bbs)) {
		return 102 if ($oSET->Get('BBS_MAIL_COUNT') < length($mail));
	}
	# 名前欄の入力確認
	if (! $oSEC->IsAuthority($capID, 7, $bbs)) {
		return 152 if ($oSET->Equal('NANASHI_CHECK', 'checked') && $name eq '');
	}
	
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
#	@param	なし
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my $this = shift;
	
	my $Form = $this->{'FORM'};
	my $oSEC = $this->{'SECURITY'};
	my $oSET = $this->{'SET'};
	my $oSYS = $this->{'SYS'};
	my $oConv = $this->{'CONV'};
	
	my $bbs = $Form->Get('bbs');
	my $text = $Form->Get('MESSAGE');
	my $host = $Form->Get('HOST');
	my $capID = $this->{'SYS'}->Get('CAPID', '');
	
	# 禁則文字変換
	$oConv->ConvertCharacter2(\$text, 2);
	
	my ($ln, $cl) = $oConv->GetTextInfo(\$text);
	
	# 本文が無い
	return 151 if ($text eq '');
	
	# 本文が長すぎ
	if (!$oSEC->IsAuthority($capID, 4, $bbs)) {
		return 103 if ($oSET->Get('BBS_MESSAGE_COUNT') < length($text));
	}
	# 改行が多すぎ
	if (!$oSEC->IsAuthority($capID, 5, $bbs)) {
		return 105 if (($oSET->Get('BBS_LINE_NUMBER') * 2) < $ln);
	}
	# 1行が長すぎ
	if (!$oSEC->IsAuthority($capID, 6, $bbs)) {
		return 104 if ($oSET->Get('BBS_COLUMN_NUMBER') < $cl);
	}
	# アンカーが多すぎ
	if ($oSYS->Get('ANKERS')) {
		return 106 if ($oConv->IsAnker(\$text, $oSYS->Get('ANKERS')));
	}
	
	# 本文ホスト表示
	if (!$oSEC->IsAuthority($capID, 15, $bbs)) {
		if ($oSET->Equal('BBS_RAWIP_CHECK', 'checked') && $oSYS->Equal('MODE', 1)) {
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
	if (open(my $fh, '<', $endPath)) {
		flock($fh, 2);
		$$data = <$fh>;
		close($fh);
	}
	else {
		my $resmax = $Sys->Get('RESMAX');
		my $resmax1 = $resmax + 1;
		my $resmaxz = $resmax;
		my $resmaxz1 = $resmax1;
		$resmaxz =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # 全角数字
		$resmaxz1 =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # 全角数字
		
		$$data = "$resmaxz1<><>Over $resmax Thread<>このスレッドは$resmaxzを超えました。<br>";
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
	
	my $bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	my $host = $ENV{'REMOTE_HOST'};
	my $agent = $Sys->Get('AGENT');
	my $koyuu = $Sys->Get('KOYUU');
	
	if ($agent ne '0') {
		if ($agent eq 'P') {
			$host = "$host($koyuu)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$host($koyuu)";
		}
	}
	
	require './module/imrahil.pl';
	my $Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/log/HOST", 500, 2 | 4) == 0) {
		$Logger->Put($host, $Sys->Get('KEY'), $Sys->Get('MODE'));
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
	
	my $bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	my $threadInfo = $Sys->Get('BBS') . ',' . $Sys->Get('KEY');
	my $name = $Form->Get('FROM');
	my $content = $Form->Get('MESSAGE');
	
	require './module/imrahil.pl';
	my $Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/info/history", $Sys->Get('HISMAX'), 2 | 4) == 0) {
		$Logger->Put($threadInfo, $resNum, $content, $name);
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

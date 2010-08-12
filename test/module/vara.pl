#============================================================================================================
#
#	掲示板書き込み支援モジュール
#	vara.pl
#	-------------------------------------------------------------------------------------
#	2004.03.27 start
#
#============================================================================================================
package	VARA;

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
	my		$obj = {};
	
	$obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef
	};
	bless($obj,$this);
	
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
	my		$this = shift;
	my		($Sys,$Form,$Set,$Thread,$Conv) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'SET'}		= $Set;
	$this->{'THREADS'}	= $Thread;
	$this->{'CONV'}		= $Conv;
	
	# モジュールが用意されてない場合はここで生成する
	if	($Set eq undef){
		require('./module/isildur.pl');
		$this->{'SET'}	= new ISILDUR;
		$this->{'SET'}->Load($Sys);
	}
	if	($Thread eq undef){
		require('./module/baggins.pl');
		$this->{'THREADS'}	= new BILBO;
		$this->{'THREADS'}->Load($Sys);
	}
	if	($Conv eq undef){
		require('./module/galadriel.pl');
		$this->{'CONV'}	= new GALADRIEL;
	}
	
	# キャップ管理モジュールロード
	require('./module/ungoliants.pl');
	$this->{'SECURITY'} = new SECURITY;
	$this->{'SECURITY'}->Init($Sys);
	$this->{'SECURITY'}->SetGroupInfo($Sys->Get('BBS'));
	
	# 拡張機能情報管理モジュールロード
	require('./module/athelas.pl');
	$this->{'PLUGIN'} = new ATHELAS;
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
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my		$this = shift;
	my		($err);
	
	# 書き込み前準備
	ReadyBeforeCheck($this);
	
	# 入力内容チェック(名前、メール)
	if	(($err = NormalizationNameMail($this))){
		return $err;
	}
	# 入力内容チェック(本文)
	if	(($err = NormalizationContents($this))){
		return $err;
	}
	# 規制チェック
	if	(($err = IsRegulation($this))){
		return $err;
	}
	
	# データの書き込み
	eval{
		my	($oSys,$oSet,$oForm,$oConv);
		my	(@elem,$date,$data,$resNum,$datPath,$id);
		
		require('./module/gondor.pl');
		$oSys		= $this->{'SYS'};
		$oSet		= $this->{'SET'};
		$oForm		= $this->{'FORM'};
		$oConv		= $this->{'CONV'};
		
		# 書き込み直前処理
		ReadyBeforeWrite($this,ARAGORN::GetNumFromFile($oSys->Get('DATPATH')) + 1);
		
		# レス要素の取得
		$oForm->GetListData(\@elem,'subject','FROM','mail','MESSAGE');
		
		$err		= 0;
		$id			= $oConv->MakeID($oSys->Get('SERVER'),8);
		$date		= $oConv->GetDate($oSet);
		$date		= $date . $oConv->GetIDPart($oSet,$oForm,$this->{'SECURITY'},$id,$oSys->Get('CAPID'),$oSys->Get('AGENT'));
		$data		= "$elem[1]<>$elem[2]<>$date<>$elem[3]<>$elem[0]\n";
		$datPath	= $oSys->Get('DATPATH');
		
		# リモートホスト保存(SETTING.TXT変更により、常に保存)
		SaveHost($oSys,$oForm);
		
		# datファイルへ直接書き込み
		eval{
			if	(($err = ARAGORN::DirectAppend($oSys,$datPath,$data)) == 0){
				# レス数が最大数を超えたらover設定をする
				if	(($resNum = ARAGORN::GetNumFromFile($datPath)) >= $oSys->Get('RESMAX')){
					# datにOVERスレッドレスを書き込む
					Get1001Data($oSys,\$data);
					ARAGORN::DirectAppend($oSys,$datPath,$data);
					$resNum ++;
				}
				# 履歴保存
				SaveHistory($oSys,$oForm,ARAGORN::GetNumFromFile($datPath));
			}
			# datファイル追記失敗
			else{
				$err = 999	if	($err == 1);
				$err = 200	if	($err == 2);
			}
		};
		if	($err == 0 && $@ eq ''){
			# subject.txtの更新
			# スレッド作成モードなら新規に追加する
			if	($oSys->Equal('MODE',1)){
				$this->{'THREADS'}->Add($oSys->Get('KEY'),$elem[0],1);
			}
			# 書き込みモードならレス数の更新
			else{
				$this->{'THREADS'}->Set($oSys->Get('KEY'),'RES',$resNum);
				# sageが入っていなかったらageる
				if	(!$oForm->Contain('mail','sage')){
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
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my		($this) = @_;
	my		($Sys,$Form,$Plugin,$id,@pluginSet,$type);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	$Plugin = $this->{'PLUGIN'};
	
	# cookie用にオリジナルを保存する
	my ($from,$mail);
	$from = $Form->Get('FROM');
	$mail = $Form->Get('mail');
	$from =~ s/<br>//g;
	$mail =~ s/<br>//g;
	$Form->Set('NAME',$from);
	$Form->Set('MAIL',$mail);
	$Form->Set('FROM',$from);
	$Form->Set('mail',$mail);
	
	# キャップパスの抽出と削除
	if	($mail =~ /(#|＃)(.+)/){
		my	($capPass,$capID);
		
		$mail =~ s/＃/#/;
		$mail =~ s/#(.+)//;
		$capPass = $1;
		
		# キャップ情報設定
		$capID = $this->{'SECURITY'}->GetCapID($capPass);
		if	($capID){
			$Sys->Set('CAPID',$capID);
		}
		$Form->Set('mail',$mail);
	}
	
	# datパスの生成
	my $datPath	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
	$Sys->Set('DATPATH',$datPath);
	
	# 有効な拡張機能一覧を取得
	$Plugin->GetKeySet('VALID',1,\@pluginSet);
	$type = $Sys->Get('MODE');
	foreach $id (@pluginSet){
		# タイプが先呼び出しの場合はロードして実行
		if($Plugin->Get('TYPE',$id) & $type){
			my $file = $Plugin->Get('FILE',$id);
			my $className = $Plugin->Get('CLASS',$id);
			my $command;
			require("./plugin/$file");
			$command = new $className;
			$command->execute($Sys,$Form,$type);
		}
	}
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
	my	($this,$res) = @_;
	my	($Sys,$Form,$Plugin,$id,@pluginSet);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	$Plugin = $this->{'PLUGIN'};
	
	# pluginに渡す値を設定
	$Sys->Set('_ERR',0);
	$Sys->Set('_NUM_',$res);
	$Sys->Set('_THREAD_',$this->{'THREADS'});
	$Sys->Set('_SET_',$this->{'SET'});
	
	# 有効な拡張機能一覧を取得
	$Plugin->GetKeySet('VALID',1,\@pluginSet);
	foreach $id (@pluginSet){
		if($Plugin->Get('TYPE',$id) & 16){
			my $file = $Plugin->Get('FILE',$id);
			my $className = $Plugin->Get('CLASS',$id);
			my $command;
			require("./plugin/$file");
			$command = new $className;
			$command->execute($Sys,$Form,16);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	規制チェック
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	規制通過なら0を返す
#			規制チェックにかかったらエラーコードを返す
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my		($this) = @_;
	my		($oSYS,$oSET,$oSEC);
	my		($err,$host,$bbs,$datPath,$capID);
	
	$oSYS		= $this->{'SYS'};
	$oSET		= $this->{'SET'};
	$oSEC		= $this->{'SECURITY'};
	$host		= $this->{'FORM'}->Get('HOST');
	$bbs		= $this->{'FORM'}->Get('BBS');
	$capID		= $oSYS->Get('CAPID');
	$datPath	= $oSYS->Get('DATPATH');
	
	# 規制ユーザ・NGワードチェック
	{
		my	($vUser,$ngWord,$check,@checkKey);
		# 規制ユーザ
		require('./module/faramir.pl');
		$vUser = new FARAMIR;
		$vUser->Load($oSYS);
		$check = $vUser->Check($host);
		if	($check == 4){
			return 601;
		}
		if	($check == 2){
			$this->{'FORM'}->Set('FROM',"<font color=tomato>$host</font>");
		}
		# NGワード
		require('./module/wormtongue.pl');
		$ngWord = new WORMTONGUE;
		$ngWord->Load($oSYS);
		@checkKey = ('FROM','mail','MESSAGE');
		$check = $ngWord->Check($this->{'FORM'},\@checkKey);
		if	($check == 3){
			return 600;
		}
		if	($check == 1){
			$ngWord->Method($this->{'FORM'},\@checkKey);
		}
		if	($check == 2){
			$this->{'FORM'}->Set('FROM',$this->{'FORM'}->Get('FROM') . "<font color=tomato>$host</font>");
		}
	}
	
	# レス書き込みモード時のみ
	if	($oSYS->Equal('MODE',2)){
		require('./module/gondor.pl');
		
		# 移転スレッド
		if	(ARAGORN::IsMoved($datPath)){
			return 202;
		}
		# レス最大数
		if	($oSYS->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath)){
			return 201;
		}
		# datファイルサイズ制限
		if	($oSET->Get('BBS_DATMAX')){
			my $datSize	= int((stat($datPath))[7] / 1024);
			if	($oSET->Get('BBS_DATMAX') < $datSize){
				return 206;
			}
		}
	}
	# REFERERチェック
	if	($oSET->Equal('BBS_REFERER_CHECK','checked')){
		if	($this->{'CONV'}->IsReferer($this->{'SYS'},\%ENV)){
			return 998;
		}
	}
	# PROXYチェック
	if	($oSET->Equal('BBS_PROXY_CHECK','checked')){
		if	($this->{'CONV'}->IsProxy(\$host)){
			return 997;
		}
	}
	# 読取専用
	if	(!$oSET->Equal('BBS_READONLY','none')){
		if	(!$oSEC->IsAuthority($capID,13,$bbs)){
			return 203;
		}
	}
	# JPホスト以外規制
	if	($oSET->Equal('BBS_JP_CHECK','checked')){
		unless	($host =~ /\.(jp|JP)$/){
			return 207;
		}
	}
	
	# スレッド作成モード
	if	($oSYS->Equal('MODE',1)){
		# スレッドキーが重複しないようにする
		my	$tPath = $oSYS->Get('BBSPATH') . '/' . $oSYS->Get('BBS') . '/dat/';
		my	$key = $oSYS->Get('KEY');
		while	(-e $tPath . $key . '.dat'){
			$key ++;
		}
		$oSYS->Set('KEY',$key);
		$datPath = $tPath . $key . '.dat';
		
		# スレッド作成(携帯から)
		if	($oSYS->Get('AGENT') != 0){
			if	(!$oSEC->IsAuthority($capID,16,$bbs)){
				return 204;
			}
		}
		# スレッド作成(キャップのみ)
		if	($oSET->Equal('BBS_THREADCAPONLY','checked')){
			if	(!$oSEC->IsAuthority($capID,9,$bbs)){
				return 504;
			}
		}
		# スレッド作成(スレッド立てすぎ)
		require('./module/peregrin.pl');
		my	$LOG = new PEREGRIN;
		$LOG->Load($oSYS,'THR');
		if	(!$oSEC->IsAuthority($capID,8,$bbs)){
			if	($LOG->Search($host,1)){
				return 500;
			}
		}
		$LOG->Set($oSET,$oSYS->Get('KEY'),$oSYS->Get('VERSION'),$host);
		$LOG->Save($oSYS);
	}
	# レス書き込みモード
	else{
		require('./module/peregrin.pl');
		my	$LOG = new PEREGRIN;
		$LOG->Load($oSYS,'WRT',$oSYS->Get('KEY'));
		# レス書き込み(連続投稿)
		if	(!$oSEC->IsAuthority($capID,10,$bbs)){
			if	($LOG->Search($host,2) >= $oSET->Get('timeclose')){
				return 501;
			}
		}
		# レス書き込み(二重投稿)
		if	(!$oSEC->IsAuthority($capID,11,$bbs)){
			if	($LOG->Search($host,1) == length($this->{'FORM'}->Get('MESSAGE'))){
				return 502;
			}
		}
		# Samba規制
		
		# 短時間投稿
		if	(!$oSEC->IsAuthority($capID,12,$bbs)){
			my $tm = $LOG->IsTime(60,$host);
			if	($tm > 0){
				$oSYS->Set('WAIT',$tm);
				return 503;
			}
		}
		$LOG->Set($oSET,length($this->{'FORM'}->Get('MESSAGE')),$oSYS->Get('VERSION'),$host);
		$LOG->Save($oSYS);
	}
	
	# パスを保存
	$oSYS->Set('DATPATH',$datPath);
	
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
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my		($this) = @_;
	my		($Form,$oSEC,$oSET,$Sys);
	my		($name,$mail,$subject,$bbs);
	my		($capName,$capID);
	
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
	if	($capID && $oSEC->IsAuthority($capID,17,$bbs)){
		$capName = $oSEC->Get($capID,'NAME',1);
	}
	
	# スレッド作成時
	if	($Sys->Equal('MODE',1)){
		if	($subject eq ''){
			return 150;
		}
		# サブジェクト欄の文字数確認
		if	(!$oSEC->IsAuthority($capID,1,$bbs)){
			if	($oSET->Get('BBS_SUBJECT_COUNT') < length($subject)){
				return 101;
			}
		}
	}
	
	# 名前欄の文字数確認
	if	(!$oSEC->IsAuthority($capID,2,$bbs)){
		if	($oSET->Get('BBS_NAME_COUNT') < length($name)){
			return 101;
		}
	}
	# メール欄の文字数確認
	if	(!$oSEC->IsAuthority($capID,3,$bbs)){
		if	($oSET->Get('BBS_MAIL_COUNT') < length($mail)){
			return 102;
		}
	}
	# 名前欄の入力確認
	if	(!$oSEC->IsAuthority($capID,7,$bbs)){
		if	($oSET->Equal('NANASHI_CHECK','checked') && $name eq ''){
			return 152;
		}
	}
	# 名無し設定
	unless	($name){	$name = $oSET->Get('BBS_NONAME_NAME');	}
	unless	($mail){	$mail = '';								}
	
	# 禁則文字変換
	$this->{'CONV'}->ConvertCharacter(\$name,1);
	$this->{'CONV'}->ConvertCharacter(\$mail,0);
	
	# fusiana変換
	if	(index($name,'fusianasan') eq 0){
		$name =~ s/fusianasan/<\/b>$host<b>/g;
	}
	else{
		$name =~ s/fusianasan/ <\/b>$host<b>/g;
	}
	
	# トリップ変換
	$this->{'CONV'}->ConvertTrip(\$name,$oSET->Get('BBS_TRIPCOLUMN'));
	
	# キャップ名結合
	if	($capName ne ''){
		if	($Form->Get('NAME')){	$name = "$name＠$capName ★";	}
		else{						$name = "$capName ★";			}
	}
	
	# 正規化した内容を再度設定
	$Form->Set('FROM',$name);
	$Form->Set('mail',$mail);
	
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
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my		($Sys) = @_;
	my		($Form,$oSEC,$oSET);
	my		($text,$bbs,$host,$ln,$cl,$capID);
	
	$Form		= $Sys->{'FORM'};
	$oSEC		= $Sys->{'SECURITY'};
	$oSET		= $Sys->{'SET'};
	$bbs		= $Form->Get('bbs');
	$text		= $Form->Get('MESSAGE');
	$host		= $Form->Get('HOST');
	$capID		= $Sys->{'SYS'}->Get('CAPID');
	($ln,$cl)	= $Sys->{'CONV'}->GetTextInfo(\$text);
	
	# 本文が無い
	if	($text eq ''){
		return 151;
	}
	# 本文が長すぎ
	if	(!$oSEC->IsAuthority($capID,4,$bbs)){
		if	($oSET->Get('BBS_MESSAGE_COUNT') < length($text)){
			return 103;
		}
	}
	# 改行が多すぎ
	if	(!$oSEC->IsAuthority($capID,5,$bbs)){
		if	(($oSET->Get('BBS_LINE_NUMBER') * 2) < $ln){
			return 105;
		}
	}
	# 1行が長すぎ
	if	(!$oSEC->IsAuthority($capID,6,$bbs)){
		if	($oSET->Get('BBS_COLUMN_NUMBER') < $cl){
			return 104;
		}
	}
	# アンカーが多すぎ
	if	($Sys->{'SYS'}->Get('ANKERS')){
		if	($Sys->{'CONV'}->IsAnker(\$text,$Sys->{'SYS'}->Get('ANKERS'))){
			return 106;
		}
	}
	# 本文ホスト表示
	if	(!$oSEC->IsAuthority($capID,15,$bbs)){
		if	($oSET->Equal('BBS_RAWIP_CHECK','checked') && $Sys->{'SYS'}->Equal('MODE',1)){
			$text .= '<hr><font color=tomato face=Arial><b>';
			$text .= "$ENV{'REMOTE_ADDR'} , $host , </b></font><br>";
		}
		$Form->Set('MESSAGE',$text);
	}
	
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
	my	($Sys,$data) = @_;
	my	$endPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/1000.txt';
	
	# 1000.txtが存在すればその内容、無ければデフォルトの1001を使用する
	if	(-e $endPath){
		open(LAST,"<$endPath");
		while	(<LAST>){
			$$data = $_;
			last;
		}
		close(LAST);
	}
	else{
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
	my	($Sys,$Form) = @_;
	my	($Logger,$bbs);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	require('./module/imrahil.pl');
	$Logger = new IMRAHIL;
	
	if($Logger->Open("$bbs/log/HOST",500,2 | 4) == 0){
		$Logger->Put($Form->Get('HOST'),$Sys->Get('KEY'),$Sys->Get('MODE'));
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
	my	($Sys,$Form,$resNum) = @_;
	my	($Logger,$bbs,$threadInfo,$name,$content);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	$threadInfo = $Sys->Get('BBS') . ',' . $Sys->Get('KEY');
	$name = $Form->Get('FROM');
	$content = $Form->Get('MESSAGE');
	
	require('./module/imrahil.pl');
	$Logger = new IMRAHIL;
	
	if($Logger->Open("$bbs/info/history",$Sys->Get('HISMAX'),2 | 4) == 0){
		$Logger->Put($threadInfo,$resNum,$content,$name);
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

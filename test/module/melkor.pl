#============================================================================================================
#
#	システムデータ管理モジュール(MELKOR)
#	melkor.pl
#	-----------------------------------------
#	2002.12.03 start
#	2003.10.20 外部ファイル対応に変更
#	2004.04.24 モジュール整理
#
#	ぜろちゃんねるプラス
#	2010.08.12 設定項目追加
#
#============================================================================================================
package	MELKOR;

use strict;
use warnings;
no warnings 'redefine';

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
	my (%SYS, @KEYS, $obj);
	
	$obj = {
		'SYS'	=> \%SYS,
		'KEY'	=> \@KEYS
	};
	bless $obj, $this;
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	正常終了したら0を返す
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	
	# システム設定を読み込む
	return Load($this);
}

#------------------------------------------------------------------------------------------------------------
#
#	システム設定読み込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	正常終了したら0を返す
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($var, $val, @dlist, $pSYS, $sysFile);
	
#	eval
	{
		# システム情報ハッシュの初期化
		undef %{$this->{'SYS'}};
		InitSystemValue(\%{$this->{'SYS'}}, \@{$this->{'KEY'}});
		$sysFile = $this->{'SYS'}->{'SYSFILE'};
		
		# 設定ファイルから読み込む
		if (-e $sysFile) {
			open SYS, "< $sysFile";
			while (<SYS>) {
				chomp $_;
				($var, $val) = split(/<>/, $_);
				$this->{'SYS'}->{$var} = $val;
			}
			close SYS;
		}
		$pSYS = $this->{'SYS'};
		
		# 時間制限のチェック
		@dlist = localtime time;
		if (($dlist[2] >= $pSYS->{'LINKST'} || $dlist[2] < $pSYS->{'LINKED'}) &&
			($pSYS->{'URLLINK'} eq 'FALSE')) {
			$pSYS->{'LIMTIME'} = 1;
		}
		else {
			$pSYS->{'LIMTIME'} = 0;
		}
	};
	return 1 if ($@ ne '');
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	システム設定書き込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($val);
	
#	eval
	{
		open SYS, '>' . $this->{'SYS'}->{'SYSFILE'};
		flock SYS, 2;
		binmode SYS;
		#truncate SYS, 0;
		#seek SYS, 0, 0;
		foreach (@{$this->{'KEY'}}) {
			$val = $this->{'SYS'}->{$_};
			print SYS "$_<>$val\n";
		}
		close SYS;
		chmod 0700, $this->{'SYS'}->{'SYSFILE'};
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	システム設定値取得
#	-------------------------------------------------------------------------------------
#	@param	$key	取得キー
#			$default : デフォルト
#	@return	設定値
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'SYS'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	システム設定値設定
#	-------------------------------------------------------------------------------------
#	@param	$key	設定キー
#	@param	$data	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{'SYS'}->{$key} = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	システム設定値比較
#	-------------------------------------------------------------------------------------
#	@param	$key	設定キー
#	@param	$val	設定値
#	@return	同等なら真を返す
#
#------------------------------------------------------------------------------------------------------------
sub Equal
{
	my $this = shift;
	my ($key, $data) = @_;
	
	return($this->{'SYS'}->{$key} eq $data);
}

#------------------------------------------------------------------------------------------------------------
#
#	オプション値取得- GetOption
#	-------------------------------------------
#	引　数：$flag : 取得フラグ
#	戻り値：成功:オプション値
#			失敗:-1
#
#------------------------------------------------------------------------------------------------------------
sub GetOption
{
	my $this = shift;
	my ($flag) = @_;
	my (@elem);
	
	@elem = split(/\,/, $this->{'SYS'}->{'OPTION'});
	
	return($elem[$flag - 1]);
}

#------------------------------------------------------------------------------------------------------------
#
#	オプション値設定 - SetOption
#	-------------------------------------------
#	引　数：$last  : ラストフラグ
#			$start : 開始行
#			$end   : 終了行
#			$one   : >>1表示フラグ
#			$alone : 単独表示フラグ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub SetOption
{
	my $this = shift;
	my ($last, $start, $end, $one, $alone) = @_;
	
	$this->{'SYS'}->{'OPTION'} = "$last,$start,$end,$one,$alone";
}

#------------------------------------------------------------------------------------------------------------
#
#	システム変数初期化 - InitSystemValue
#	-------------------------------------------
#	引　数：$pSYS : ハッシュの参照
#	戻り値：なし
#	備　考：(*)マークがついている項目のみ手動で変更可能です
#
#	2010.08.12 windyakin ★
#	 -> Samba値の設定, 告知欄表示の設定, ２重カキコ規制の設定
#
#------------------------------------------------------------------------------------------------------------
sub InitSystemValue
{
	my ($pSYS, $pKEY) = @_;
	my (@dlist);
	
	%$pSYS = (
		'SYSFILE'	=> './info/system.cgi',						# システム設定ファイル
		'SERVER'	=> '',										# 設置サーバパス(*)
		'CGIPATH'	=> '/test',									# CGI設置パス(*)
		'INFO'		=> '/info',									# 管理データ設置パス(*)
		'DATA'		=> '/datas',								# 初期データ設置パス(*)
		'BBSPATH'	=> '..',									# 掲示板設置パス(*)
		'DEBUG'		=> 1,										# デバグモード(*)
		'VERSION'	=> '0ch+ BBS 0.4.6b 101230',				# CGIバージョン
		'PM-DAT'	=> 0644,									# datパーミション(*)
		'PM-TXT'	=> 0644,									# TXTパーミション(*)
		'PM-LOG'	=> 0770,									# LOGパーミション(*)
		'PM-ADM'	=> 0770,									# 管理ファイル群(*)
		'PM-ADIR'	=> 0770,									# 管理DIRパーミション(*)
		'PM-BDIR'	=> 0755,									# 板DIRパーミション(*)
		'PM-LDIR'	=> 0770,									# ログDIRパーミション(*)
		'PM-STOP'	=> 0604,									# スレストパーミション(*)
		'ERRMAX'	=> 500,										# エラーログ最大保持数
		'SUBMAX'	=> 500,										# subject最大保持数
		'RESMAX'	=> 1000,									# レス最大書き込み数
		'ADMMAX'	=> 500,										# 管理操作ログ最大保持数
		'HISMAX'	=> 20,										# 書き込み履歴最大保持数
		'ANKERS'	=> 10,										# 最大アンカー数
		'URLLINK'	=> 'TRUE',									# URLへの自動リンク
		'LINKST'	=> 23,										# リンク禁止開始時間
		'LINKED'	=> 2,										# リンク禁止終了時間
		'PATHKIND'	=> 0,										# 生成パスの種類
		'HEADTEXT'	=> '<small>■<b>掲示板一覧</b>■</small>',	# ヘッダ下部の表示文字列
		'HEADURL'	=> '../index.html',							# ヘッダ下部のURL
		'FASTMODE'	=> 0,										# 高速モード
		
		# ここからぜろプラオリジナル
		'SAMBATM'	=> 10,										# 連続書き込み規制時間(秒)
	#	'ISSAMBA'	=> 0,										# Samba規制
	#	'HOUSHI'	=> 10,										# Samba規制時間(分)
		'BANNER'	=> 1,										# read.cgi他の告知欄の表示
		'KAKIKO'	=> 1,										# 2重かきこですか？？
		'COUNTER'	=> '1002000420550000',						# ofuda.cc アカウント
		'PRTEXT'	=> 'ぜろちゃんねるプラス',					# PR欄の表示文字列
		'PRLINK'	=> 'http://zerochplus.sourceforge.jp/',		# PR欄のリンクURL
		'TRIP12'	=> 0,										# 12桁トリップを変換するかどうか
		'MSEC'		=> 0,										# msecまで表示するか
		'BBSGET'	=> 0,										# bbs.cgiでGETメソッドを使用するかどうか
		
		# DNSBL設定
		'BBQ'		=> 1,										# BBQ(niku.2ch.net)
		'BBX'		=> 1,										# BBX(bbx.2ch.net)
		'SPAMCH'	=> 1,										# スパムちゃんぷるー
	);
	
	# 情報保持キー
	@$pKEY = (
		'SERVER',	'CGIPATH',	'INFO',		'DATA',		'BBSPATH',
		'PM-DAT',	'PM-TXT',	'PM-LOG',	'PM-ADM',	'PM-ADIR',	'PM-BDIR',	'PM-LDIR',	'PM-STOP',
		'ERRMAX',	'SUBMAX',	'RESMAX',	'ADMMAX',	'HISMAX',	'ANKERS',	'URLLINK',
		'LINKST',	'LINKED',	'PATHKIND',	'HEADTEXT',	'HEADURL',	'FASTMODE',
		'SAMBATM',	
	#	'ISSAMBA',	'HOUSHI',	
		'BANNER',	'KAKIKO',	'COUNTER',	'PRTEXT',	'PRLINK',	'TRIP12',	'MSEC',		'BBSGET',
		'BBQ',		'BBX',		'SPAMCH',
	);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

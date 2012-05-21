#============================================================================================================
#
#	汎用データ変換・取得モジュール(GALADRIEL)
#	galadriel.pl
#	------------------------------------------------
#	2002.12.03 start
#	2003.02.07 cookie関係を別モジュールに
#	           DeleteText追加
#
#	ぜろちゃんねるプラス
#	2010.08.12 新仕様トリップ対応
#	2010.08.14 ID仕様変更 トリップ仕様変更
#	           禁則処理2ch完全互換
#	2010.08.15 プラグイン対応維持につき文字処理の分割
#	2010.08.21 新仕様トリップ対応修正
#
#============================================================================================================
package	GALADRIEL;

use strict;
#コメントアウトを外す場合は変数の初期化チェックをすること。
#use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my $obj = {};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	URL引数取得 - GetArgument
#	-------------------------------------------
#	引　数：$pENV : %ENVのリファレンス
#	戻り値：引数配列
#
#------------------------------------------------------------------------------------------------------------
sub GetArgument
{
	my $this = shift;
	my ($pENV) = @_;
	my (@retArg, @Awork);
	my ($var, $val);
	
	if ($pENV->{'PATH_INFO'}) {														# PATH_INFOあり
		@Awork		= split(/\//, $pENV->{'PATH_INFO'});
		$retArg[0]	= $Awork[1];													# bbs名(パス)
		$retArg[1]	= $Awork[2];													# スレッドキー
		@Awork		= ConvertOption($Awork[3]);										# オプション変換
		$retArg[2]	= $Awork[0];
		$retArg[3]	= $Awork[1];
		$retArg[4]	= $Awork[2];
		$retArg[5]	= $Awork[3];
		$retArg[6]	= $Awork[4];
	}
	else {																			# QUERY_STRING
		@Awork = split(/&/, $pENV->{'QUERY_STRING'});
		@retArg = ('', '', 0, 1, 1000, 1, 0);
		foreach (@Awork) {
			($var, $val) = split(/=/, $_);
			if		($var eq 'bbs') {						$retArg[0] = $val; }	# BBS
			elsif	($var eq 'key') {						$retArg[1] = $val; }	# スレッドキー
			elsif	($var eq 'st') {						$retArg[3] = $val; }	# 開始レス番
			elsif	($var eq 'to') {						$retArg[4] = $val; }	# 終了レス番
			elsif	($var eq 'nofirst' && $val eq 'true') {	$retArg[5] = 1; }		# 1非表示
			elsif	($var eq 'last' && $val != -1) {								# 最新n件表示
				$retArg[2] = 1;
				$retArg[3] = $val;
				$retArg[4] = $val;
			}
		}
		if ($retArg[3] == $retArg[4] && $retArg[2] != 1) {							# 単独表示フラグ
			$retArg[6] = 1;
		}
	}
	
	return @retArg;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示レス数正規化 - RegularDispNum
#	-------------------------------------------
#	引　数：$A     : ARAGORNオブジェクト
#			$last  : lastフラグ
#			$start : 開始行
#			$end   : 終了行
#	戻り値：(開始行、終了行)
#
#------------------------------------------------------------------------------------------------------------
sub RegularDispNum
{
	my $this = shift;
	my ($M, $A, $last, $start, $end) = @_;
	my (@dlist, $rn, $st, $ed);
	
	if ($start > $end && $end != -1) {					# 大きさ判定
		$rn = $start;
		$start = $end;
		$end = $rn;
	}
	$rn = $A->Size();
	
	if ($last == 1) {									# 最新n件表示
		$start -= 2;
		$st = (($rn - $start > 0) ? $rn - $start : 1);
		$ed = $rn;
	}
	elsif ($start || $end) {							# 指定表示
		if ($end == -1) {
			$st = $start > 0 ? $start : 1;
			$ed = $rn;
		}
		else {
			$st = $start > 0 ? $start : 1;
			$ed = $end < $rn ? $end : $rn;
		}
	}
	else {												# 全件表示
		$st = 1;
		$ed = $rn;
	}
	
	if ($M->Get('LIMTIME')) {							# 時間による制限有り
		if ($ed - $st > 100) {							# 表示レス数が100超えた
			$ed = $st + 100;
		}
	}
	return ($st, $ed);
}

#------------------------------------------------------------------------------------------------------------
#
#	URL変換 - ConvertURL
#	--------------------------------------------
#	引　数：$M,$I : モジュール
#			$mode : エージェント
#			$text : 変換テキスト
#	戻り値：変換後のメッセージ
#
#------------------------------------------------------------------------------------------------------------
sub ConvertURL
{
	my $this = shift;
	my ($M, $I, $mode, $text) = @_;
	my (@work, @dlist, $reg1, $reg2, $cushion, $server);
	
	if 	($M->Get('LIMTIME')) {															# 時間による制限有り
		return $text;
	}
	
	$server		= $M->Get('SERVER');
	$cushion	= $I->Get('BBS_REFERER_CUSHION');										# URLクッション
	$reg1		= q{(https?|ftp)://(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)};			# URL検索１
	$reg2		= q{<(https?|ftp)::(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)>};		# URL検索２
	
	if ($mode) {																		# 携帯から
		$$text =~ s{$reg1}{<$1::$2>}g;													# URL1次変換
		while ($$text =~ /$reg2/) {
			@work = split(/\//, $2);
			$work[0] =~ s/(www\.|\.com|\.net|\.jp|\.co|\.ne)//g;
			$$text =~ s{$reg2}{<a href="$1://$2">$work[0]</a>};
		}
		$$text	=~ s/ <br> /<br>/g;														# 改行
		$$text	=~ s/\s*<br>/<br>/g;													# 空白改行
		$$text	=~ s/(?:<br>){2}/<br>/g;												# 空改行
		$$text	=~ s/(?:<br>){3,}/<br><br>/g;											# 空改行
	}
	else {																				# PCから
		if ($cushion) {																	# クッションあり
			$server =~ m|$reg1|;
			$server = $2;
			$$text =~ s|$reg1|<$1::$2>|g;												# URL1次変換
			while ($$text =~ m|$reg2|) {												# 2次変換
				if ($2 =~ m{^\Q$server\E(?:/|$)}) {										# 自鯖リンク
					$$text =~ s|$reg2|<a href="$1://$2" target="_blank">$1://$2</a>|;	# クッションなし
				}
				else {																	# 自鯖以外
					if( $1 eq "http" ) {
						$$text =~ s|$reg2|<a href="$1://$cushion$2" target="_blank">$1://$2</a>|;
					}
					elsif ( $cushion =~ /(?:jump.x0.to|nun.nu)/ ) {
						$$text =~ s|$reg2|<a href="http://$cushion$1://$2" target="_blank">$1://$2</a>|;
					}
				}
			}
		}
		else {																			# クッション無し
			$$text =~ s|$reg1|<a href="$1://$2" target="_blank">$1://$2</a>|g;			# 通常URL変換
		}
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	引用変換 - ConvertQuotation
#	--------------------------------------------
#	引　数：$M    : MELKORオブジェクト
#			$text : 変換テキスト
#	戻り値：変換後のメッセージ
#
#------------------------------------------------------------------------------------------------------------
sub ConvertQuotation
{
	my $this = shift;
	my ($Sys, $text, $mode) = @_;
	my ($buf, $pathCGI);
	
	if ($Sys->Get('LIMTIME')) {															# 時間による制限有り
		return $text;
	}
	$pathCGI = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	
	if ($Sys->Get('PATHKIND')) {
		# URLベースを生成
		$buf .= '<a href="';
		$buf .= $pathCGI . ($mode ? '/r.cgi' : '/read.cgi');
		$buf .= '?bbs=' . $Sys->Get('BBS') . '&key=' . $Sys->Get('KEY');
		$buf .= '&nofirst=true';
		
		$$text =~ s{&gt;&gt;(\d+)-(\d+)}												# 引用 n-m
					{$buf&st=$1&to=$2" target="_blank">>>$1-$2</a>}g;
		$$text =~ s{&gt;&gt;(\d+)-}														# 引用 n-
					{$buf&st=$1&to=-1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;-(\d+)}														# 引用 -n
					{$buf&st=1&to=$1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;(\d+)}														# 引用 n
					{$buf&st=$1&to=$1" target="_blank">>>$1</a>}g;
	}
	else{
		# URLベースを生成
		$buf = '<a href="';
		$buf .= $pathCGI . ($mode ? '/r.cgi/' : '/read.cgi/');
		$buf .= $Sys->Get('BBS') . '/' . $Sys->Get('KEY');
		
		$$text =~ s{&gt;&gt;(\d+)-(\d+)}{$buf/$1-$2n" target="_blank">>>$1-$2</a>}g;	# 引用 n-m
		$$text =~ s{&gt;&gt;(\d+)-}{$buf/$1-" target="_blank">>>$1-</a>}g;				# 引用 n-
		$$text =~ s{&gt;&gt;-(\d+)}{$buf/-$1" target="_blank">>>-$1</a>}g;				# 引用 -n
		$$text =~ s{&gt;&gt;(\d+)}{$buf/$1" target="_blank">>>$1</a>}g;					# 引用 n
	}
	$$text	=~ s{>>(\d+)}{&gt;&gt;$1}g;													# &gt;変換
	
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	特殊引用変換 - ConvertSpecialQuotation
#	--------------------------------------------
#	引　数：$M    : MELKORオブジェクト
#			$text : 変換テキスト
#	戻り値：変換後のメッセージ
#
#------------------------------------------------------------------------------------------------------------
sub ConvertSpecialQuotation
{
	my $this = shift;
	my ($M, $text, $mode) = @_;
	my (@lines, @edited, $len);
	
	if ($mode == 0) {
		@lines = split(/<br>/, $text);
		$text = '';
		foreach (@lines) {
			if (/^＞/) {
				$_ = "<font color=gray>$_</font>";
			}
			elsif (/^#/) {
				$_ = "<font color=green>$_</font>";
			}
			$text .= "$_<br>";
		}
		$len = $text - 4;
		return substr($text, 0, $len);
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	テキスト削除 - DeleteText
#	--------------------------------------------
#	引　数：$text : 対象テキスト
#			$len  : 最大文字数
#	戻り値：成形後テキスト
#
#------------------------------------------------------------------------------------------------------------
sub DeleteText
{
	my $this = shift;
	my ($text, $len) = @_;
	my @texts = split(/<br>/, $$text);
	my ($ret, $tlen, $rlen);
	
	$ret = '';
	$tlen = 0;
	foreach (@texts) {
		$rlen = length $_;
		$tlen += $rlen;
		last if ($tlen > $len);
		$ret = "$ret$_<br>";
		$tlen += 4;
	}
	$tlen = length($ret) - 4;
	$ret = substr($ret, 0, $tlen);
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	改行数取得 - GetTextLine
#	--------------------------------------------
#	引　数：$text : 対象テキスト
#	戻り値：改行数
#
#------------------------------------------------------------------------------------------------------------
sub GetTextLine
{
	my $this = shift;
	my ($text) = @_;
	my ($buf, $l);
	
	$_ = $$text;
	$l = s/(\r\n)/a/g;
	
	if ($l == 0) { $_ = $$text; $l = s/(\r)/a/g; }
	if ($l == 0) { $_ = $$text; $l = s/(\n)/a/g; }
	if ($l == 0) { $_ = $$text; $l = s/(<br>|<BR>)/a/g; }
	
	return ($l + 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	行列情報取得 - GetTextInfo
#	------------------------------------------------
#	引　数：$text : 調査テキスト
#	戻り値：($tline,$tcolumn) : テキストの行数と
#			テキストの最大桁数
#	備　考：テキストの行区切りは<br>になっていること
#
#------------------------------------------------------------------------------------------------------------
sub GetTextInfo
{
	my $this = shift;
	my ($text) = @_;
	my (@lines, $ln, $mx);
	
	@lines = split(/ ?<br> ?/, $$text);
	$ln = $$text =~ s/<br>/<br>/g;
	$mx = 0;
	
	foreach (@lines) {
		if ($mx < length($_)) {
			$mx = length $_;
		}
	}
	return ($ln, $mx);
}

#------------------------------------------------------------------------------------------------------------
#
#	エージェントモード取得 - GetAgentMode
#	--------------------------------------------
#	引　数：$UA   : ユーザーエージェント
#	戻り値：エージェントモード
#
#	2010.08.13 windyakin ★
#	 -> ID末尾文字正規化のため変更
#
#	2010.08.30 windyakin ★
#	 -> フルブラウザ, AirH"の対応
#
#	2011.02.13 色々
#	 -> 仮
#
#------------------------------------------------------------------------------------------------------------
sub GetAgentMode
{
	my $this = shift;
	my ($client) = @_;
	my ($agent);
	
	$agent = '0';
	
	if ($client & $ZP::C_MOBILEBROWSER) {
		$agent = 'O';
	}
	elsif ($client & $ZP::C_FULLBROWSER) {
		$agent = 'Q';
	}
	elsif ($client & $ZP::C_P2) {
		$agent = 'P';
	}
	elsif ($client & $ZP::C_IPHONE_F) {
		$agent = 'i';
	}
	elsif ($client & $ZP::C_IPHONEWIFI) {
		$agent = 'I';
	}
	else {
		$agent = '0';
	}
	
}

#------------------------------------------------------------------------------------------------------------
#
#	クライアント(機種)取得 - GetClient
#	--------------------------------------------
#	引　数：
#	戻り値：
#
#	2011.02.13 色々
#
#------------------------------------------------------------------------------------------------------------
sub GetClient
{
	my $this = shift;
	my ($ua, $host, $addr, $client, $cidr);
	
	$ua = $ENV{'HTTP_USER_AGENT'};
	$host = $ENV{'REMOTE_HOST'};
	$addr = $ENV{'REMOTE_ADDR'};
	$client = 0;
	
	require './module/cidr_list.pl';
	
	$cidr = $ZP_CIDR::cidr;
	
	if (CIDRHIT($cidr->{'docomo'}, $addr)) {
		$client = $ZP::C_DOCOMO_M;
	}
	elsif (CIDRHIT($cidr->{'docomo_pc'}, $addr)) {
		$client = $ZP::C_DOCOMO_F;
	}
	elsif (CIDRHIT($cidr->{'vodafone'}, $addr)) {
		$client = $ZP::C_SOFTBANK_M;
	}
	elsif (CIDRHIT($cidr->{'vodafone_pc'}, $addr)) {
		$client = $ZP::C_SOFTBANK_F;
	}
	elsif (CIDRHIT($cidr->{'ezweb'}, $addr)) {
		$client = $ZP::C_AU_M;
	}
	elsif (CIDRHIT($cidr->{'ezweb_pc'}, $addr)) {
		$client = $ZP::C_AU_F;
	}
	elsif (CIDRHIT($cidr->{'emobile'}, $addr)) {
		if ($ua =~ m|^emobile/1\.0\.0|) {
			$client = $ZP::C_EMOBILE_M;
		}
		else {
			$client = $ZP::C_EMOBILE_F;
		}
	}
	elsif (CIDRHIT($cidr->{'willcom'}, $addr)) {
		if ($ua =~ m|^Mozilla/3\.0|) {
			$client = $ZP::C_WILLCOM_M;
		}
		elsif ($ua =~ m|^Mozilla/4\.0| && $ua =~ m/IEMobile|PPC/) {
			$client = $ZP::C_WILLCOM_M;
		}
		else {
			$client = $ZP::C_WILLCOM_F;
		}
	}
	elsif (CIDRHIT($cidr->{'ibis'}, $addr)) {
		$client = $ZP::C_IBIS;
	}
	elsif (CIDRHIT($cidr->{'jig'}, $addr)) {
		$client = $ZP::C_JIG;
	}
	elsif (CIDRHIT($cidr->{'iphone'}, $addr)) {
		$client = $ZP::C_IPHONE_F;
	}
	elsif (CIDRHIT($cidr->{'p2'}, $addr)) {
		$client = $ZP::C_P2;
	}
	elsif ($host =~ m|\.opera-mini\.net$|) {
		$client = $ZP::C_OPERAMINI;
	}
	elsif ($ua =~ / iPhone| iPad/) {
		$client = $ZP::C_IPHONEWIFI;
	}
	else {
		$client = $ZP::C_PC;
	}
	
	return $client;
}

#------------------------------------------------------------------------------------------------------------
#
#	IPチェック(CIDR対応) by (-Ac)
#	-------------------------------------------------------------------------------------
#	@param	$orz  : CIDRリスト(配列)
#			$ho   : チェック文字
#	@return	ヒットした場合1 それ以外は0
#
#------------------------------------------------------------------------------------------------------------

sub CIDRHIT {
	
	my ( $orz, $ho ) = @_;
	
	foreach ( @{$orz} ) {
		
		# CIDR形式でなければ普通に完全一致チェック
		# return ( $_ eq $ho ? 1 : 0 ) if ( $_ !~ m|/| );
		# 完全一致 = /32 ってことで^^;
		$_ .= '/32' if ( $_ !~ m|/| );
		
		# 以下CIDR形式
		{
			my ( $target, $length ) = split( '/', $_ );
			
			my $ipaddr = unpack("B$length", pack('C*', split(/\./, $ho)));
			$target = unpack("B$length", pack('C*', split(/\./, $target)));
			
			return 1 if ( $target eq $ipaddr );
		}
		
	}
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	携帯機種情報取得
#	-------------------------------------------------------------------------------------
#	@return	個体識別番号
#
#	2010.08.14 windyakin ★
#	 -> 主要3キャリア+公式p2を取れるように変更
#
#------------------------------------------------------------------------------------------------------------
sub GetProductInfo
{
	my $this = shift;
	my ($client) = @_;
	my $product = undef;
	
	# docomo
	if ( $client & $ZP::C_DOCOMO ) {
		# $ENV{'HTTP_X_DCMGUID'} - 端末製造番号, 個体識別情報, ユーザID, iモードID
		$product = $ENV{'HTTP_X_DCMGUID'};
		$product =~ s/^X-DCMGUID: ([a-zA-Z0-9]+)$/$1/i;
	}
	# SoftBank
	elsif ( $client & $ZP::C_SOFTBANK ) {
		# USERAGENTに含まれる15桁の数字 - 端末シリアル番号
		$product = $ENV{'HTTP_USER_AGENT'};
		$product =~ s/.+\/SN([A-Za-z0-9]+)\ .+/$1/;
	}
	# au
	elsif ( $client & $ZP::C_AU ) {
		# $ENV{'HTTP_X_UP_SUBNO'} - サブスクライバID, EZ番号
		$product = $ENV{'HTTP_X_UP_SUBNO'};
		$product =~ s/([A-Za-z0-9_]+).ezweb.ne.jp/$1/i;
	}
	# e-mobile(音声端末)
	elsif ( $client & $ZP::C_EMOBILE ) {
		# $ENV{'X-EM-UID'} - 
		$product = $ENV{'X-EM-UID'};
		$product =~ s/x-em-uid: (.+)/$1/i;
	}
	# 公式p2
	elsif ( $client & $ZP::C_P2 ) {
		# $ENV{'HTTP_X_P2_CLIENT_IP'} - (発言者のIP)
		# $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} - (発言者の固体識別番号)
		$ENV{'REMOTE_P2'} = $ENV{'REMOTE_ADDR'};
		$ENV{'REMOTE_ADDR'} = $ENV{'HTTP_X_P2_CLIENT_IP'};
		$ENV{'REMOTE_HOST'} = $this->GetRemoteHost($ENV{'REMOTE_ADDR'});
		if( $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} ne "" ) {
			$product = $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'};
		}
		else {
			$product = $ENV{'HTTP_USER_AGENT'};
			$product =~ s/.+p2-user-hash: (.+)\)/$1/i;
		}
	}
	else {
		$product = $ENV{'REMOTE_HOST'};
	}
	return $product;
}

#------------------------------------------------------------------------------------------------------------
#
#	リモートホスト(IP)取得関数 - GetRemoteHost
#	---------------------------------------------
#	引　数：なし
#	戻り値：IP、リモホス
#
#------------------------------------------------------------------------------------------------------------
sub GetRemoteHost
{
	my $this = shift;
	my ($HOST);
	
	$HOST = $ENV{'REMOTE_ADDR'};
	
	if ($HOST =~ /\d$/) {
		$HOST = gethostbyaddr(pack('c4', split(/\./, $HOST)), 2) || $HOST;
	}
	
	return $HOST;
}

#------------------------------------------------------------------------------------------------------------
#
#	ID作成関数 - MakeID
#	--------------------------------------
#	引　数：$server : キーサーバ
#			$column : ID桁数
#	戻り値：ID
#
#------------------------------------------------------------------------------------------------------------
sub MakeID
{
	my $this = shift;
	my ($server, $client, $koyuu, $bbs, $column) = @_;
	my @times = localtime time;
	my (@nums, $ret, $str, $uid);
	
	# 種の生成
	if ( $client & ($ZP::C_P2 | $ZP::C_MOBILE) ) {
		# 端末番号 もしくは p2-user-hash の上位3文字を取得
		#$uid = main::GetProductInfo($this, $ENV{'HTTP_USER_AGENT'}, $ENV{'REMOTE_HOST'});
		if (length($koyuu) > 8) {
			$uid = substr($koyuu, 0, 2) . substr($koyuu, -6, 3);
		}
		else {
			$uid = substr($koyuu, 0, 5);
		}
	}
	else {
		# IPを分解
		@nums = split(/\./, $ENV{'REMOTE_ADDR'});
		# 上位3つの1桁目取得
		$uid = substr($nums[3], -2) . substr($nums[2], -2) . substr($nums[1], -1);
	}
	
	# サーバー名･板名を結合する
	$str = $uid . substr(crypt($server, $times[4]), 2, 1) . substr(crypt($bbs, $times[4]), 2, 2);
	# 桁を設定
	$column = -1 * $column;
	
	# IDの生成
	$ret = substr(crypt(crypt($str, $times[5]), $times[3] + 31), $column);
	$ret =~ s/\./+/g;
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	トリップ作成関数 - ConvertTrip
#	--------------------------------------
#	引　数：$key    : トリップキー
#			$column : 桁数
#			$orz    : 新仕様ON/OFF
#	戻り値：変換後文字列
#
#	2010.08.12 windyakin ★
#	 -> 生キー変換, 新仕様トリップ(12桁) に対応
#		詳細は副産物のtriptestを参考のこと
#
#	2010.08.14 windyakin ★
#	 -> 新仕様トリップの選択性に対応
#
#	2010.08.21 色々
#	 -> 新仕様トリップ対応修正
#
#------------------------------------------------------------------------------------------------------------
sub ConvertTrip
{
	my $this = shift;
	my ($key, $column, $shatrip) = @_;
	my ($trip, $mark, $salt, $key2);
	
	$$key = '' if (! defined $$key);
	
	# cryptのときの桁取得
	$column = -1 * $column;
	
	$trip = '';
	
	if (length $$key >= 12) {
		# 先頭2文字の取得
		$mark = substr($$key, 0, 1);
		
		if ($mark eq '#' || $mark eq '$') {
			if ($$key =~ m|^#([0-9a-zA-Z]{16})([./0-9A-Za-z]{0,2})$|) {
				$key2 = pack('H*', $1);
				$salt = substr($2 . '..', 0, 2);
				
				# 0x80問題再現
				$key2 =~ s/\x80[\x00-\xff]*$//;
				
				$trip = substr(crypt($key2, $salt), $column);
			}
			else {
				# 将来の拡張用
				$trip = '???';
			}
		}
		elsif ($shatrip eq 1) {
			# SHA1(新仕様)トリップ
			eval {
				require Digest::SHA::PurePerl;
				Digest::SHA::PurePerl->import( qw(sha1_base64) );
				$trip = substr(sha1_base64($$key), 0, 12);
			};
			if ( $@ ) {
				# Digest::SHA::PurePerlできない場合は???(e)を表示させる
				$trip = "???(e)";
			}
			$trip =~ tr/+/./;
		}
	}
	
	if ($trip eq '') {
		# 従来のトリップ生成方式
		$salt = substr($$key, 1, 2);
		$salt = '' if (! defined $salt);
		$salt .= 'H.';
		$salt =~ s/[^\.-z]/\./go;
		$salt =~ tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/;
		
		# 0x80問題再現
		$$key =~ s/\x80[\x00-\xff]*$//;
		
		$trip = substr(crypt($$key, $salt), $column);
	}
	
	return $trip;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	オプション変換 - ConvertOption
#	--------------------------------------
#	引　数：$opt : オプション
#	戻り値：結果配列
#
#------------------------------------------------------------------------------------------------------------
sub ConvertOption
{
	my ($opt) = @_;
	my (@ret);
	
	$opt = '' if (! defined $opt);
	
	@ret = (-1, -1, -1, -1, -1);		# 初期値
	
	if ($opt =~ /l(\d+)n/) {			# 最新n件(1無し)
		$ret[0] = 1;					# ラストフラグ
		$ret[1] = $1 + 1;				# 開始行
		$ret[2] = $1 + 1;				# 終了行
		$ret[3] = 1;					# >>1非表示フラグ
	}
	elsif ($opt =~ /l(\d+)/) {			# 最新n件(1あり)
		$ret[0] = 1;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = $1;					# 終了行
		$ret[3] = 0;					# >>1非表示フラグ
	}
	elsif ($opt =~ /(\d+)-(\d+)n/) {	# n-m(1無し)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = $2;					# 終了行
		$ret[3] = 1;					# >>1非表示フラグ
	}
	elsif ($opt =~ /(\d+)-(\d+)/) {		# n-m(1あり)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = $2;					# 終了行
		$ret[3] = 0;					# >>1非表示フラグ
	}
	elsif ($opt =~ /(\d+)-n/) {			# n以降(1無し)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = -1;					# 終了行
		$ret[3] = 1;					# >>1非表示フラグ
	}
	elsif ($opt =~ /(\d+)-/) {			# n以降(1あり)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = -1;					# 終了行
		$ret[3] = 0;					# >>1非表示フラグ
	}
	elsif ($opt =~ /-(\d+)/) {			# nまで(1あり)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = 1;					# 開始行
		$ret[2] = $1;					# 終了行
		$ret[3] = 0;					# >>1非表示フラグ
	}
	elsif ($opt =~ /(\d+)n/) {			# n表示(1無し)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = $1;					# 終了行
		$ret[3] = 1;					# >>1非表示フラグ
		$ret[4] = 1;					# 単独表示フラグ
	}
	elsif ($opt =~ /(\d+)/) {			# n表示(1あり)
		$ret[0] = 0;					# ラストフラグ
		$ret[1] = $1;					# 開始行
		$ret[2] = $1;					# 終了行
		$ret[3] = 1;					# >>1非表示フラグ
		$ret[4] = 1;					# 単独表示フラグ
	}
	
	return @ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	パス生成 - CreatePath
#	-------------------------------------------
#	引　数：$bbs  : BBSキー
#			$key  : スレッドキー
#			$opt  : オプション
#	戻り値：生成されたパス
#
#------------------------------------------------------------------------------------------------------------
sub CreatePath
{
	my $this = shift;
	my ($M, $mode, $bbs, $key, $opt) = @_;
	my ($path, @opts);
	
	$path = $M->Get('SERVER') . $M->Get('CGIPATH') . ($mode == 0 ? '/read.cgi' : '/r.cgi');
	
	if ($M->Get('PATHKIND')) {							# QUERY_STRINGパス生成
		@opts = ConvertOption($opt);
		
		$path .= "?bbs=$bbs&key=$key";					# ベース作成
		if ($opts[0]) {									# 最新n件表示
			$path .= "&last=$opts[1]&nofirst=";
		}
		else {											# 指定表示
			$path .= "&st=$opts[1]";
			$path .= "&to=$opts[2]&nofirst=";
		}
		$path .= ($opts[3] == 1 ? 'true' : 'false');	# >>1表示の付加
	}
	else {												# PATH_INFOパス生成
		$path .= "/$bbs/$key/$opt";
	}
	
	return $path;
}

#------------------------------------------------------------------------------------------------------------
#
#	日付取得 - GetDate
#	--------------------------------------
#	引　数：なし
#	戻り値：日付文字列
#
#------------------------------------------------------------------------------------------------------------
sub GetDate
{
	my $this = shift;
	my ($oSet, $msect) = @_;
	my (@info, @weeks, $week);
	
	$ENV{'TZ'} = "JST-9";
	@info = localtime time;
	$info[5] += 1900;
	$info[4] += 1;
	
	# 曜日の取得
	$week = ('日', '月', '火', '水', '木', '金', '土')[$info[6]];
	if (defined $oSet) {
		if (! $oSet->Equal('BBS_YMD_WEEKS', '')) {
			@weeks = split(/\//, $oSet->Get('BBS_YMD_WEEKS'));
			$week = $weeks[$info[6]];
		}
	}
	
	foreach (0 .. 4) {
		$info[$_] = "0$info[$_]" if ($info[$_] < 10);
	}
	
	# msecの取得
	if ($msect) {
		use Time::HiRes;
		my $times = Time::HiRes::time;
		$info[0] .= sprintf(".%02d", substr((split(/\./, $times))[1], 0, 2 ));
	}
	
	return "$info[5]/$info[4]/$info[3]" . ($week eq '' ? '' : "($week)") . " $info[2]:$info[1]:$info[0]";
	
}

#------------------------------------------------------------------------------------------------------------
#
#	シリアル値から日付文字列を取得する
#	-------------------------------------------------------------------------------------
#	@param	$serial	シリアル値
#	@param	$mode	0:時間表示有り 1:日付のみ
#	@return	日付文字列
#
#------------------------------------------------------------------------------------------------------------
sub GetDateFromSerial
{
	my $this = shift;
	my ($serial, $mode) = @_;
	my (@info, $week);
	
	$ENV{'TZ'} = "JST-9";
	@info = localtime $serial;
	$info[5] += 1900;
	$info[4] += 1;
	
	foreach (1 .. 4) {
		$info[$_] = "0$info[$_]" if ($info[$_] < 10);
	}
	
	return "$info[5]/$info[4]/$info[3]"						if ($mode == 1);
	return "$info[5]/$info[4]/$info[3] $info[2]:$info[1]"	if ($mode == 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	ID部分文字列生成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Set	ISILDUR
#	@param	$Form	SAMWISE
#	@param	$Sec	
#	@param	$id		ID
#	@return	ID部分文字列
#	@see	優先順位：HOST > NOID > FORCE > PASS
#
#------------------------------------------------------------------------------------------------------------
sub GetIDPart
{
	my $this = shift;
	my ($Set, $Form, $Sec, $id, $capID, $koyuu, $agent) = @_;
	my ($mode, @mail);
	
	$mode = '';
	
	# PC・携帯識別番号付加
	if ($Set->Equal('BBS_SLIP', 'checked')) {
		$mode = $agent;
		$id .= $mode;
	}
	
	# ホスト表示
	if ($Set->Equal('BBS_DISP_IP', 'checked')) {
		
		# ID非表示権限有り
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
			return " ID:???$mode";
		}
		
		if ( $mode eq 'O' ) {
			return " HOST:$koyuu $ENV{'REMOTE_HOST'}".( $mode ne '' ? " $mode" : '' );
		}
		elsif ( $mode eq 'P' ) {
			return " HOST:$koyuu $ENV{'REMOTE_HOST'} ($ENV{'REMOTE_ADDR'})".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " HOST:$koyuu".( $mode ne '' ? " $mode" : '' );
		}
	}
	# IP表示 Ver.Siberia
	if ($Set->Equal('BBS_DISP_IP', 'siberia')){
		
		# ID非表示権限有り
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
			return " 発信元:???$mode";
		}
		
		if ( $mode eq 'P' ) {
			return " 発信元:$ENV{'REMOTE_P2'}".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " 発信元:$ENV{'REMOTE_ADDR'}".( $mode ne '' ? " $mode" : '' );
		}
	}
	# IP表示 Ver.Sakhalin
	if ($Set->Equal('BBS_DISP_IP', 'sakhalin')) {
		
		# ID非表示権限有り
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
			return " 発信元:???".( $mode ne '' ? " $mode" : '' );
		}
		
		if ( $mode eq 'P' ) {
			return " 発信元:$ENV{'HTTP_X_P2_CLIENT_IP'} ($koyuu)".( $mode ne '' ? " $mode" : '' );
		}
		elsif ( $mode eq 'O' ) {
			return " 発信元:$ENV{'REMOTE_ADDR'} ($koyuu)".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " 発信元:$ENV{'REMOTE_ADDR'}".( $mode ne '' ? " $mode" : '' );
		}
	}
	
	# ID表示無しならそのままリターン
	if ($Set->Equal('BBS_NO_ID', 'checked')) {
		return ( $mode ne '' ? " $mode" : '' );
	}
	# ID非表示権限有り
	if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
		return " ID:???$mode";
	}
	# 強制IDの場合
	if ($Set->Equal('BBS_FORCE_ID', 'checked')) {
		return " ID:$id";
	}
	# 任意IDの場合
	@mail = ('mail');
	if (! $Form->IsInput(\@mail)) {
		return " ID:$id";
	}
	
	return " ID:???$mode";
}

#------------------------------------------------------------------------------------------------------------
#
#	特殊文字変換 - ConvertCharacter0
#	--------------------------------------
#	引　数：$data : 変換元データの参照
#			$mode : 
#	戻り値：なし
#
#	2011.07.17 色々
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter0
{
	my $this = shift;
	my ($data) = @_;
	
	$$data = '' if (! defined $$data);
	
	$$data =~ s/^($ZP::RE_SJIS*?)＃/$1#/g;
}

#------------------------------------------------------------------------------------------------------------
#
#	特殊文字変換 - ConvertCharacter1
#	--------------------------------------
#	引　数：$data : 変換元データの参照
#			$mode : 
#	戻り値：なし
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter1
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (! defined $$data);
	
	# all
	$$data =~ s/</&lt;/g;
	$$data =~ s/>/&gt;/g;
	
	# mail
	if ($mode == 1) {
		$$data =~ s/"/&quot;/g;#"
	}
	
	# text
	if ($mode == 2) {
		$$data =~ s/\n/<br>/g;
	}
	# not text
	else {
		$$data =~ s/\n//g;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	禁則文字変換 - ConvertCharacter2
#	--------------------------------------
#	引　数：$data : 変換元データの参照
#			$mode : 
#	戻り値：なし
#
#	2010.08.15 色々
#	 -> プラグイン互換性維持につき処理順序の変更
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter2
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (! defined $$data);
	
	# name mail
	if ($mode == 0 || $mode == 1) {
		$$data =~ s/★/☆/g;
		$$data =~ s/◆/◇/g;
		$$data =~ s/削除/”削除”/g;
	}
	
	# name
	if ($mode == 0) {
		$$data =~ s/管理/”管理”/g;
		$$data =~ s/管直/”管直”/g;
		$$data =~ s/復帰/”復帰”/g;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	特殊文字変換 - ConvertFusianasan
#	--------------------------------------
#	引　数：$data : 変換元データの参照
#			$mode : 
#	戻り値：なし
#
#	2011.07.17 色々
#
#------------------------------------------------------------------------------------------------------------
sub ConvertFusianasan
{
	my $this = shift;
	my ($data, $host) = @_;
	
	$$data = '' if (! defined $$data);
	
	$$data =~ s/山崎渉/fusianasan/g;
	$$data =~ s|^($ZP::RE_SJIS*?)fusianasan|$1</b>$host<b>|g;
	$$data =~ s|^($ZP::RE_SJIS*?)fusianasan|$1 </b>$host<b>|g;
}

#------------------------------------------------------------------------------------------------------------
#
#	連続アンカー検出 - IsAnker
#	--------------------------------------
#	引　数：$text : 検査対象テキスト
#			$num  : 最大アンカー数
#	戻り値：0:許容内 1:だめぽ
#
#------------------------------------------------------------------------------------------------------------
sub IsAnker
{
	my $this = shift;
	my ($text, $num) = @_;
	my ($cnt);
	
	$cnt = 0;
	
	$_ = $$text;
	$cnt = s/&gt;&gt;(\d+)//g;
	
	return ($cnt > $num ? 1 : 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	リファラ判断 - IsReferer
#	--------------------------------------
#	引　数：$M : モジュール
#	戻り値：許可なら0,NGなら1
#
#------------------------------------------------------------------------------------------------------------
sub IsReferer
{
	my $this = shift;
	my ($M, $pENV) = @_;
	my ($svr);
	
	$svr = $M->Get('SERVER');
	if ($pENV->{'HTTP_REFERER'} =~ /\Q$svr\E/) {		# 自鯖からならOK
		return 0;
	}
	if ($pENV->{'HTTP_USER_AGENT'} =~ /Monazilla/) {	# ２ちゃんツールもOK
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	プロクシチェック - IsProxy
#	--------------------------------------
#	引　数：なし
#	戻り値：プロクシなら対象ポート番号
#
#	2010.08.12 windyakin ★
#	 -> BBQ, BBX, スパムちゃんぷるー のDNSBL問い合わせ式に変更
#	2010.08.23 windyakin ★
#	 -> p2.2ch.net をプロキシ経由で書き込みした場合串マークを表示
#
#------------------------------------------------------------------------------------------------------------
sub IsProxy
{
	my $this = shift;
	my ($sys, $oForm, $from, $mode) = @_;
	my ($addr, @dnsbls);
	
	@dnsbls = ();
	
	push(@dnsbls, 'niku.2ch.net') if($sys->Get('BBQ'));
	push(@dnsbls, 'bbx.2ch.net') if($sys->Get('BBX'));
	push(@dnsbls, 'dnsbl.spam-champuru.livedoor.com') if($sys->Get('SPAMCH'));
	
	# 携帯, iPhone(3G回線) はプロキシ規制を回避する
	if ( $mode eq "O" || $mode eq "i" ) {
		return 0;
	}
	
	# DNSBL問い合わせ
	$addr = join('.', reverse( split(/\./, $ENV{'REMOTE_ADDR'})));
	foreach my $dnsbl (@dnsbls) {
		if ( CheckDNSBL("$addr.$dnsbl") eq '127.0.0.2' ) {
			$oForm->Set('FROM', "</b> [―\{}\@{}\@{}-] <b>$from");
			return ( $mode eq "P" ? 0 : 1 );
		}
	}
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	DNSBL正引き(timeout付き) - CheckDNSBL
#	--------------------------------------
#	引　数：$host : 正引きするHOST
#	戻り値：プロキシであれば127.0.0.2
#
#------------------------------------------------------------------------------------------------------------
sub CheckDNSBL
{
	
	my ( $host ) = @_;
	my ( $res, $query, @ans );
	
	require Net::DNS;
	
	$res = Net::DNS::Resolver->new;
	$res->tcp_timeout(1);
	$res->udp_timeout(1);
	$res->retry(1);
	
	if ( ($query = $res->query($host)) ) {
		
		@ans = $query->answer;
		
		foreach ( @ans ) {
			return $_->address;
		}
	}
	if ( $res->errorstring eq 'query timed out' ) {
		return "127.0.0.0";
	}
	
	return "127.0.0.1";
	
}

#------------------------------------------------------------------------------------------------------------
#
#	パス合成・正規化 - MakePath
#	--------------------------------------
#	引　数：
#	戻り値：
#
#	2011.02.13 色々
#
#------------------------------------------------------------------------------------------------------------
sub MakePath {
	my $this = undef;
	$this = shift if (ref($_[0]) eq 'GALADRIEL');
	my ($path1, $path2) = @_;
	my (@dir1, @dir2, @dir3, $path3, $absflg, $depth);
	
	$path1 = '.' if (! defined $path1 || $path1 eq '');
	$path2 = '.' if (! defined $path2 || $path2 eq '');
	
	@dir1 = ($path1 =~ m[^/|[^/]+]g);
	@dir2 = ($path2 =~ m[^/|[^/]+]g);
	
	if ($dir2[0] eq '/') {
		$absflg = 1;
		@dir1 = @dir2;
	}
	else {
		$absflg = 0;
		push @dir1, @dir2;
	}
	
	@dir3 = ();
	
	$depth = 0;
	for my $i (0 .. $#dir1) {
		if ($i == 0 && $dir1[$i] eq '/') {
			$absflg = 1;
		}
		elsif ($dir1[$i] eq '.' || $dir1[$i] eq '') {
		}
		elsif ($dir1[$i] eq '..') {
			if ($depth >= 1) {
				pop @dir3;
			}
			else {
				if ($absflg) {
					last;
				}
				if ($#dir3 == -1 || $dir3[$#dir3] eq '..') {
					push @dir3, '..';
				}
				else {
					pop @dir3;
				}
			}
			$depth--;
		}
		else {
			push @dir3, $dir1[$i];
			$depth++;
		}
	}
	
	if ($#dir3 == -1) {
		$path3 = ($absflg ? '/' : '.');
	}
	else {
		$path3 = ($absflg ? '/' : '') . join('/', @dir3);
	}
	
	return $path3;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

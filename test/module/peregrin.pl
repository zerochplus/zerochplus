#============================================================================================================
#
#	管理ログデータ管理モジュール(PEREGRIN)
#	peregrin.pl
#	----------------------------------------
#	2003.01.07 start
#	2003.01.22 共通インタフェイスへ移行
#	2003.03.06 ログ検索時のエラーをFIX
#	2003.06.25 Addメソッド追加
#
#	ぜろちゃんねるプラス
#	2010.08.13 一部ログ出力形式を変更
#	2010.08.14 一部ログ出力形式を変更
#
#============================================================================================================
package	PEREGRIN;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	引　数：
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my (@LOG, $PATH, $FILE, $MAX, $MAXA, $MAXH, $KIND, $obj);
	
	$obj = {
		'LOG'	=> \@LOG,
		'PATH'	=> $PATH,
		'FILE'	=> $FILE,
		'MAX'	=> $MAX,
		'MAXA'	=> $MAXA,
		'MAXH'	=> $MAXH,
		'KIND'	=> $KIND,
		'NUM'	=> 0
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	デストラクタ - DESTROY
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub DESTROY
{
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ読み込み - Load
#	------------------------------------------------
#	引　数：$M   : MELKOR
#			$log : ログ種類
#			$key : スレッドキー(書き込みの場合のみ)
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($M, $log, $key) = @_;
	my ($path, $file, $kind);
	
	undef @{$this->{'LOG'}};
	$this->{'PATH'}	= '';
	$this->{'FILE'}	= '';
	$this->{'KIND'}	= 0;
	$this->{'MAX'}	= $M->Get('ERRMAX');
	$this->{'MAXA'}	= $M->Get('ADMMAX');
	$this->{'MAXH'}	= $M->Get('HISMAX');
	$this->{'NUM'}	= 0;
	
	$path = $M->Get('BBSPATH') . '/' . $M->Get('BBS') . '/log';		# 掲示板パス
	
	if ($log eq 'ERR')		{ $file = 'errs.cgi';	$kind = 1; }	# エラーログ
	elsif ($log eq 'THR')	{ $file = 'IP.cgi';		$kind = 2; }	# スレッド作成ログ
	elsif ($log eq 'WRT')	{ $file = "$key.cgi";	$kind = 3; }	# 書き込みログ
	elsif ($log eq 'HST')	{ $file = "HOSTs.cgi";	$kind = 5; }	# ホストログ
	elsif ($log eq 'SMB')	{ $file = "samba.cgi";	$kind = 6; }	# Sambaログ
	else {															# 異常
		$file = '';
		$kind = 0;
	}
	
	if ($kind) {													# 正常に設定
		if (-e "$path/$file") {
			open LOG, "<$path/$file";
			while (<LOG>) {
				push @{$this->{'LOG'}}, $_;
				$this->{'NUM'}++;
			}
			close LOG;
		}
		$this->{'PATH'} = $path;
		$this->{'FILE'} = $file;
	}
	$this->{'KIND'} = $kind;
}

#------------------------------------------------------------------------------------------------------------
#
#	エラーログ書き込み - SaveError
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($M) = @_;
	my ($path, $file);
	
	$path	= $this->{'PATH'};
	$file	= $this->{'FILE'};
	
	if ($this->{'KIND'}) {
		eval { chmod 0666, "$path/$file"; };				# パーミッション設定
		open LOG, ">$path/$file";
		eval { flock LOG, 2; };
		print LOG @{$this->{'LOG'}};
		close LOG;
		eval { chmod $M->Get('PM-LOG'), "$path/$file"; };	# パーミッション設定
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ追加 - Set
#	-------------------------------------------
#	引　数：$I     : ISILDUR
#			$data1 : 汎用データ1
#			$data2 : 汎用データ2
#			$host  : リモートホスト
#			$data  : DAT形式のログ
#			$mode  : ID末尾分
#	戻り値：なし
#
#	2010.08.12 windyakin ★
#	 -> 通常書き込みログ出力形式を２ちゃんねる形式へ変更
#
#	2010.08.14 windyakin ★
#	 -> 携帯,p2のHOST部分のログ出力を変更
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($I, $data1, $data2, $host, $data, $mode) = @_;
	my ($work, $nm, $tm, $bf, $kind, $tsw, @logdat);
	
	$bf		= 0;
	$nm		= $this->{'NUM'};														# ログ数取得
	$kind	= $this->{'KIND'};
	$tsw	= $ENV{'REMOTE_HOST'};
	$mode	= '0' if (! defined $mode);
	
	if ($mode ne '0') {
		if ($mode eq 'P') {
			$host = "$tsw($host)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$tsw($host)";
		}
	}
	
	if ($kind) {																	# 読み込み済み
		if ($kind == 1 && $nm >= $this->{'MAX'}) { $bf = 1; }						# エラーログ
		elsif ($kind == 2 && $nm >= $I->Get('BBS_THREAD_TATESUGI')) { $bf = 1; }	# スレッドログ
		elsif ($kind == 3 && $nm >= $I->Get('timecount')) { $bf = 1; }				# 書き込みログ
		
		$tm = time;
		
		if ($kind eq 3) {
			
			@logdat = split(/<>/, $data, 5);
			
			$work = join('<>',
				$logdat[0],
				$logdat[1],
				$logdat[2],
				substr($logdat[3], 0, 30),
				$logdat[4],
				$host,
				$ENV{'REMOTE_ADDR'},
				$data1,
				$ENV{'HTTP_USER_AGENT'}
			) . "\n";
			
		}
		else {
			$work = join('<>',
				$tm,
				$data1,
				$data2,
				$host
			) . "\n";
		}
		
		push @{$this->{'LOG'}}, $work;												# 末尾へ追加
		$this->{'NUM'}++;
		
		if ($bf) {																	# ログ最大値を越えた
			shift @{$this->{'LOG'}};												# 先頭ログの削除
			$this->{'NUM'}--;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ取得 - Get
#	-------------------------------------------
#	引　数：$ln : ログ番号
#	戻り値：@data
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($ln) = @_;
	my (@data, $work);
	
	$work = $this->{'LOG'}->[$ln];
	chomp $work;
	@data = split(/<>/, $work);
	
	return @data;
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ検索 - Search
#	-------------------------------------------
#	引　数：$data : サーチキー
#			$f    : サーチモード
#	戻り値：見つかれば1,なければ0
#
#	2010.08.13 windyakin ★
#	 -> ログ保存形式変更によるシステムの変更
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my $this = shift;
	my ($data, $f) = @_;
	my ($key, $dmy, $num, $i, $dat, $kind);
	
	$kind = $this->{'KIND'};
	
	if ($f == 1) {												# data1で検索
		$num = @{$this->{'LOG'}};
		for ($i = $num - 1 ; $i >= 0 ; $i--) {
			$dmy = $this->{'LOG'}->[$i];
			chomp $dmy;
			($key, $dat) = (split(/<>/, $dmy))[($kind == 3 ? (7, 5) : (1, 3))];
			if ($data eq $key) {
				return $dat;
			}
		}
	}
	elsif ($f == 2) {											# host出現数
		$num = 0;
		$dat = @{$this->{'LOG'}};
		for ($i = $dat - 1;$i >= 0;$i--) {
			$dmy = $this->{'LOG'}->[$i];
			chomp $dmy;
			$key = (split(/<>/, $dmy))[($kind == 3 ? 5 : 3)];
			if ($data eq $key) {
				$num++;
			}
		}
		return $num;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	時間判定 - IsTime
#	-------------------------------------------
#	引　数：$tmn : 判定時間(秒)
#	戻り値：時間内:残り秒数,時間外:0
#	備　考：最終ログから$tmn秒経過したかどうかを判定
#
#------------------------------------------------------------------------------------------------------------
sub IsTime
{
	my $this = shift;
	my ($tmn, $host) = @_;
	my ($i, $n, $work, $tm, $nw, $hst, $kind);
	
	$nw = time;
	$n = @{$this->{'LOG'}};
	$kind = $this->{'KIND'};
	
	return 0 if ($kind == 3);
	
	for ($i = $n - 1 ; $i >= 0 ; $i--) {
		($tm, undef, undef, $hst) = split(/<>/, $this->{'LOG'}->[$i]);
		chomp $hst;
		if ($host eq $hst) {
			if ($nw - $tm > $tmn) { return 0; }
			else {
				return ($tmn - ($nw - $tm));	# 残り秒数を返す
			}
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	Samba判定 - IsSamba
#	-------------------------------------------
#	引　数：$M    : 
#			$host : 
#	戻り値：$n    : Samba回数
#			$tm   : 必要待ち時間
#
#------------------------------------------------------------------------------------------------------------
sub IsSamba
{
	my $this = shift;
	my ($sb, $host) = @_;
	my (@iplist, $i, $n, $tm, $nw, $hst, $kind);
	
	$nw = time;
	$n = @{$this->{'LOG'}};
	$kind = $this->{'KIND'};
	
	return (0, 0) if ($kind != 6);
	
	for ($i = 0 ; $i < $n ; $i++) {
		($tm, undef, undef, $hst) = split(/<>/, $this->{'LOG'}->[$i]);
		chomp $hst;
		if (($host eq $hst) && ($sb >= $nw - $tm)) {
			push @iplist, $tm;
		}
	}
	$n = @iplist;
	if ($n) {
		return ($n, ($nw - $iplist[$#iplist]));
	}
	return (0, 0);
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

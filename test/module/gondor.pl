#============================================================================================================
#
#	datファイル管理モジュール
#	gondor.pl
#	-------------------------------------------------------------------------------------
#	2004.04.24 start
#
#============================================================================================================
package	ARAGORN;

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
	my ($obj, @LINES);
	
	$obj = {
		'LINE'		=> \@LINES,
		'PATH'		=> undef,
		'RES'		=> 0,
		'HANDLE'	=> undef,
		'MAX'		=> 0,
		'STAT'		=> 0,
		'PERM'		=> 0,
		'MODE'		=> 0
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	デストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DESTROY
{
	my $this = shift;
	
	# ファイルオープン状態の場合はクローズする
	if ($this->{'STAT'}) {
		my $handle	= $this->{'HANDLE'};
		if ($handle) {
			eval {
				close $handle;
				chmod $this->{'PERM'}, $this->{'PATH'};
			};
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	読み込み
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@param	$path	読み込みパス
#	@param	$readOnly	モード
#	@return	成功したら読み込んだレス数
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($SYS, $szPath, $readOnly) = @_;
	
	eval {
		$this->{'RES'} = 0;
		
		# 状態が初期状態なら読み込み開始
		if ($this->{'STAT'} == 0) {
			undef @{$this->{'LINE'}};
			$this->{'MAX'} = $SYS->Get('RESMAX');
			$this->{'PATH'} = $szPath;
			$this->{'PERM'} = GetPermission($szPath);
			$this->{'MODE'} = $readOnly;
			
			if (-e $szPath) {
				chmod 0777, $szPath;
				open DATFILE, "< $szPath";
				binmode DATFILE;
				while (<DATFILE>) {
					push @{$this->{'LINE'}}, $_;
				}
				
				# 書き込みモードの場合
				if (!$readOnly) {
					close DATFILE;
					open DATFILE, "+> $szPath";
					flock DATFILE, 2;
					binmode DATFILE;
				}
				
				# ハンドルを保存し状態を読み込み状態にする
				$this->{'HANDLE'}	= *DATFILE;
				$this->{'STAT'}		= 1;
				$this->{'RES'}		= @{$this->{'LINE'}};
			}
		}
	};
	return $this->{'RES'};
}

#------------------------------------------------------------------------------------------------------------
#
#	再読み込み
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@param	$readOnly	モード
#	@return	成功したら読み込んだレス数
#
#------------------------------------------------------------------------------------------------------------
sub ReLoad
{
	my $this = shift;
	my ($SYS, $readOnly) = @_;
	
	if ($this->{'STAT'}) {
		$this->Close();
		return $this->Load($SYS, $this->{'PATH'}, $readOnly);
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($SYS) = @_;
	my ($handle);
	
	# ファイルオープン状態なら書き込みを実行する
	if ($this->{'STAT'} && $this->{'HANDLE'}) {
		if (! $this->{'MODE'}) {
			$handle = $this->{'HANDLE'};
			eval {
				truncate $handle, 0;
				seek $handle, 0, 0;
				print $handle @{$this->{'LINE'}};
				close $handle;
				chmod $this->{'PERM'}, $this->{'PATH'};
			};
			$this->{'STAT'}		= 0;
			$this->{'HANDLE'}	= undef;
		}
		else {
			$this->Close();
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	強制クローズ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Close
{
	my $this = shift;
	
	# ファイルオープン状態の場合はクローズする
	if ($this->{'STAT'}) {
		eval {
			my $handle	= $this->{'HANDLE'};
			close $handle;
			chmod $this->{'PERM'}, $this->{'PATH'};
			$this->{'STAT'}		= 0;
			$this->{'HANDLE'}	= undef;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	データ設定
#	-------------------------------------------------------------------------------------
#	@param	$line	設定行
#	@param	$data	設定データ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($line, $data) = @_;
	
	$this->{'LINE'}->[$line] = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ取得
#	-------------------------------------------------------------------------------------
#	@param	$line	取得行
#	@return	行データの参照
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($line) = @_;
	
	if ($line >= 0 && $line < $this->{'RES'}) {
		return \($this->{'LINE'}->[$line]);
	}
	return undef;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ追加
#	-------------------------------------------------------------------------------------
#	@param	$data	追加データ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($data) = @_;
	
	# 最大データ数内なら追加する
	if ($this->{'MAX'} > $this->{'RES'}) {
		push @{$this->{'LINE'}}, $data;
		$this->{'RES'}++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	データ削除
#	-------------------------------------------------------------------------------------
#	@param	$num	削除行
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($num) = @_;
	
	splice @{$this->{'LINE'}}, $num, 1;
	$this->{'RES'}--;
}

#------------------------------------------------------------------------------------------------------------
#
#	レス数取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	レス数
#
#------------------------------------------------------------------------------------------------------------
sub Size
{
	my $this = shift;
	
	return $this->{'RES'};
}

#------------------------------------------------------------------------------------------------------------
#
#	サブジェクト取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	サブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub GetSubject
{
	my $this = shift;
	my (@elem, $subject);
	
	@elem = split(/<>/, $this->{'LINE'}->[0]);
	$subject = $elem[4];
	chomp $subject;
	
	return $subject;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド停止
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	成功:1 失敗:0
#
#------------------------------------------------------------------------------------------------------------
sub Stop
{
	my $this = shift;
	my ($SYS) = @_;
	my ($stopData, $res);
	
	# ↓スレスト文言
	$stopData = "書けませんよ。。。<>停止<>停止<>真・スレッドストッパー。。。（￣ー￣）ﾆﾔﾘｯ<>\n";
	$res = 0;
	
	eval {
		# レス最大数超えてる場合はスレスト不可
		if ($this->Size() <= $SYS->Get('RESMAX')) {
			# 停止状態じゃない場合のみ実行
			if ($this->{'PERM'} ne $SYS->Get('PM-STOP')) {
				# 停止データを追加して強制的にセーブする
				$this->Add($stopData);
				$this->Save($SYS);
				
				# パーミッションを停止用に設定する
				chmod $SYS->Get('PM-STOP'), $this->{'PATH'};
				$res = 1;
			}
		}
	};
	return $res;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド開始
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	成功:1 失敗:0
#
#------------------------------------------------------------------------------------------------------------
sub Start
{
	my $this = shift;
	my ($SYS) = @_;
	my ($res, $line);
	
	$res = 0;
	eval {
		# 停止状態の場合のみ実行
		if ($this->{'PERM'} eq $SYS->Get('PM-STOP')) {
			# 最終行を削除して保存
			$line = $this->{'RES'} - 1;
			$this->Delete($line);
			$this->Save($SYS);
			
			# パーミッションを通常用に設定する
			chmod $SYS->Get('PM-DAT'), $this->{'PATH'};
			$res = 1;
		}
	};
	return $res;
}

#------------------------------------------------------------------------------------------------------------
#
#	dat直接追記
#	-------------------------------------------------------------------------------------
#	@param	$path	追記ファイルパス
#	@param	$data	追記データ
#	@return	追記できたら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub DirectAppend
{
	my ($SYS, $path, $data) = @_;
	my $ret = 0;
	
	eval {
		if (GetPermission($path) ne $SYS->Get('PM-STOP')) {
			open DATFILE, ">> $path";
			flock DATFILE, 2;
			binmode DATFILE;
			print DATFILE "$data";
			close DATFILE;
			chmod $SYS->Get('PM-DAT'), $path;
		}
		else {
			$ret = 2;
		}
	};
	if ($@ ne '') {
		$ret = 1;
	}
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	ファイル指定レス数取得
#	-------------------------------------------------------------------------------------
#	@param	$path	指定ファイルパス
#	@return	レス数
#
#------------------------------------------------------------------------------------------------------------
sub GetNumFromFile
{
	my ($path) = @_;
	my $cnt = 0;
	
	if (-e $path) {
		open FILE, "< $path";
		while (<FILE>) {
			$cnt++;
		}
		close FILE;
	}
	return $cnt;
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション取得
#	-------------------------------------------------------------------------------------
#	@param	$path	指定ファイルパス
#	@return	パーミッション
#
#------------------------------------------------------------------------------------------------------------
sub GetPermission
{
	my ($path) = @_;
	
	return (-e $path ? (stat $path)[2] % 01000 : 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	移転検査
#	-------------------------------------------------------------------------------------
#	@param	$path	指定ファイルパス
#	@return	パーミッション
#
#------------------------------------------------------------------------------------------------------------
sub IsMoved
{
	my ($path) = @_;
	my (@elem, $line);
	
	if (-e $path) {
		open FILE, "< $path";
		while (<FILE>) {
			$line = $_;
			last;
		}
		close FILE;
		@elem = split(/<>/, $line);
		if ($elem[2] eq '移転') {
			return 1;
		}
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	デバグ用出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DEBUG
{
	my $this = shift;
	my ($pStream) = @_;
	
	print $pStream "DEBUG MODE ------- \n";
	print $pStream @{$this->{'LINE'}};
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

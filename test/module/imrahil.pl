#============================================================================================================
#
#	ログ管理モジュール
#	imrahil.pl
#	-------------------------------------------------------------------------------------
#	2005.04.02 start
#
#============================================================================================================
package	IMRAHIL;
use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#	Modeのビットについて
#	--------------------------------------
#	0:読取専用
#	1:オープンと同時に内容読み込み
#	2:最大サイズを超えたログを保存
#	3〜:未使用
#------------------------------------------------------------------------------------------------------------

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
	my ($File, $Limit, $Mode) = @_;
	my ($obj, @LOGS);
	local *HANDLE;
	
	$obj = {
		'LOGS'		=> \@LOGS,
		'PATH'		=> $File,
		'SIZE'		=> 0,
		'HANDLE'	=> *HANDLE,
		'LIMIT'		=> $Limit,
		'STAT'		=> 0,
		'MODE'		=> $Mode
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
		my $handle = $this->{'HANDLE'};
		if ($handle) {
#			eval
			{
				close $handle;
			};
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ログオープン
#	-------------------------------------------------------------------------------------
#	@param	$File	ログファイルパス(拡張子除く)
#	@param	$Limit	ログ最大サイズ
#	@param	$Mode	モード
#	@return	成功:0,失敗:-1
#
#------------------------------------------------------------------------------------------------------------
sub Open
{
	my $this = shift;
	my ($File, $Limit, $Mode) = @_;
	my $ret = -1;
	
	if (defined $File && defined $Limit && defined $Mode) {
		$this->{'PATH'} = $File;
		$this->{'LIMIT'} = $Limit;
		$this->{'MODE'} = $Mode;
	}
	else {
		$File = $this->{'PATH'};
		$Limit = int $this->{'LIMIT'};
		$Mode = int $this->{'MODE'};
	}
	
	if (defined  $this->{'HANDLE'}) {
		local *HANDLE;
		$this->{'HANDLE'} = *HANDLE;
	}
	$File .= '.cgi';
	
#	eval
	{
		if ($this->{'STAT'} == 0) {
			my $handle = $this->{'HANDLE'};
			open $handle, "+>> $File";
			flock $handle, 2 if ($Mode & 1);
			binmode $handle;
			
			$this->{'STAT'} = 1;
			$ret = 0;
			if ($Mode & 2) {
				$ret = $this->Read();
			}
		}
	};
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	ログクローズ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Close
{
	my $this = shift;
	
	if ($this->{'STAT'} == 1) {
#		eval
		{
			my $handle = $this->{'HANDLE'};
			close $handle;
			$this->{'STAT'} = 0;
		};
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	読み込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	成功:0,失敗:-1
#
#------------------------------------------------------------------------------------------------------------
sub Read
{
	my $this = shift;
	my $ret = -1;
	
	if ($this->{'STAT'} == 1) {
#		eval
		{
			my $handle = $this->{'HANDLE'};
			my $count = 0;
			undef @{$this->{'LOGS'}};
			seek $handle, 0, 0;
			while (<$handle>) {
				chomp $_;
				push @{$this->{'LOGS'}}, $_;
				$count++;
			}
			$this->{'SIZE'} = $count;
			$ret = 0;
		};
	}
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	書き込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	
	# ファイルオープン状態なら書き込みを実行する
	if ($this->{'STAT'}) {
		if (! ($this->{'MODE'} & 1)) {
			my $handle = $this->{'HANDLE'};
#			eval
			{
				truncate $handle, 0;
				seek $handle, 0, 0;
				for (my $i = 0 ; $i < $this->{'SIZE'} ; $i++) {
					print $handle $this->{'LOGS'}->[$i] . "\n";
				}
				close $handle;
			};
			$this->{'STAT'} = 0;
		}
		else {
			$this->Close();
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	データ取得
#	-------------------------------------------------------------------------------------
#	@param	$line	取得データ行
#	@return	取得データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($line) = @_;
	
	if ($line >= 0 && $line < $this->{'SIZE'}) {
		return $this->{'LOGS'}->[$line];
	}
	return undef;
}

#------------------------------------------------------------------------------------------------------------
#
#	データ追加
#	-------------------------------------------------------------------------------------
#	@param	$pData	追加データ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Put
{
	my $this = shift;
	my (@datas) = @_;
	my ($logData, $tm);
	
	if ($this->{'SIZE'} + 1 > $this->{'LIMIT'}) {
		my $old = shift @{$this->{'LOGS'}};
		if ($this->{'MODE'} & 4) {
			my $logName = $this->{'PATH'} . '_old.cgi';
#			eval
			{
				open OLDLOG, ">> $logName";
				flock OLDLOG, 2;
				binmode OLDLOG;
				print OLDLOG "$old\n";
				close OLDLOG;
			};
		}
		$this->{'SIZE'}--;
	}
	$tm = time;
	$logData = join('<>', $tm, @datas);
	
	push @{$this->{'LOGS'}}, $logData;
	$this->{'SIZE'}++;
}

#------------------------------------------------------------------------------------------------------------
#
#	サイズ取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	サイズ
#
#------------------------------------------------------------------------------------------------------------
sub Size
{
	my $this = shift;
	return $this->{'SIZE'};
}

#------------------------------------------------------------------------------------------------------------
#
#	ログ退避
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub MoveToOld
{
	my $this = shift;
	my ($i);
	
#	eval
	{
		open OLDLOG, ">> " . $this->{'PATH'} . '_old.cgi';
		flock OLDLOG, 2;
		binmode OLDLOG;
		for($i = 0 ; $i < $this->{'SIZE'} ; $i++) {
			print OLDLOG $this->{'LOGS'}->[$i] . "\n";
		}
		close OLDLOG;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	ログクリア
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	undef @{$this->{'LOGS'}};
	$this->{'SIZE'} = 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	検索
#	-------------------------------------------------------------------------------------
#	@param	$index		検索要素のインデクス
#	@param	$word		検索データ
#	@param	$pResult	結果格納用配列の参照
#	@return	ヒット数
#
#------------------------------------------------------------------------------------------------------------
sub search
{
	my $this = shift;
	my ($index, $word, $pResult) = @_;
	my ($i, @elem, $num);
	
	$num = 0;
	for($i = 0 ; $i < $this->{'SIZE'} ; $i++) {
		@elem = split(/<>/, $this->{'LOGS'}->[$i]);
		if ($elem[$index] eq $word) {
			push @$pResult, $this->{'LOGS'}->[$i];
			$num++;
		}
	}
	return $num;
}
#============================================================================================================
#	Module END
#============================================================================================================
1;

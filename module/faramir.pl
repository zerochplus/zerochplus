#============================================================================================================
#
#	アクセスユーザ管理モジュール(FARAMIR)
#	faramir.pl
#	------------------------------------------
#	2002.12.15 start
#	2003.01.22 共通インタフェイスに移行
#	2003.02.25 役割変更
#------------------------------------------------------------------------------------------------------------
#
#	Load
#	Save
#	Set
#	Get
#	Clear
#	Check
#
#============================================================================================================
package	FARAMIR;

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
	my		$this = shift;
	my		(@USER,$TYPE,$METHOD,$obj);
	
	undef(%USER);
	
	$obj = {
		'TYPE'		=> $TYPE,
		'METHOD'	=> $METHOD,
		'USER'		=> \@USER
	};
	bless $obj,$this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ読み込み - Load
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：正常読み込み:0,エラー:1
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my		$this = shift;
	my		($Sys) = @_;
	my		(@datas,@head,$path,$dummy);
	
	undef(@{$this->{'USER'}});
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/access.cgi";
	
	if	(-e $path){
		open(USER,"<$path");
		@datas = <USER>;
		close(USER);
		
		($dummy,@datas) = @datas;
		chomp($dummy);
		@head = split(/<>/,$dummy);
		$this->{'TYPE'} = $head[0];
		$this->{'METHOD'} = $head[1];
		
		foreach	(@datas){
			chomp($_);
			push(@{$this->{'USER'}},$_)
		}
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ書き込み - Save
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：正常書き込み:0,エラー:-1
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my		$this = shift;
	my		($Sys) = @_;
	my		($path);
	
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/access.cgi";
	
	eval{
		open(USER,">$path");
		flock(USER,2);
		binmode(USER);
		print USER $this->{'TYPE'} . '<>' . $this->{'METHOD'} . "\n";
		foreach	(@{$this->{'USER'}}){
			print USER "$_\n";
		}
		close(USER);
		chmod($Sys->Get('PM-ADM'),$path);
	};
	if	($@ ne ''){
		return $@;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ追加 - Set
#	-------------------------------------------
#	引　数：$name : 追加ユーザ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my		$this = shift;
	my		($name) = @_;
	
	push(@{$this->{'USER'}},$name);
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#	戻り値：ユーザデータ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my		$this = shift;
	my		($key) = @_;
	
	return $this->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザクリア - Clear
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my		$this = shift;
	
	undef(@{$this->{'USER'}});
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザデータ設定 - SetData
#	-------------------------------------------
#	引　数：$key  : 設定キー
#			$data : 設定データ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my		$this = shift;
	my		($key,$data) = @_;
	
	$this->{$key} = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ調査 - Check
#	-------------------------------------------
#	引　数：$host : 調査ホスト
#	戻り値：登録ユーザ:1,未登録ユーザ:0
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my		$this = shift;
	my		($host) = @_;
	my		($flag);
	
	$flag = 0;
	foreach	(@{$this->{'USER'}}){
		if	($host =~ /$_/){
			$flag = 1;
			last;
		}
	}
	if	($flag && $this->{'TYPE'} eq 'disable'){									# 規制ユーザ
		if	($this->{'METHOD'} eq 'disable'){										# 処理：書き込み不可
			return 4;
		}
		elsif	($this->{'METHOD'} eq 'host'){										# 処理：ホスト表示
			return 2;
		}
	}
	elsif	(!$flag && $this->{'TYPE'} eq 'enable'){									# 限定ユーザ以外
		if	($this->{'METHOD'} eq 'disable'){										# 処理：書き込み不可
			return 4;
		}
		elsif	($this->{'METHOD'} eq 'host'){										# 処理：ホスト表示
			return 2;
		}
	}
	return 0;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

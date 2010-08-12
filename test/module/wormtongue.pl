#============================================================================================================
#
#	NGワード管理モジュール(WORMTONGUE)
#	wormtongue.pl
#	---------------------------------------
#	2003.02.06 start
#	2003.04.05 Get,Method追加
#------------------------------------------------------------------------------------------------------------
#
#	Object																			; オブジェクト取得
#	Load																			; NGワード読み込み
#	Save																			; NGワード書き込み
#	Set																				; NGワード追加
#	Get																				; NGワードデータ取得
#	Clear																			; NGワード削除
#	Check																			; NGワード調査
#	Method																			; NGワード処理
#
#============================================================================================================
package	WORMTONGUE;

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
	my		(@NGWORD,$METHOD,$SUBSTITUTE,$obj);
	
	undef @NGWORD;
	
	$obj = {
		'METHOD'	=> $METHOD,
		'SUBSTITUTE'=> $SUBSTITUTE,
		'NGWORD'	=> \@NGWORD
	};
	
	bless $obj,$this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード読み込み - Load
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my		$this = shift;
	my		($Sys) = @_;
	my		(@datas,@head,$path,$dummy);
	
	undef @{$this->{'NGWORD'}};
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/ngwords.cgi";
	
	if	(-e "$path"){
		open(NGWORD,"<$path");
		@datas = <NGWORD>;
		close(NGWORD);
		
		($dummy,@datas) = @datas;
		chomp($dummy);
		@head = split(/<>/,$dummy);
		$this->{'METHOD'} = $head[0];
		$this->{'SUBSTITUTE'} = $head[1];
		
		foreach	(@datas){
			chomp($_);
			push(@{$this->{'NGWORD'}},$_)
		}
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード書き込み - Save
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my		$this = shift;
	my		($Sys) = @_;
	my		($path);
	
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/ngwords.cgi";
	
	eval{
		open(NGWORD,">$path");
		flock(NGWORD,2);
		binmode(NGWORD);
		print NGWORD $this->{'METHOD'} . '<>' . $this->{'SUBSTITUTE'} . "\n";
		foreach	(@{$this->{'NGWORD'}}){
			print NGWORD "$_\n";
		}
		close(NGWORD);
		chmod($Sys->Get('PM-ADM'),$path);
	};
	if	($@ ne ''){
		return $@;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード追加 - Set
#	-------------------------------------------
#	引　数：$key : NGワード
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my		$this = shift;
	my		($key) = @_;
	
	push(@{$this->{'NGWORD'}},$key);
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワードデータ取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#	戻り値：データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my		$this = shift;
	my		($key) = @_;
	
	return $this->{$key}
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワードデータ設定 - SetData
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
#	NGワードクリア - Clear
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my		$this = shift;
	
	undef(@{$this->{'NGWORD'}});
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード調査 - Check
#	-------------------------------------------
#	引　数：$S : SAMWISE
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my		$this = shift;
	my		($Form,$pList) = @_;
	my		($word,$key,$work);
	
	foreach	$word (@{$this->{'NGWORD'}}){
		foreach	$key (@$pList){
			$work = $Form->Get($key);
			if	($work =~ /$word/){
				return 2	if($this->{'METHOD'} eq 'host');
				return 3	if($this->{'METHOD'} eq 'disable');
				return 1;
			}
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード処理 - Method
#	-------------------------------------------
#	引　数：$S : SAMWISE
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Method
{
	my		$this = shift;
	my		($Form,$pList) = @_;
	my		($word,$work,$substitute,$key);
	
	# 処理種別が代替か削除の場合のみ処理
	if	($this->{'METHOD'} ne 'delete' && $this->{'METHOD'} ne 'substitute'){
		return;
	}
	else{
		# 代替用文字列を設定
		if	($this->{'METHOD'} eq 'delete'){
#			$substitute = '<b><font color=red>削除</font></b>';
			$substitute = '';
		}
		else{
			$substitute = $this->{'SUBSTITUTE'};
		}
	}
	
	foreach	$word (@{$this->{'NGWORD'}}){
		foreach	$key (@$pList){
			$work = $Form->Get($key);
			if	($work =~ /$word/){
				$work =~ s/$word/$substitute/g;
				$Form->Set($key,$work);
			}
		}
	}
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

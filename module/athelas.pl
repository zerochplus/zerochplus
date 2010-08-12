#============================================================================================================
#
#	プラグイン管理モジュール
#	athelas.pl
#	-------------------------------------------------------------------------------------
#	2005.02.19 start
#
#============================================================================================================
package	ATHELAS;

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
	my		($obj,%FILES,%CLASSES,%NAMES,%EXPS,%TYPES,%VALIDS);
	
	$obj = {
		'FILE'	=> \%FILES,
		'CLASS'	=> \%CLASSES,
		'NAME'	=> \%NAMES,
		'EXPL'	=> \%EXPS,
		'TYPE'	=> \%TYPES,
		'VALID'	=> \%VALIDS
	};
	bless($obj,$this);
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my		$this = shift;
	my		($Sys) = @_;
	my		($path,@elem);
	
	# ハッシュ初期化
	undef($this->{'FILE'});
	undef($this->{'CLASS'});
	undef($this->{'NAME'});
	undef($this->{'EXPL'});
	undef($this->{'TYPE'});
	undef($this->{'VALID'});
	
	$path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	if	(-e $path){
		open(PLUGINS,"<$path");
		while	(<PLUGINS>){
			chomp($_);
			@elem = split(/<>/,$_);
			if(@elem >= 7){
				$this->{'FILE'}->{$elem[0]}		= $elem[1];
				$this->{'CLASS'}->{$elem[0]}	= $elem[2];
				$this->{'NAME'}->{$elem[0]}		= $elem[3];
				$this->{'EXPL'}->{$elem[0]}		= $elem[4];
				$this->{'TYPE'}->{$elem[0]}		= $elem[5];
				$this->{'VALID'}->{$elem[0]}	= $elem[6];
			}
		}
		close(PLUGINS);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報保存
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my		$this = shift;
	my		($Sys) = @_;
	my		($path,$data);
	
	$path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	eval{
		open(PLUGINS,"+>$path");
		flock(PLUGINS,2);
		binmode(PLUGINS);
		truncate(PLUGINS,0);
		seek(PLUGINS,0,0);
		foreach	(keys %{$this->{'FILE'}}){
			$data = $_ . '<>' . $this->{'FILE'}->{$_};
			$data = $data . '<>' . $this->{'CLASS'}->{$_};
			$data = $data . '<>' . $this->{'NAME'}->{$_};
			$data = $data . '<>' . $this->{'EXPL'}->{$_};
			$data = $data . '<>' . $this->{'TYPE'}->{$_};
			$data = $data . '<>' . $this->{'VALID'}->{$_};
			
			print PLUGINS "$data\n";
		}
		close(PLUGINS);
		chmod($Sys->Get('PM-ADM'),$path);
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグインIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	検索種別
#	@param	$name	検索ワード
#	@param	$pBuf	IDセット格納バッファ
#	@return	キーセット数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my		$this = shift;
	my		($kind,$name,$pBuf) = @_;
	my		($key,$n);
	
	$n = 0;
	
	if	($kind eq 'ALL'){
		foreach	$key (keys %{$this->{NAME}}){
			push(@$pBuf,$key);
			$n++;
		}
	}
	else{
		foreach	$key (keys %{$this->{$kind}}){
			if	(($this->{$kind}->{$key} eq $name) || ($name eq 'ALL')){
				push(@$pBuf,$key);
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	ユーザID
#	@return	ユーザ情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my		$this = shift;
	my		($kind,$key) = @_;
	
	return $this->{$kind}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
#	@param	$kind	情報種別
#	@param	$val	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my		$this = shift;
	my		($id,$kind,$val) = @_;
	
	if	(exists($this->{$kind}->{$id})){
		$this->{$kind}->{$id} = $val;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン追加
#	-------------------------------------------------------------------------------------
#	@param	$file	プラグインファイル名
#	@param	$valid	有効フラグ
#	@return	プラグインID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my		$this = shift;
	my		($file,$valid) = @_;
	my		($id,$ret);
	
	$ret = undef;
	$id = time();
	while(exists($this->{'FILE'}->{$id})){
		$id ++;
	}
	if(-e "./plugin/$file"){
		if($file =~ /0ch_(.*)\.pl/){
			my $className = 'ZPL_' . $1;
			eval{
				require("./plugin/$file");
				my $plugin = new $className;
				$this->{'FILE'}->{$id}	= $file;
				$this->{'CLASS'}->{$id}	= $className;
				$this->{'NAME'}->{$id}	= $plugin->getName();
				$this->{'EXPL'}->{$id}	= $plugin->getExplanation();
				$this->{'TYPE'}->{$id}	= $plugin->getType();
				$this->{'VALID'}->{$id}	= $valid;
				$ret = $id;
			};
		}
	}
	return '';
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除プラグインID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my		$this = shift;
	my		($id) = @_;
	
	delete($this->{'FILE'}->{$id});
	delete($this->{'CLASS'}->{$id});
	delete($this->{'NAME'}->{$id});
	delete($this->{'EXPL'}->{$id});
	delete($this->{'TYPE'}->{$id});
	delete($this->{'VALID'}->{$id});
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報更新
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my		$this = shift;
	my		(@files,$file,$plugin,@buff,$exist);
	
	if(-e './plugin'){
		opendir(PLUGINS,'./plugin');
		@files = readdir(PLUGINS);
		closedir(PLUGINS);
		# プラグイン追加・更新フェイズ
		foreach $file (@files){
			if($file =~ /^0ch_(.*)\.pl/){
				my $className = 'ZPL_' . $1;
				if($this->GetKeySet('FILE',$file,\@buff) > 0){
					require("./plugin/$file");
					$plugin = new $className;
					$this->{'NAME'}->{$buff[0]} = $plugin->getName();
					$this->{'EXPL'}->{$buff[0]} = $plugin->getExplanation();
					$this->{'TYPE'}->{$buff[0]} = $plugin->getType();
					$plugin = undef;
				}
				else{
					$this->Add($file,0);
				}
				undef(@buff);
			}
		}
		# プラグイン削除フェイズ
		if($this->GetKeySet('ALL','',\@buff) > 0){
			$exist = 0;
			foreach $plugin (@buff){
				foreach $file (@files){
					if($this->Get('FILE',$plugin) eq $file){
						$exist = 1;
						last;
					}
				}
				if($exist == 0){
					$this->Delete($plugin);
				}
				$exist = 0;
			}
		}
	}
	else{
		undef($this->{'FILE'});
		undef($this->{'CLASS'});
		undef($this->{'NAME'});
		undef($this->{'EXPL'});
		undef($this->{'TYPE'});
		undef($this->{'VALID'});
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

#============================================================================================================
#
#	ユーザ通知管理モジュール
#	gandalf.pl
#	-------------------------------------------------------------------------------------
#	2004.09.11 start
#
#============================================================================================================
package	GANDALF;;

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
	my		($obj);
	
	$obj = {
		'TO'		=> undef,
		'FROM'		=> undef,
		'SUBJECT'	=> undef,
		'TEXT'		=> undef,
		'DATE'		=> undef,
		'LIMIT'		=> undef
	};
	bless($obj,$this);
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報読み込み
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
	undef($this->{'TO'});
	undef($this->{'FROM'});
	undef($this->{'SUBJECT'});
	undef($this->{'TEXT'});
	undef($this->{'DATE'});
	
	$path = '.' . $Sys->Get('INFO') . '/notice.cgi';
	
	if	(-e $path){
		open(NOTICE,"<$path");
		while	(<NOTICE>){
			chomp($_);
			@elem = split(/<>/,$_);
			$this->{'TO'}->{$elem[0]}		= $elem[1];
			$this->{'FROM'}->{$elem[0]}		= $elem[2];
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[3];
			$this->{'TEXT'}->{$elem[0]}		= $elem[4];
			$this->{'DATE'}->{$elem[0]}		= $elem[5];
			$this->{'LIMIT'}->{$elem[0]}	= $elem[6];
		}
		close(NOTICE);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報保存
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
	
	$path = '.' . $Sys->Get('INFO') . '/notice.cgi';
	
	eval{
		open(NOTICE,"+>$path");
		flock(NOTICE,2);
		binmode(NOTICE);
		truncate(NOTICE,0);
		seek(NOTICE,0,0);
		foreach	(keys %{$this->{'TO'}}){
			$data = $_ . '<>' . $this->{TO}->{$_};
			$data = $data . '<>' . $this->{FROM}->{$_};
			$data = $data . '<>' . $this->{SUBJECT}->{$_};
			$data = $data . '<>' . $this->{TEXT}->{$_};
			$data = $data . '<>' . $this->{DATE}->{$_};
			$data = $data . '<>' . $this->{LIMIT}->{$_};
			
			print NOTICE "$data\n";
		}
		close(NOTICE);
		chmod($Sys->Get('PM-ADM'),$path);
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	IDセット取得
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
		foreach	$key (keys(%{$this->{TO}})){
			push(@$pBuf,$key);
			$n++;
		}
	}
	else{
		foreach	$key (keys(%{$this->{$kind}})){
			if	(($this->{$kind}->{$key} eq $name) || ($kind eq 'ALL')){
				push(@$pBuf,$key);
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	ID
#	@return	情報
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
#	通知情報追加
#	-------------------------------------------------------------------------------------
#	@param	$to		通知先ユーザ
#	@param	$from	送信ユーザ
#	@param	$subj	タイトル
#	@param	$text	内容
#	@return	ID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my		$this = shift;
	my		($to,$from,$subj,$text,$limit) = @_;
	my		($id);
	
	$id = time();
	while	(exists($this->{'TO'}->{$id})){
		$id ++;
	}
	$this->{'TO'}->{$id}		= $to;
	$this->{'FROM'}->{$id}		= $from;
	$this->{'SUBJECT'}->{$id}	= $subj;
	$this->{'TEXT'}->{$id}		= $text;
	$this->{'DATE'}->{$id}		= time();
	$this->{'LIMIT'}->{$id}		= $limit;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		ID
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
#	通知情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除ID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my		$this = shift;
	my		($id) = @_;
	
	delete($this->{'TO'}->{$id});
	delete($this->{'FROM'}->{$id});
	delete($this->{'SUBJECT'}->{$id});
	delete($this->{'TEXT'}->{$id});
	delete($this->{'DATE'}->{$id});
	delete($this->{'LIMIT'}->{$id});
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報判定
#	-------------------------------------------------------------------------------------
#	@param	$id		通知ID
#	@param	$user	ユーザID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub IsInclude
{
	my		$this = shift;
	my		($id,$user) = @_;
	my		(@users);
	
	# 全体通知
	if	($this->{'TO'}->{$id} eq '*'){
		return 1;
	}
	
	@users = split(/\,/,$this->{'TO'}->{$id});
	foreach	(@users){
		if	($_ eq $user){
			return 1;
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知情報期限切れ判定
#	-------------------------------------------------------------------------------------
#	@param	$id		通知ID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub IsLimitOut
{
	my		$this = shift;
	my		($id) = @_;
	my		(@users);
	
	# 全体通知の場合のみ
	if	($this->{'TO'}->{$id} eq '*'){
		$now = time();
		if	($now > $this->{'LIMIT'}->{$id}){
			return 1;
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知先ユーザ削除
#	-------------------------------------------------------------------------------------
#	@param	$id		通知ID
#	@param	$user	ユーザID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub RemoveToUser
{
	my		$this = shift;
	my		($id,$user) = @_;
	my		(@users,@news);
	
	# 全体通知は個別削除不可
	if	($this->{'TO'}->{$id} eq '*'){
		return;
	}
	
	undef(@news);
	@users = split(/\,/,$this->{'TO'}->{$id});
	
	foreach	(@users){
		if	($_ ne $user){
			push(@news,$_);
		}
	}
	
	# すべての通知先ユーザが削除されたら、その通知は破棄する
	if	(@news == 0){
		$this->Delete($id);
	}
	else{
		$this->{'TO'}->{$id} = join(',',@news);
	}
}

sub DEBUG
{
	my		$this = shift;
	my		($Page) = @_;
	my		($id);
	
	$Page->Print("<b>DEBUG START</b><br>\n");
	foreach	$id (keys(%{$this->{'TO'}})){
		$Page->Print("　 To:" . $this->{'TO'}->{$id} . "<br>\n");
		$Page->Print("　 From:" . $this->{'FROM'}->{$id} . "<br>\n");
		$Page->Print("　 Subject:" . $this->{'SUBJECT'}->{$id} . "<br>\n");
		$Page->Print("　 Text:" . $this->{'TEXT'}->{$id} . "<br>\n");
		$Page->Print("　 Date:" . $this->{'DATE'}->{$id} . "<br>\n");
	}
	$Page->Print("<b>DEBUG END</b><br>\n");
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

#============================================================================================================
#
#	スレッド情報管理モジュール
#	baggins.pl
#	-------------------------------------------------------------------------------------
#	2004.02.18 start
#	2004.04.10 パッケージSACKBIL追加
#	2004.09.04 パッケージSACKBIL削除
#	-------------------------------------------------------------------------------------
#	このモジュールはスレッド情報を管理します。
#	以下の3つのパッケージによって構成されます
#
#	BILBO	: 現行スレッド情報管理
#	FRODO	: プールスレッド情報管理
#
#============================================================================================================

#============================================================================================================
#
#	スレッド情報管理パッケージ
#	NAZGUL
#	-------------------------------------------------------------------------------------
#	2004.02.18 start
#
#============================================================================================================
package	BILBO;

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
	my ($obj, %SUBJECT, %RES, @SORT);
	
	$obj = {
		'SUBJECT'	=> \%SUBJECT,
		'RES'		=> \%RES,
		'SORT'		=> \@SORT,
		'NUM'		=> 0
	};
	bless $obj, $this;
	
	return $obj;
}

sub DESTROY
{
	my $this = shift;
	
	if (0) {
		open DBG, ">> dbg_BILBO.log";
		print DBG ">>SUBJECTS\n";
		foreach (@{$this->{'SORT'}}) {
			if (exists $this->{'SUBJECT'}->{$_}) {
				print DBG "$_ : " . $this->{'SUBJECT'}->{$_} . " : " . $this->{'RES'}->{$_} . "\n";
			}
			else {
				print DBG "### missing\n";
			}
		}
		print DBG "--- End\n\n";
		close DBG;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, @elem, $dmy, $num);
	
	undef($this->{'SUBJECT'});
	undef($this->{'RES'});
	undef($this->{'SORT'});
	
	$path	= $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/subject.txt';
	$num	= 0;
	
	if (-e $path) {
		open(SUBJ, "< $path");
		while (<SUBJ>) {
			@elem = split(/<>/, $_);
			($elem[0], $dmy) = split(/\./, $elem[0]);
			$elem[1] =~ s/\((\d+)\)\n//;
			$elem[2] = $1;
			
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[1];
			$this->{'RES'}->{$elem[0]}		= $elem[2];
			push @{$this->{'SORT'}}, $elem[0];
			$num++;
		}
		close SUBJ;
		$this->{'NUM'} = $num;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報保存
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $data);
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/subject.txt';
	
	eval {
		open SUBJ, "+> $path";
		flock SUBJ, 2;
		truncate SUBJ, 0;
		seek SUBJ, 0, 0;
		binmode SUBJ;
		foreach (@{$this->{'SORT'}}) {
			$data = "$_.dat<>" . $this->{'SUBJECT'}->{$_};
			$data = "$data(" . $this->{'RES'}->{$_} . ')';
			
			print SUBJ "$data\n";
		}
		close SUBJ;
		chmod $Sys->Get('PM-TXT'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	検索種別('ALL'の場合すべて)
#	@param	$name	検索ワード
#	@param	$pBuf	IDセット格納バッファ
#	@return	キーセット数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($kind, $name, $pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	if ($kind eq 'ALL') {
		foreach $key (@{$this->{SORT}}) {
			push @$pBuf, $key;
			$n++;
		}
	}
	else {
		foreach $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	スレッドID
#	@return	スレッド情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key) = @_;
	
	return $this->{$kind}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報追加
#	-------------------------------------------------------------------------------------
#	@param	$subject	スレッドタイトル
#	@return	スレッドID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($id, $subject, $res) = @_;
	
	$this->{'SUBJECT'}->{$id}	= $subject;
	$this->{'RES'}->{$id}		= $res;
	unshift @{$this->{'SORT'}}, $id;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		スレッドID
#	@param	$kind	情報種別
#	@param	$val	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($id, $kind, $val) = @_;
	
	if (exists($this->{$kind}->{$id})) {
		$this->{$kind}->{$id} = $val;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除スレッドID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	my ($lid, $n);
	
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'RES'}->{$id};
	
	$n = 0;
	foreach $lid (@{$this->{'SORT'}}) {
		if ($id eq $lid) {
			splice @{$this->{'SORT'}}, $n, 1;
			last;
		}
		$n++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド数取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	スレッド数
#
#------------------------------------------------------------------------------------------------------------
sub GetNum
{
	my $this = shift;
	
	return $this->{'NUM'};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドあげ
#	-------------------------------------------------------------------------------------
#	@param	スレッドID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub AGE
{
	my $this = shift;
	my ($id) = @_;
	my ($lid, $n);
	
	$n = 0;
	foreach $lid (@{$this->{'SORT'}}) {
		if ($id eq $lid) {
			splice @{$this->{'SORT'}}, $n, 1;
			unshift @{$this->{'SORT'}}, $lid;
			last;
		}
		$n++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドだめ
#	-------------------------------------------------------------------------------------
#	@param	スレッドID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DAME
{
	my $this = shift;
	my ($id) = @_;
	my ($lid, $n);
	
	$n = 0;
	foreach $lid (@{$this->{'SORT'}}) {
		if ($id eq $lid) {
			splice @{$this->{'SORT'}}, $n, 1;
			push @{$this->{'SORT'}}, $lid;
			last;
		}
		$n++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報更新
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my $this = shift;
	my ($SYS) = @_;
	my ($id, $base, $n);
	
	$base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/dat';
	
	foreach $id (@{$this->{'SORT'}}) {
		$n = 0;
		if (-e "$base/$id.dat") {
			open DAT, "< $base/$id.dat";
			while (<DAT>) {
				$n++;
			}
			close DAT;
			$this->{'RES'}->{$id} = $n;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報完全更新
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub UpdateAll
{
	my $this = shift;
	my ($SYS) = @_;
	my (@dirSet, $id, $base, $n, $num, $first, $subj);
	
	undef $this->{'SUBJECT'};
	undef $this->{'RES'};
	undef $this->{'SORT'};
	
	$base	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/dat';
	$num	= 0;
	
	# ディレクトリ内一覧を取得
	opendir DATDIR, $base;
	@dirSet = readdir DATDIR;
	closedir DATDIR;
	
	foreach $el	(@dirSet) {
		if ($el =~ /(.*)\.dat/) {
			$n	= 0;
			$id	= $1;
			open DAT, "$base/$el";
			while (<DAT>) {
				if ($n == 0) {
					chomp $_;
					$first = $_;
				}
				$n++;
			}
			close DAT;
			(undef, undef, undef, undef, $subj) = split(/<>/, $first);
			$this->{'SUBJECT'}->{$id}	= $subj;
			$this->{'RES'}->{$id}		= $n;
			unshift @{$this->{'SORT'}}, $id;
			$num++;
		}
	}
	$this->{'NUM'} = $num;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド位置取得
#	-------------------------------------------------------------------------------------
#	@param	$id	スレッドID
#	@return	スレッド位置。取得できない場合は-1
#
#------------------------------------------------------------------------------------------------------------
sub GetPosition
{
	my $this = shift;
	my ($id) = @_;
	my ($iid, $n);
	
	$n = 0;
	foreach $iid (@{$this->{'SORT'}}) {
		if ($iid eq $id) {
			return $n;
		}
		$n++;
	}
	return -1;
}


#============================================================================================================
#
#	プールスレッド情報管理パッケージ
#	FRODO
#	-------------------------------------------------------------------------------------
#	2004.02.18 start
#
#============================================================================================================
package	FRODO;

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
	my ($obj, %SUBJECT, %RES, @SORT);
	
	$obj = {
		'SUBJECT'	=> \%SUBJECT,
		'RES'		=> \%RES,
		'SORT'		=> \@SORT,
		'NUM'		=> 0
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, @elem, $num);
	
	undef $this->{'SUBJECT'};
	undef $this->{'RES'};
	undef $this->{'SORT'};
	
	$path = $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/pool/subject.cgi';
	$num = 0;
	
	if (-e $path) {
		open SUBJ, "< $path";
		while (<SUBJ>) {
			@elem = split(/<>/, $_);
			($elem[0], undef) = split(/\./, $elem[0]);
			$elem[1] =~ s/\((\d+)\)\n//;
			$elem[2] = $1;
			
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[1];
			$this->{'RES'}->{$elem[0]}		= $elem[2];
			push @{$this->{'SORT'}}, $elem[0];
			$num++;
		}
		close SUBJ;
		$this->{'NUM'} = $num;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報保存
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $data);
	
	$path = $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/pool/subject.cgi';
	
	eval {
		open SUBJ, "+> $path";
		flock SUBJ, 2;
		truncate SUBJ, 0;
		seek SUBJ, 0, 0;
		binmode SUBJ;
		foreach (@{$this->{'SORT'}}) {
			$data = "$_.dat<>" . $this->{SUBJECT}->{$_};
			$data = "$data(" . $this->{RES}->{$_} . ')';
			
			print SUBJ "$data\n";
		}
		close SUBJ;
		chmod $Sys->Get('PM-TXT'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッドIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	検索種別('ALL'の場合すべて)
#	@param	$name	検索ワード
#	@param	$pBuf	IDセット格納バッファ
#	@return	キーセット数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($kind, $name, $pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	if ($kind eq 'ALL') {
		foreach $key (@{$this->{SORT}}) {
			push @$pBuf, $key;
			$n++;
		}
	}
	else {
		foreach $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	スレッドID
#	@return	スレッド情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key) = @_;
	
	return $this->{$kind}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報追加
#	-------------------------------------------------------------------------------------
#	@param	$subject	スレッドタイトル
#	@return	スレッドID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($id, $subject, $res) = @_;
	
	$this->{'SUBJECT'}->{$id}	= $subject;
	$this->{'RES'}->{$id}		= $res;
	unshift @{$this->{'SORT'}}, $id;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		スレッドID
#	@param	$kind	情報種別
#	@param	$val	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($id, $kind, $val) = @_;
	
	if (exists $this->{$kind}->{$id}) {
		$this->{$kind}->{$id} = $val;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除スレッドID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	my ($lid, $n);
	
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'RES'}->{$id};
	
	$n = 0;
	foreach $lid (@{$this->{'SORT'}}) {
		if ($id eq $lid) {
			splice @{$this->{'SORT'}}, $n, 1;
			last;
		}
		$n++;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド数取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	スレッド数
#
#------------------------------------------------------------------------------------------------------------
sub GetNum
{
	my $this = shift;
	
	return $this->{'NUM'};
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報更新
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my $this = shift;
	my ($SYS) = @_;
	my ($id, $base, $n);
	
	$base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/pool';
	
	foreach $id (@{$this->{'SORT'}}) {
		$n = 0;
		if (-e "$base/$id.cgi") {
			open DAT, "< $base/$id.cgi";
			while (<DAT>) {
				$n++;
			}
			close DAT;
			$this->{'RES'}->{$id} = $n;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	スレッド情報完全更新
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub UpdateAll
{
	my $this = shift;
	my ($SYS) = @_;
	my (@dirSet, $id, $base, $n, $num, $first, $subj);
	
	undef $this->{'SUBJECT'};
	undef $this->{'RES'};
	undef $this->{'SORT'};
	
	$base	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/pool';
	$num	= 0;
	
	# ディレクトリ内一覧を取得
	opendir DATDIR, $base;
	@dirSet = readdir DATDIR;
	closedir DATDIR;
	
	foreach $el (@dirSet) {
		if ($el =~ /(\d+)\.cgi/) {
			$n	= 0;
			$id	= $1;
			open DAT, "$base/$el";
			while (<DAT>) {
				if ($n == 0) {
					chomp $_;
					$first = $_;
				}
				$n++;
			}
			close DAT;
			(undef, undef, undef, undef, $subj) = split(/<>/, $first);
			$this->{'SUBJECT'}->{$id}	= $subj;
			$this->{'RES'}->{$id}		= $n;
			unshift @{$this->{'SORT'}}, $id;
			$num++;
		}
	}
	$this->{'NUM'} = $num;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

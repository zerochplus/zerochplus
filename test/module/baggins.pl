#============================================================================================================
#
#	スレッド情報管理モジュール
#	baggins.pl
#	-------------------------------------------------------------------------------------
#	2004.02.18 start
#	2004.04.10 パッケージSACKBIL追加
#	2004.09.04 パッケージSACKBIL削除
#
#	ぜろちゃんねるプラス
#	2010.08.14 subject.txtの2ch完全互換
#	2011.11.03 設計変更…のつもりだったけど、間に合わせのぶっこわれ対策^^;
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
#	BILBO
#	-------------------------------------------------------------------------------------
#	2004.02.18 start
#
#============================================================================================================
package	BILBO;

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
	my $class = shift;
	
	my $obj = {
		'SUBJECT'	=> undef,
		'RES'		=> undef,
		'SORT'		=> undef,
		'NUM'		=> undef,
		'HANDLE'	=> undef,
	};
	bless $obj, $class;
	
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
	
	my $handle = $this->{'HANDLE'};
	close($handle) if ($handle);
	$this->{'HANDLE'} = undef;
}

#------------------------------------------------------------------------------------------------------------
#
#	オープン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Open
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/subject.txt';
	my $fh = undef;
	
	if ($this->{'HANDLE'}) {
		$fh = $this->{'HANDLE'};
		seek($fh, 0, 0);
	}
	elsif (open($fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		binmode($fh);
		seek($fh, 0, 0);
		$this->{'HANDLE'} = $fh;
	}
	else {
		warn "can't load subject: $path";
	}
	
	return $fh;
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
	
	my $handle = $this->{'HANDLE'};
	close($handle) if ($handle);
	$this->{'HANDLE'} = undef;
	#chmod $Sys->Get('PM-TXT'), $path;
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
	
	$this->{'SUBJECT'} = {};
	$this->{'RES'} = {};
	$this->{'SORT'} = [];
	
	my $fh = $this->Open($Sys) or return;
	my @lines = <$fh>;
	chomp @lines;
	
	my $num = 0;
	foreach (@lines) {
		next if ($_ eq '');
		
		if ($_ =~ /^(.+?)\.dat<>(.*?) ?\(([0-9]+)\)$/) {
			$this->{'SUBJECT'}->{$1} = $2;
			$this->{'RES'}->{$1} = $3;
			push @{$this->{'SORT'}}, $1;
			$num++;
		}
		else {
			warn "invalid line";
			next;
		}
	}
	$this->{'NUM'} = $num;
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
	
	my $fh = $this->Open($Sys) or return;
	
	foreach (@{$this->{'SORT'}}) {
		next if (! defined $this->{'SUBJECT'}->{$_});
		print $fh "$_.dat<>$this->{'SUBJECT'}->{$_} ($this->{'RES'}->{$_})\n";
	}
	
	truncate($fh, tell($fh));
	
	$this->Close();
}

#------------------------------------------------------------------------------------------------------------
#
#	オンデマンド式レス数更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$id	スレッドID
#	@param	$val	レス数
#	@param	$age	ageるなら1
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub OnDemand
{
	my $this = shift;
	my ($Sys, $id, $val, $age) = @_;
	
	$this->{'SUBJECT'} = {};
	$this->{'RES'} = {};
	$this->{'SORT'} = [];
	
	my $fh = $this->Open($Sys) or return;
	my @lines = <$fh>;
	chomp @lines;
	
	my $num = 0;
	foreach (@lines) {
		next if ($_ eq '');
		
		if ($_ =~ /^(.+?)\.dat<>(.*?) ?\(([0-9]+)\)$/) {
			$this->{'SUBJECT'}->{$1} = $2;
			$this->{'RES'}->{$1} = $3;
			push @{$this->{'SORT'}}, $1;
			$num++;
		}
		else {
			warn "invalid line";
			next;
		}
	}
	$this->{'NUM'} = $num;
	
	# レス数更新
	if (exists $this->{'RES'}->{$id}) {
		$this->{'RES'}->{$id} = $val;
	}
	
	if ($age) {
		my $sort = $this->{'SORT'};
		for (my $i = 0; $i <= $#$sort; $i++) {
			if ($id eq $sort->[$i]) {
				splice @$sort, $i, 1;
				unshift @$sort, $id;
				last;
			}
		}
	}
	
	# subject書き込み
	seek($fh, 0, 0);
	
	foreach (@{$this->{'SORT'}}) {
		next if (! defined $this->{'SUBJECT'}->{$_});
		print $fh "$_.dat<>$this->{'SUBJECT'}->{$_} ($this->{'RES'}->{$_})\n";
	}
	
	truncate($fh, tell($fh));
	
	$this->Close();
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
	
	my $n = 0;
	
	if ($kind eq 'ALL') {
		$n += push @$pBuf, @{$this->{'SORT'}};
	}
	else {
		foreach my $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				$n += push @$pBuf, $key;
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
#			$default : デフォルト
#	@return	スレッド情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key, $default) = @_;
	
	my $val = $this->{$kind}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
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
	
	$this->{'SUBJECT'}->{$id} = $subject;
	$this->{'RES'}->{$id} = $res;
	unshift @{$this->{'SORT'}}, $id;
	$this->{'NUM'}++;
	
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
	
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'RES'}->{$id};
	
	my $sort = $this->{'SORT'};
	for (my $i = 0; $i <= $#$sort; $i++) {
		if ($id eq $sort->[$i]) {
			splice @$sort, $i, 1;
			$this->{'NUM'}--;
			last;
		}
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
#	最後のスレッドID取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	スレッドID
#
#------------------------------------------------------------------------------------------------------------
sub GetLastID
{
	my $this = shift;
	
	my $sort = $this->{'SORT'};
	return $sort->[$#$sort];
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
	
	my $sort = $this->{'SORT'};
	for (my $i = 0; $i <= $#$sort; $i++) {
		if ($id eq $sort->[$i]) {
			splice @$sort, $i, 1;
			unshift @$sort, $sort->[$i];
			last;
		}
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
	
	my $sort = $this->{'SORT'};
	for (my $i = 0; $i <= $#$sort; $i++) {
		if ($id eq $sort->[$i]) {
			splice @$sort, $i, 1;
			push @$sort, $sort->[$i];
			last;
		}
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
	
	my $base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/dat';
	
	foreach my $id (@{$this->{'SORT'}}) {
		if (open(my $fh, '<', "$base/$id.dat")) {
			flock($fh, 2);
			my $n = 0;
			$n++ while (<$fh>);
			close($fh);
			$this->{'RES'}->{$id} = $n;
		}
		else {
			warn "can't open file: $base/$id.dat";
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
	
	my $psort = $this->{'SORT'};
	$this->{'SORT'} = [];
	$this->{'SUBJECT'} = {};
	$this->{'RES'} = {};
	my $idhash = {};
	my @dirSet = ();
	
	my $base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/dat';
	my $num	= 0;
	
	# ディレクトリ内一覧を取得
	if (opendir(my $fh, $base)) {
		@dirSet = readdir($fh);
		closedir($fh);
	}
	else {
		warn "can't open dir: $base";
		return;
	}
	
	foreach my $el (@dirSet) {
		if ($el =~ /^(.*)\.dat$/ && open(my $fh, '<', "$base/$el")) {
			flock($fh, 2);
			my $id = $1;
			my $n = 1;
			my $first = <$fh>;
			$n++ while (<$fh>);
			close($fh);
			chomp $first;
			
			my @elem = split(/<>/, $first, -1);
			$this->{'SUBJECT'}->{$id} = $elem[4];
			$this->{'RES'}->{$id} = $n;
			$idhash->{$id} = 1;
			$num++;
		}
	}
	$this->{'NUM'} = $num;
	
	foreach my $id (@$psort) {
		if (defined $idhash->{$id}) {
			push @{$this->{'SORT'}}, $id;
			delete $idhash->{$id};
		}
	}
	foreach my $id (sort keys %$idhash) {
		unshift @{$this->{'SORT'}}, $id;
	}
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
	
	my $sort = $this->{'SORT'};
	for (my $i = 0; $i <= $#$sort; $i++) {
		return $i if ($id eq $sort->[$i]);
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
	my $class = shift;
	
	my $obj = {
		'SUBJECT'	=> {},
		'RES'		=> {},
		'SORT'		=> [],
		'NUM'		=> 0
	};
	bless $obj, $class;
	
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
	
	$this->{'SUBJECT'} = {};
	$this->{'RES'} = {};
	$this->{'SORT'} = [];
	
	my $path = $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/pool/subject.cgi';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		chomp @lines;
		
		my $num = 0;
		for (@lines) {
			next if ($_ eq '');
			
			if ($_ =~ /^(.+?)\.dat<>(.*?) ?\(([0-9]+)\)$/) {
				$this->{'SUBJECT'}->{$1} = $2;
				$this->{'RES'}->{$1} = $3;
				push @{$this->{'SORT'}}, $1;
				$num++;
			}
			else {
				warn "invalid line in $path";
				next;
			}
		}
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
	
	my $path = $Sys->Get('BBSPATH') . '/' .$Sys->Get('BBS') . '/pool/subject.cgi';
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach (@{$this->{'SORT'}}) {
			next if (! defined $this->{'SUBJECT'}->{$_});
			print $fh "$_.dat<>$this->{'SUBJECT'}->{$_} ($this->{'RES'}->{$_})\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	else {
		warn "can't save subject: $path";
	}
	chmod $Sys->Get('PM-TXT'), $path;
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
	
	my $n = 0;
	
	if ($kind eq 'ALL') {
		$n += push @$pBuf, @{$this->{'SORT'}};
	}
	else {
		foreach my $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				$n += push @$pBuf, $key;
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
#			$default : デフォルト
#	@return	スレッド情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key, $default) = @_;
	
	my $val = $this->{$kind}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
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
	
	$this->{'SUBJECT'}->{$id} = $subject;
	$this->{'RES'}->{$id} = $res;
	unshift @{$this->{'SORT'}}, $id;
	$this->{'NUM'}++;
	
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
	
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'RES'}->{$id};
	
	my $sort = $this->{'SORT'};
	for (my $i = 0; $i <= $#$sort; $i++) {
		if ($id eq $sort->[$i]) {
			splice @$sort, $i, 1;
			$this->{'NUM'}--;
			last;
		}
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
	
	foreach my $id (@{$this->{'SORT'}}) {
		if (open(my $fh, '<', "$base/$id.cgi")) {
			flock($fh, 2);
			my $n = 0;
			$n++ while (<$fh>);
			close($fh);
			$this->{'RES'}->{$id} = $n;
		}
		else {
			warn "can't open file: $base/$id.dat";
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
	
	$this->{'SORT'} = [];
	$this->{'SUBJECT'} = {};
	$this->{'RES'} = {};
	my @dirSet = ();
	
	my $base = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/pool';
	my $num = 0;
	
	# ディレクトリ内一覧を取得
	if (opendir(my $fh, $base)) {
		@dirSet = readdir($fh);
		closedir($fh);
	}
	else {
		warn "can't open dir: $base";
		return;
	}
	
	foreach my $el (@dirSet) {
		if ($el =~ /^(.*)\.cgi$/ && open(my $fh, '<', "$base/$el")) {
			flock($fh, 2);
			my $id = $1;
			my $n = 1;
			my $first = <$fh>;
			$n++ while (<$fh>);
			close($fh);
			chomp $first;
			
			my @elem = split(/<>/, $first, -1);
			$this->{'SUBJECT'}->{$id} = $elem[4];
			$this->{'RES'}->{$id} = $n;
			push @{$this->{'SORT'}}, $id;
			$num++;
		}
	}
	$this->{'NUM'} = $num;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

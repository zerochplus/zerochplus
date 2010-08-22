#============================================================================================================
#
#	キャップ管理モジュール
#	ungoliants.pl
#	-------------------------------------------------------------------------------------
#	2004.06.27 start
#	-------------------------------------------------------------------------------------
#	このモジュールはキャップ情報を管理します。
#	以下の3つのパッケージによって構成されます
#
#	UNGOLIANT	: キャップ情報管理
#	SHEROB		: キャップグループ情報管理
#				: セキュリティインタフェイス
#
#============================================================================================================

#============================================================================================================
#
#	キャップ管理パッケージ
#	UNGOLIANT
#	-------------------------------------------------------------------------------------
#	2004.06.27 start
#
#============================================================================================================
package	UNGOLIANT;

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
	my ($obj, %NAME, %PASS, %FULL, %EXPLAN);
	
	$obj = {
		'NAME'	=> \%NAME,
		'PASS'	=> \%PASS,
		'FULL'	=> \%FULL,
		'EXPL'	=> \%EXPLAN,
		'SYSAD'	=> 0
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, @elem);
	
	# ハッシュ初期化
	undef $this->{'NAME'};
	undef $this->{'PASS'};
	undef $this->{'FULL'};
	undef $this->{'EXPL'};
	undef $this->{'SYSAD'};
	
	$path = '.' . $Sys->Get('INFO') . '/caps.cgi';
	
	if (-e $path) {
		open USERS, $path;
		while (<USERS>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'NAME'}->{$elem[0]}		= $elem[1];
			$this->{'PASS'}->{$elem[0]}		= $elem[2];
			$this->{'FULL'}->{$elem[0]}		= $elem[3];
			$this->{'EXPL'}->{$elem[0]}		= $elem[4];
			$this->{'SYSAD'}->{$elem[0]}	= $elem[5];
		}
		close USERS;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ情報保存
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
	
	$path = '.' . $Sys->Get('INFO') . '/caps.cgi';
	
#	eval
	{
		open USERS, "+> $path";
		flock USERS, 2;
		binmode USERS;
		truncate USERS, 0;
		seek USERS, 0, 0;
		foreach (keys %{$this->{'NAME'}}) {
			$data = join('<>',
				$_,
				$this->{NAME}->{$_},
				$this->{PASS}->{$_},
				$this->{FULL}->{$_},
				$this->{EXPL}->{$_},
				$this->{SYSAD}->{$_}
			);
			
			print USERS "$data\n";
		}
		close USERS;
		chmod $Sys->Get('PM-ADM'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	検索種別
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
		foreach $key (keys %{$this->{NAME}}) {
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
#	キャップ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	キャップID
#			$default : デフォルト
#	@return	キャップ情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key, $default) = @_;
	my ($val);
	
	$val = $this->{$kind}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ追加
#	-------------------------------------------------------------------------------------
#	@param	$name	情報種別
#	@param	$pass	キャップID
#	@param	$explan	説明
#	@param	$sysad	管理者フラグ
#	@return	キャップID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $pass, $full, $explan, $sysad) = @_;
	my ($id);
	
	$id = time;
	$this->{'NAME'}->{$id}	= $name;
	$this->{'PASS'}->{$id}	= $this->GetStrictPass($pass, $id);
	$this->{'EXPL'}->{$id}	= $explan;
	$this->{'FULL'}->{$id}	= $full;
	$this->{'SYSAD'}->{$id}	= $sysad;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		キャップID
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
		if ($kind eq 'PASS') {
			$val = $this->GetStrictPass($val, $id);
		}
		$this->{$kind}->{$id} = $val;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除キャップID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'NAME'}->{$id};
	delete $this->{'PASS'}->{$id};
	delete $this->{'FULL'}->{$id};
	delete $this->{'EXPL'}->{$id};
	delete $this->{'SYSAD'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	暗号化パス取得
#	-------------------------------------------------------------------------------------
#	@param	$pass	パスワード
#	@param	$key	パスワード変換キー
#	@return	暗号化されたパスコード
#
#------------------------------------------------------------------------------------------------------------
sub GetStrictPass
{
	my $this = shift;
	my ($pass, $key) = @_;
	
	return substr(crypt($pass, substr(crypt($key, 'ZC'), -2)), -10);
}


#============================================================================================================
#
#	グループ管理パッケージ
#	SHELOB
#	-------------------------------------------------------------------------------------
#	2004.06.27 start
#
#============================================================================================================
package	SHELOB;

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
	my ($obj, %NAME, %EXPLAN, %RANGE, %AUTHOR, %CAPS);
	
	$obj = {
		'NAME'	=> \%NAME,
		'EXPL'	=> \%EXPLAN,
		'AUTH'	=> \%AUTHOR,
		'CAPS'	=> \%CAPS
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, @elem, @auth);
	
	# ハッシュ初期化
	undef $this->{'NAME'};
	undef $this->{'EXPL'};
	undef $this->{'AUTH'};
	undef $this->{'CAPS'};
	
	$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/capgroups.cgi';
	
	if (-e $path) {
		open GROUPS, $path;
		while (<GROUPS>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'NAME'}->{$elem[0]}	= $elem[1];
			$this->{'EXPL'}->{$elem[0]}	= $elem[2];
			$this->{'AUTH'}->{$elem[0]}	= $elem[3];
			$this->{'CAPS'}->{$elem[0]}	= $elem[4];
		}
		close GROUPS;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報保存
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
	
	$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/capgroups.cgi';
	
#	eval
	{
		open GROUPS, "+> $path";
		flock GROUPS, 2;
		binmode GROUPS;
		truncate GROUPS, 0;
		seek GROUPS, 0, 0;
		foreach (keys %{$this->{'NAME'}}) {
			$data = join('<>',
				$_,
				$this->{NAME}->{$_},
				$this->{EXPL}->{$_},
				$this->{AUTH}->{$_},
				$this->{CAPS}->{$_}
			);
			
			print GROUPS "$data\n";
		}
		close GROUPS;
		chmod $Sys->Get('PM-ADM'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	グループIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$pBuf	IDセット格納バッファ
#	@return	グループID数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($pBuf) = @_;
	my ($n);
	
	$n = 0;
	
	foreach (keys %{$this->{NAME}}) {
		push @$pBuf, $_;
		$n++;
	}
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	種別
#	@param	$key	グループID
#			$default : デフォルト
#	@return	グループ名
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key, $default) = @_;
	my ($val);
	
	$val = $this->{$kind}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ追加
#	-------------------------------------------------------------------------------------
#	@param	$name		情報種別
#	@param	$explan		説明
#	@param	$authors	権限セット
#	@param	$caps		キャップセット
#	@return	グループID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $explan, $authors, $caps) = @_;
	my ($id);
	
	$id = time;
	$this->{'NAME'}->{$id}	= $name;
	$this->{'EXPL'}->{$id}	= $explan;
	$this->{'AUTH'}->{$id}	= $authors;
	$this->{'CAPS'}->{$id}	= $caps;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループキャップ追加
#	-------------------------------------------------------------------------------------
#	@param	$id		グループID
#	@param	$user	追加キャップID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub AddCap
{
	my $this = shift;
	my ($id, $cap) = @_;
	my (@users, @match, $nuser);
	
	@users = split(/\,/, $this->{'CAPS'}->{$id});
	@match = grep($cap, @users);
	$nuser = @match;
	
	# 登録済みのキャップは重複登録しない
	if ($nuser == 0) {
		$this->{'CAPS'}->{$id} .= ",$cap";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		グループID
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
#	グループ情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除グループID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'NAME'}->{$id};
	delete $this->{'EXPL'}->{$id};
	delete $this->{'AUTH'}->{$id};
	delete $this->{'CAPS'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	所属キャップグループ取得
#	-------------------------------------------------------------------------------------
#	@param	$id		キャップID
#	@return	キャップが所属しているグループID
#
#------------------------------------------------------------------------------------------------------------
sub GetBelong
{
	my $this = shift;
	my ($id) = @_;
	my (@users, $group, $user);
	
	foreach $group (keys %{$this->{'CAPS'}}) {
		@users = split(/\,/, $this->{'CAPS'}->{$group});
		foreach $user (@users) {
			if ($id eq $user) {
				return $group;
			}
		}
	}
	return '';
}


#============================================================================================================
#
#	セキュリティ管理パッケージ
#	SECURITY
#	-------------------------------------------------------------------------------------
#	2004.02.07 start
#
#============================================================================================================
package SECURITY;

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
	my ($obj);
	
	$obj = {
		'SYS'	=> undef,
		'CAP'	=> undef,
		'GROUP'	=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'SYS'} = $Sys;
	
	# 2重ロード防止
	if (! defined $this->{'CAP'}) {
		$this->{'CAP'} = new UNGOLIANT;
		$this->{'GROUP'} = new SHELOB;
		$this->{'CAP'}->Load($Sys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	情報取得
#	-------------------------------------------------------------------------------------
#	@param	$id		キャップ/グループID
#	@param	$key	取得キー
#	@param	$f		取得種別
#			$default : デフォルト
#	@return	正式なキャップなら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($id, $key, $f, $default) = @_;
	
	if ($f) {
		return $this->{'CAP'}->Get($key, $id, $default);
	}
	else {
		return $this->{'GROUP'}->Get($key, $id, $default);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップID取得
#	-------------------------------------------------------------------------------------
#	@param	$pass	パスワード
#	@return	パスワードに対応するキャップID
#
#------------------------------------------------------------------------------------------------------------
sub GetCapID
{
	my $this = shift;
	my ($pass) = @_;
	my (@capSet, $Cap, $capPass, $id);
	
	$Cap = $this->{'CAP'};
	
	$Cap->GetKeySet('ALL', '', \@capSet);
	foreach $id (@capSet) {
		$capPass = $Cap->GetStrictPass($pass, $id);
		if ($capPass eq $Cap->Get('PASS', $id)) {
			return $id;
		}
	}
	return '';
}

#------------------------------------------------------------------------------------------------------------
#
#	権限判定前グループ情報準備
#	-------------------------------------------------------------------------------------
#	@param	$bbs	適応個所
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetGroupInfo
{
	my $this = shift;
	my ($bbs) = @_;
	my ($oldBBS);
	
	$oldBBS = $this->{'SYS'}->Get('BBS');
	
	$this->{'SYS'}->Set('BBS', $bbs);
	$this->{'GROUP'}->Load($this->{'SYS'});
	$this->{'SYS'}->Set('BBS', $oldBBS);
}

#------------------------------------------------------------------------------------------------------------
#
#	権限判定
#	-------------------------------------------------------------------------------------
#	@param	$id		キャップID
#	@param	$author	権限
#	@param	$bbs	適応個所
#	@return	キャップが権限を持っていたら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub IsAuthority
{
	my $this = shift;
	my ($id, $author, $bbs) = @_;
	my ($sysad, $group, $auth, @authors);
	
	# システム管理権限グループなら無条件OK
	$sysad = $this->{'CAP'}->Get('SYSAD', $id);
	if ($sysad) {
		return 1;
	}
	if ($bbs eq '*') {
		return 0;
	}
	
	# 対象BBSに所属しているか確認
	$group = $this->{'GROUP'}->GetBelong($id);
	if ($group eq '') {
		return 0;
	}
	
	# 権限を持っているか確認
	$auth = $this->{'GROUP'}->Get('AUTH', $group);
	@authors = split(/\,/, $auth);
	foreach $auth (@authors) {
		if ($auth eq $author) {
			return 1;
		}
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

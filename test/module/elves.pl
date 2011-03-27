#============================================================================================================
#
#	管理セキュリティ管理モジュール
#	elves.pl
#	-------------------------------------------------------------------------------------
#	2004.02.07 start
#	-------------------------------------------------------------------------------------
#	このモジュールは管理CGIのセキュリティ情報を管理します。
#	以下の3つのパッケージによって構成されます
#
#	GLORFINDEL	: ユーザ情報管理
#	GILDOR		: グループ情報管理
#	ARWEN		: セキュリティインタフェイス
#
#============================================================================================================

#============================================================================================================
#
#	ユーザ管理パッケージ
#	GLORFINDEL
#	-------------------------------------------------------------------------------------
#	2004.02.07 start
#
#============================================================================================================
package	GLORFINDEL;

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
#	ユーザ情報読み込み
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
	
	$path = '.' . $Sys->Get('INFO') . '/users.cgi';
	
	if (-e $path) {
		open USERS, "< $path";
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
#	ユーザ情報保存
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
	
	$path = '.' . $Sys->Get('INFO') . '/users.cgi';
	
#	eval
	{
		open USERS, "> $path";
		flock USERS, 2;
		binmode USERS;
		#truncate USERS, 0;
		#seek USERS, 0, 0;
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
#	ユーザIDセット取得
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
#	ユーザ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	ユーザID
#			$default : デフォルト
#	@return	ユーザ情報
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
#	ユーザ追加
#	-------------------------------------------------------------------------------------
#	@param	$name	情報種別
#	@param	$pass	ユーザID
#	@param	$explan	説明
#	@param	$sysad	管理者フラグ
#	@return	ユーザID
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
#	ユーザ情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
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
#	ユーザ情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除ユーザID
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
#	GILDOR
#	-------------------------------------------------------------------------------------
#	2004.02.07 start
#
#============================================================================================================
package	GILDOR;

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
	my ($obj, %NAME, %EXPLAN, %RANGE, %AUTHOR, %USERS);
	
	$obj = {
		'NAME'	=> \%NAME,
		'EXPL'	=> \%EXPLAN,
		'AUTH'	=> \%AUTHOR,
		'USERS'	=> \%USERS
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
	undef $this->{'USERS'};
	
	$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/groups.cgi';
	
#	eval
	{
		if (-e $path) {
			open GROUPS, "< $path";
			while (<GROUPS>) {
				chomp $_;
				@elem = split(/<>/, $_);
				$this->{'NAME'}->{$elem[0]}		= $elem[1];
				$this->{'EXPL'}->{$elem[0]}		= $elem[2];
				$this->{'AUTH'}->{$elem[0]}		= $elem[3];
				$this->{'USERS'}->{$elem[0]}	= $elem[4];
			}
			close GROUPS;
		}
	};
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
	
	$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/groups.cgi';
	
#	eval
	{
		open GROUPS, "> $path";
		flock GROUPS, 2;
		binmode GROUPS;
		#truncate GROUPS, 0;
		#seek GROUPS, 0, 0;
		foreach (keys %{$this->{'NAME'}}) {
			$data = join('<>',
				$_,
				$this->{NAME}->{$_},
				$this->{EXPL}->{$_},
				$this->{AUTH}->{$_},
				$this->{USERS}->{$_}
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
#	@param	$users		ユーザセット
#	@return	グループID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $explan, $authors, $users) = @_;
	my ($id);
	
	$id = time;
	$this->{'NAME'}->{$id}	= $name;
	$this->{'EXPL'}->{$id}	= $explan;
	$this->{'AUTH'}->{$id}	= $authors;
	$this->{'USERS'}->{$id}	= $users;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループユーザ追加
#	-------------------------------------------------------------------------------------
#	@param	$id		グループID
#	@param	$user	追加ユーザID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub AddUser
{
	my $this = shift;
	my ($id, $user) = @_;
	my (@users, @match, $nuser);
	
	@users = split(/\,/, $this->{'USERS'}->{$id});
	@match = grep($user, @users);
	$nuser = $#match;
	
	# 登録済みのユーザは重複登録しない
	if ($nuser == 0) {
		$this->{'USERS'}->{$id} .= ",$user";
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
	delete $this->{'USERS'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	所属ユーザグループ取得
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
#	@return	ユーザが所属しているグループID
#
#------------------------------------------------------------------------------------------------------------
sub GetBelong
{
	my $this = shift;
	my ($id) = @_;
	my (@users, $group, $user);
	
	foreach $group (keys %{$this->{'USERS'}}) {
		next if (! defined $this->{'USERS'}->{$group});
		@users = split(/\,/, $this->{'USERS'}->{$group});
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
#	ARWEN
#	-------------------------------------------------------------------------------------
#	2004.02.07 start
#
#============================================================================================================
package ARWEN;

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
		'USER'	=> undef,
		'GROUP'	=> undef,
		'BBS'	=> undef
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
	if (! defined $this->{'USER'}) {
		$this->{'USER'} = new GLORFINDEL;
		$this->{'GROUP'} = new GILDOR;
		$this->{'USER'}->Load($Sys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ログイン判定
#	-------------------------------------------------------------------------------------
#	@param	$name	ユーザ名
#	@param	$pass	パスワード
#	@return	正式なユーザなら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub IsLogin
{
	my $this = shift;
	my ($name, $pass) = @_;
	my (@userSet, $User, $lPass, $id);
	
	$User = $this->{'USER'};
	
	# ユーザ名でユーザIDセットを取得
	$User->GetKeySet('NAME', $name, \@userSet);
	
	# 取得したIDセットからユーザ名とパスワードが同じものを検索
	foreach $id (@userSet) {
		$lPass = $User->Get('PASS', $id);
		$pass = $User->GetStrictPass($pass, $id);
		if ($lPass eq $pass) {
			return $id;
		}
	}
	return 0;
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
	$this->{'BBS'} = $bbs;
	
	$this->{'GROUP'}->Load($this->{'SYS'});
	
	$this->{'SYS'}->Set('BBS', $oldBBS);
}

#------------------------------------------------------------------------------------------------------------
#
#	権限判定
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
#	@param	$author	権限
#	@param	$bbs	適応個所
#	@return	ユーザが権限を持っていたら1を返す
#
#------------------------------------------------------------------------------------------------------------
sub IsAuthority
{
	my $this = shift;
	my ($id, $author, $bbs) = @_;
	my ($sysad, $group, $auth, @authors);
	
	# システム管理権限グループなら無条件OK
	$sysad	= $this->{'USER'}->Get('SYSAD', $id);
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

#------------------------------------------------------------------------------------------------------------
#
#	所属掲示板リスト取得
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
#	@param	$oBBS	NAZGULオブジェクト
#	@param	$pBBS	結果格納用配列の参照
#	@return	所属掲示板数
#
#------------------------------------------------------------------------------------------------------------
sub GetBelongBBSList
{
	my $this = shift;
	my ($id, $oBBS, $pBBS) = @_;
	my (@bbsSet, $bbsDir, $bbsID, $n, $origBBS);
	
	# システム管理ユーザは全てのBBSに所属とする
	if ($this->{'USER'}->Get('SYSAD', $id)) {
		$oBBS->GetKeySet('ALL', '', $pBBS);
		$n = @$pBBS;
	}
	# 一般ユーザは所属グループから判断する
	else {
		$oBBS->GetKeySet('ALL', '', \@bbsSet);
		$origBBS = $this->{'BBS'};
		$n = 0;
		
		foreach $bbsID (@bbsSet) {
			$bbsDir = $oBBS->Get('DIR', $bbsID);
			SetGroupInfo($this, $bbsDir);
			if ($this->{'GROUP'}->GetBelong($id) ne '') {
				push @$pBBS, $bbsID;
				$n++;
			}
		}
		
		# 後処理
		if (defined $origBBS) {
			SetGroupInfo($this, $origBBS);
		}
	}
	return $n;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

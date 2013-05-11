#============================================================================================================
#
#	キャップ管理モジュール
#	-------------------------------------------------------------------------------------
#	このモジュールはキャップ情報を管理します。
#	以下の3つのパッケージによって構成されます
#
#	UNGOLIANT	: キャップ情報管理
#	SHELOB		: キャップグループ情報管理
#	SECURITY	: セキュリティインタフェイス
#
#============================================================================================================

#============================================================================================================
#
#	キャップ管理パッケージ
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
	my $class = shift;
	
	my $obj = {
		'NAME'		=> undef,
		'PASS'		=> undef,
		'FULL'		=> undef,
		'EXPL'		=> undef,
		'SYSAD'		=> undef,
		'CUSTOMID'	=> undef,
	};
	bless $obj, $class;
	
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
	
	# ハッシュ初期化
	$this->{'NAME'} = {};
	$this->{'PASS'} = {};
	$this->{'FULL'} = {};
	$this->{'EXPL'} = {};
	$this->{'SYSAD'} = {};
	$this->{'CUSTOMID'} = {};
	
	my $path = '.' . $Sys->Get('INFO') . '/caps.cgi';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			next if ($_ eq '');
			
			my @elem = split(/<>/, $_, -1);
			if (scalar(@elem) < 6) { # 7
				warn "invalid line in $path";
				next;
			}
			push @elem, '';
			
			my $id = $elem[0];
			$this->{'NAME'}->{$id} = $elem[1];
			$this->{'PASS'}->{$id} = $elem[2];
			$this->{'FULL'}->{$id} = $elem[3];
			$this->{'EXPL'}->{$id} = $elem[4];
			$this->{'SYSAD'}->{$id} = $elem[5];
			$this->{'CUSTOMID'}->{$id} = $elem[6];
		}
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
	
	my $path = '.' . $Sys->Get('INFO') . '/caps.cgi';
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach (keys %{$this->{'NAME'}}) {
			my $data = join('<>',
				$_,
				$this->{'NAME'}->{$_},
				$this->{'PASS'}->{$_},
				$this->{'FULL'}->{$_},
				$this->{'EXPL'}->{$_},
				$this->{'SYSAD'}->{$_},
				$this->{'CUSTOMID'}->{$_},
			);
			
			print $fh "$data\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $path);
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
	
	my $n = 0;
	
	if ($kind eq 'ALL') {
		$n += push @$pBuf, keys %{$this->{'NAME'}};
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
#	キャップ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind		情報種別
#	@param	$key		キャップID
#	@param	$default	デフォルト
#	@return	キャップ情報
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
#	キャップ追加
#	-------------------------------------------------------------------------------------
#	@param	$name	情報種別
#	@param	$pass	キャップID
#	@param	$full	フルネーム
#	@param	$explan	説明
#	@param	$sysad	管理者フラグ
#	@return	キャップID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $pass, $full, $explan, $sysad, $customid) = @_;
	
	my $id = time;
	$this->{'NAME'}->{$id} = $name;
	$this->{'PASS'}->{$id} = $this->GetStrictPass($pass, $id);
	$this->{'EXPL'}->{$id} = $explan;
	$this->{'FULL'}->{$id} = $full;
	$this->{'SYSAD'}->{$id} = $sysad;
	$this->{'CUSTOMID'}->{$id} = $customid;
	
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
	delete $this->{'CUSTOMID'}->{$id};
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
	
	my $hash;
	if (length($pass) >= 9) {
		require Digest::SHA::PurePerl;
		Digest::SHA::PurePerl->import( qw(sha1_base64) );
		$hash = substr(crypt($key, 'ZC'), -2);
		$hash = substr(sha1_base64("ZeroChPlus_${hash}_$pass"), 0, 10);
	}
	else {
		$hash = substr(crypt($pass, substr(crypt($key, 'ZC'), -2)), -10);
	}
	
	return $hash;
}


#============================================================================================================
#
#	グループ管理パッケージ
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
	my $class = shift;
	
	my $obj = {
		'NAME'		=> undef,
		'EXPL'		=> undef,
		'COLOR'		=> undef,
		'AUTH'		=> undef,
		'CAPS'		=> undef,
		'ISCOMMON'	=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$sysgroup	共通グループかどうか
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys, $sysgroup) = @_;
	
	# ハッシュ初期化
	$this->{'NAME'} = {};
	$this->{'EXPL'} = {};
	$this->{'COLOR'} = {};
	$this->{'AUTH'} = {};
	$this->{'CAPS'} = {};
	$this->{'ISCOMMON'} = {};
	
	my $path = '.' . $Sys->Get('INFO') . '/capgroups.cgi';
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			next if ($_ eq '');
			
			my @elem = split(/<>/, $_, -1);
			if (scalar(@elem) < 6) {
				warn "invalid line in $path";
				#next;
			}
			
			my $id = $elem[0];
			$elem[4] = '' if (!defined $elem[4]);
			$elem[5] = '' if (!defined $elem[5]);
			$this->{'NAME'}->{$id} = $elem[1];
			$this->{'EXPL'}->{$id} = $elem[2];
			$this->{'AUTH'}->{$id} = $elem[3];
			$this->{'CAPS'}->{$id} = $elem[4];
			$this->{'COLOR'}->{$id} = $elem[5];
			$this->{'ISCOMMON'}->{$id} = 1;
		}
	}
	
	if (!$sysgroup) {
		$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/capgroups.cgi';
		if (open(my $fh, '<', $path)) {
			flock($fh, 2);
			my @lines = <$fh>;
			close($fh);
			map { s/[\r\n]+\z// } @lines;
			
			foreach (@lines) {
				next if ($_ eq '');
				
				my @elem = split(/<>/, $_, -1);
				if (scalar(@elem) < 6) {
					warn "invalid line in $path";
					#next;
				}
				
				my $id = $elem[0];
				$elem[4] = '' if (!defined $elem[4]);
				$elem[5] = '' if (!defined $elem[5]);
				$this->{'NAME'}->{$id} = $elem[1];
				$this->{'EXPL'}->{$id} = $elem[2];
				$this->{'AUTH'}->{$id} = $elem[3];
				$this->{'CAPS'}->{$id} = $elem[4];
				$this->{'COLOR'}->{$id} = $elem[5];
				$this->{'ISCOMMON'}->{$id} = 0;
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報保存
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$sysgroup	共通グループかどうか
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys, $sysgroup) = @_;
	
	my $commflg = ($sysgroup ? 1 : 0);
	
	my $path;
	if ($commflg) {
		$path = '.' . $Sys->Get('INFO') . '/capgroups.cgi';
	}
	else {
		$path = $Sys->Get('BBSPATH') . '/' .  $Sys->Get('BBS') . '/info/capgroups.cgi';
	}
	
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach (keys %{$this->{'NAME'}}) {
			next if ($this->{'ISCOMMON'}->{$_} ne $commflg);
			
			my $data = join('<>',
				$_,
				$this->{'NAME'}->{$_},
				$this->{'EXPL'}->{$_},
				$this->{'AUTH'}->{$_},
				$this->{'CAPS'}->{$_},
				$this->{'COLOR'}->{$_},
			);
			
			print $fh "$data\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $path);
}

#------------------------------------------------------------------------------------------------------------
#
#	グループIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$pBuf		IDセット格納バッファ
#	@param	$sysgroup	共通グループかどうか
#	@return	グループID数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($pBuf, $sysgroup) = @_;
	
	my $n = 0;
	my $commflg = ($sysgroup ? 1 : 0);
	
	foreach (keys %{$this->{'NAME'}}) {
		next if ($this->{'ISCOMMON'}->{$_} ne $commflg);
		$n += push @$pBuf, $_;
	}
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	グループ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind		種別
#	@param	$key		グループID
#	@param	$default	デフォルト
#	@return	グループ名
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
	my ($name, $explan, $color, $authors, $caps, $sysgroup) = @_;
	
	my $id = time;
	$this->{'NAME'}->{$id}	= $name;
	$this->{'EXPL'}->{$id}	= $explan;
	$this->{'COLOR'}->{$id}	= $color;
	$this->{'AUTH'}->{$id}	= $authors;
	$this->{'CAPS'}->{$id}	= $caps;
	$this->{'ISCOMMON'}->{$id}	= ($sysgroup ? 1 : 0);
	
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
	
	my @users = split(/\,/, $this->{'CAPS'}->{$id});
	my @match = grep($cap, @users);
	my $nuser = scalar(@match);
	
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
	delete $this->{'COLOR'}->{$id};
	delete $this->{'AUTH'}->{$id};
	delete $this->{'CAPS'}->{$id};
	delete $this->{'ISCOMMON'}->{$id};
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
	
	my $ret = '';
	
	foreach my $group (keys %{$this->{'CAPS'}}) {
		my @users = split(/\,/, $this->{'CAPS'}->{$group});
		foreach my $user (@users) {
			if ($id eq $user) {
				$ret = $group;
				# 共通グループを優先
				if ($this->{'ISCOMMON'}->{$group}) {
					return $ret;
				}
			}
		}
	}
	return $ret;
}


#============================================================================================================
#
#	セキュリティ管理パッケージ
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
	my $class = shift;
	
	my $obj = {
		'SYS'	=> undef,
		'CAP'	=> undef,
		'GROUP'	=> undef,
	};
	bless $obj, $class;
	
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
		$this->{'CAP'} = UNGOLIANT->new;
		$this->{'GROUP'} = SHELOB->new;
		$this->{'CAP'}->Load($Sys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	情報取得
#	-------------------------------------------------------------------------------------
#	@param	$id			キャップ/グループID
#	@param	$key		取得キー
#	@param	$f			取得種別
#	@param	$default	デフォルト
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
	
	my $Cap = $this->{'CAP'};
	
	my @capSet = ();
	$Cap->GetKeySet('ALL', '', \@capSet);
	foreach my $id (@capSet) {
		my $capPass = $Cap->GetStrictPass($pass, $id);
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
	
	my $oldBBS = $this->{'SYS'}->Get('BBS');
	
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
	
	# システム管理権限グループなら無条件OK
	my $sysad = $this->{'CAP'}->Get('SYSAD', $id);
	return 1 if ($sysad);
	
	return 0 if ($bbs eq '*');
	
	# 対象BBSに所属しているか確認
	my $group = $this->{'GROUP'}->GetBelong($id);
	return 0 if ($group eq '');
	
	# 権限を持っているか確認
	my $authors = $this->{'GROUP'}->Get('AUTH', $group);
	my @authors = split(/\,/, $authors);
	foreach my $auth (@authors) {
		return 1 if ($auth == $author);
	}
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

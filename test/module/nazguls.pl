#============================================================================================================
#
#	掲示板情報管理モジュール
#	nazguls.pl
#	-------------------------------------------------------------------------------------
#	2004.02.08 start
#	-------------------------------------------------------------------------------------
#	このモジュールは管理CGIの掲示板情報を管理します。
#	以下の2つのパッケージによって構成されます
#
#	NAZGUL	: 掲示板情報管理
#	ANGMAR	: カテゴリ情報管理
#
#============================================================================================================

#============================================================================================================
#
#	掲示板情報管理パッケージ
#	NAZGUL
#	-------------------------------------------------------------------------------------
#	2004.02.08 start
#
#============================================================================================================
package	NAZGUL;

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
	my ($obj, %NAME, %DIR, %SUBJECT, %CATEGORY);
	
	$obj = {
		'NAME'		=> \%NAME,
		'DIR'		=> \%DIR,
		'SUBJECT'	=> \%SUBJECT,
		'CATEGORY'	=> \%CATEGORY
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報読み込み
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
	
	undef $this->{'NAME'};
	undef $this->{'DIR'};
	undef $this->{'SUBJECT'};
	undef $this->{'CATEGORY'};
	
	$path = '.' . $Sys->Get('INFO') . '/bbss.cgi';
	
	if (-e $path) {
		open BBSS, "< $path";
		while (<BBSS>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'NAME'}->{$elem[0]}		= $elem[1];
			$this->{'DIR'}->{$elem[0]}		= $elem[2];
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[3];
			$this->{'CATEGORY'}->{$elem[0]}	= $elem[4];
		}
		close BBSS;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報保存
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
	
	$path = '.' . $Sys->Get('INFO') . '/bbss.cgi';
	
#	eval
	{
		open BBSS, "> $path";
		flock BBSS, 2;
		binmode BBSS;
		#truncate BBSS, 0;
		#seek BBSS, 0, 0;
		foreach (keys %{$this->{'NAME'}}) {
			$data = join('<>',
				$_,
				$this->{NAME}->{$_},
				$this->{DIR}->{$_},
				$this->{SUBJECT}->{$_},
				$this->{CATEGORY}->{$_}
			);
			
			print BBSS "$data\n";
		}
		close BBSS;
		chmod $Sys->Get('PM-ADM'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板IDセット取得
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
		foreach $key (sort keys %{$this->{NAME}}) {
			push @$pBuf, $key;
			$n++;
		}
	}
	else {
		foreach $key (keys %{$this->{$kind}}) {
			if (($this->{$kind}->{$key} eq $name)) {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報取得
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
#	掲示板情報追加
#	-------------------------------------------------------------------------------------
#	@param	$name		掲示板名称
#	@param	$dir		掲示板ディレクトリ
#	@param	$subject	説明
#	@param	$category	掲示板カテゴリ
#	@return	掲示板ID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $dir, $subject, $category) = @_;
	my ($id);
	
	$id = time;
	$this->{'NAME'}->{$id}		= $name;
	$this->{'DIR'}->{$id}		= $dir;
	$this->{'SUBJECT'}->{$id}	= $subject;
	$this->{'CATEGORY'}->{$id}	= $category;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		掲示板ID
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
#	掲示板情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除掲示板ID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'NAME'}->{$id};
	delete $this->{'DIR'}->{$id};
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'CATEGORY'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$skey	掲示板名称のキー
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my $this = shift;
	my ($Sys, $skey) = @_;
	my (@dirs, $dir, $id, $bbsroot, $key, $dat, $f);
	
	# 現在の情報をすべてクリア
	undef %{$this->{'NAME'}};
	undef %{$this->{'DIR'}};
	undef %{$this->{'SUBJECT'}};
	undef %{$this->{'CATEGORY'}};
	
	$bbsroot = $Sys->Get('BBSPATH');
	$skey = 'BBS_TITLE' if ($skey eq '');
	
	opendir DIRS, $bbsroot;							# BBSルート対象
	@dirs = readdir DIRS;
	closedir DIRS;
	
	foreach $dir (@dirs) {							# 掲示板ルート検索
		if (-d "$bbsroot/$dir") {					# ディレクトリ発見
			if (-e "$bbsroot/$dir/SETTING.TXT") {	# SETTING.TXT存在
				$f = 0;
				$id = time;
				# IDの重複回避
				while (exists $this->{'DIR'}->{$id}) {
					$id++;
				}
				$this->{'DIR'}->{$id}		= $dir;
				$this->{'CATEGORY'}->{$id}	= '0000000001';
				open SETTING, "< $bbsroot/$dir/SETTING.TXT";
				
				# SETTING.TXTから必要な情報を取得する
				foreach (<SETTING>) {
					chomp $_;
					($key, $dat) = split(/=/, $_);
					if ($key eq $skey) {
						$this->{'NAME'}->{$id} = $dat;
						$f++;
					}
					elsif ($key eq 'BBS_SUBTITLE') {
						$this->{'SUBJECT'}->{$id} = $dat;
						$f++;
					}
					if ($f == 2) {
						last;
					}
				}
				close SETTING;
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板コンテンツ生成 - CreateContents
#	-------------------------------------------
#	引　数：$M : MELKOR
#			$T : THORIN
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub CreateContents
{
	my $this = shift;
	my ($Sys, $Page) = @_;
	my ($Category, @catSet, $bbsSet, $bbsroot, $name, $dir, $ver, $id, @bbsSet);
	
	# カテゴリ情報を読み込み
	$Category = ANGMAR->new;
	$Category->Load($Sys);
	$Category->GetKeySet(\@catSet);
	
	$bbsroot = $Sys->Get('BBSPATH');
	$ver = $Sys->Get('VERSION');
	
	$Page->Print('<html><!--nobanner--><body><small><center><br>');
	
	# ここらへんに自分の掲示板の名前を入れる
	$Page->Print('<b>0ch BBS<br>');
	$Page->Print("Contents</b><br><br><hr></center><br>\n");
	
	foreach $id (@catSet) {
		undef @bbsSet;
		$name = $Category->Get('NAME', $id);
		$Page->Print("<b>$name</b><br>\n");									# カテゴリ出力
		$this->GetKeySet('CATEGORY', $id, \@bbsSet);
		foreach $id (@bbsSet) {
			$name = $this->{'NAME'}->{$id};
			$dir = $this->{'DIR'}->{$id};
			
			$Page->Print("　<a href=\"./$dir/index.html\" target=MAIN>");	# 掲示板リンク出力
			$Page->Print("$name</a><br>\n");
		}
		$Page->Print('<br>');
	}
	$Page->Print("<hr>$ver</body></html>\n");
	
	$Page->Flush(1, $Sys->Get('PM-TXT'), "$bbsroot/contents.html");
}


#============================================================================================================
#
#	カテゴリ情報管理パッケージ
#	ANGMAR
#	-------------------------------------------------------------------------------------
#	2004.02.08 start
#
#============================================================================================================
package	ANGMAR;

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
	my ($obj, %NAME, %SUBJECT);
	
	$obj = {
		'NAME'		=> \%NAME,
		'SUBJECT'	=> \%SUBJECT,
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ情報読み込み
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
	
	$path = '.' . $Sys->Get('INFO') . '/category.cgi';
	
	if (-e $path) {
		open CATS, "< $path";
		while (<CATS>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'NAME'}->{$elem[0]}		= $elem[1];
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[2];
		}
		close CATS;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ情報保存
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
	
	$path = '.' . $Sys->Get('INFO') . '/category.cgi';
	
#	eval
	{
		open CATS, "> $path";
		flock CATS, 2;
		binmode CATS;
		#truncate CATS, 0;
		#seek CATS, 0, 0;
		foreach (keys %{$this->{'NAME'}}) {
			$data = join('<>',
				$_,
				$this->{NAME}->{$_},
				$this->{SUBJECT}->{$_}
			);
			
			print CATS "$data\n";
		}
		close CATS;
		chmod $Sys->Get('PM-ADM'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$pBuf	IDセット格納バッファ
#	@return	キーセット数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	foreach $key (keys %{$this->{NAME}}) {
		push @$pBuf, $key;
		$n++;
	}
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	カテゴリID
#			$default : デフォルト
#	@return	カテゴリ情報
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
#	カテゴリ情報追加
#	-------------------------------------------------------------------------------------
#	@param	$name		カテゴリ名称
#	@param	$subject	説明
#	@return	カテゴリID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($name, $subject) = @_;
	my ($id);
	
	$id = time;
	$this->{'NAME'}->{$id}		= $name;
	$this->{'SUBJECT'}->{$id}	= $subject;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		カテゴリID
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
#	カテゴリ情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除カテゴリID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'NAME'}->{$id};
	delete $this->{'SUBJECT'}->{$id};
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

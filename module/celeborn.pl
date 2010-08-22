#============================================================================================================
#
#	過去ログ管理モジュール(CELEBORN)
#	celeborn.pl
#	-------------------------------------------------------------------------------------
#	2003.01.22 start
#	2003.03.07 Makeメソッド追加
#	2004.08.24 再構築
#
#============================================================================================================
package	CELEBORN;

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
	my (%KAKO, $PATH, $obj);
	
	$obj = {
		'KEY'		=> undef,
		'SUBJECT'	=> undef,
		'DATE'		=> undef,
		'PATH'		=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログ情報ファイル読み込み
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($SYS) = @_;
	my (@elem, $path);
	
	undef $this->{'KEY'};
	undef $this->{'SUBJECT'};
	undef $this->{'DATE'};
	undef $this->{'PATH'};
	
	$path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
	if (-e $path) {
		open KAKO, "< $path";
		while (<KAKO>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'KEY'}->{$elem[0]}		= $elem[1];
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[2];
			$this->{'DATE'}->{$elem[0]}		= $elem[3];
			$this->{'PATH'}->{$elem[0]}		= $elem[4];
		}
		close KAKO;
		return 0;
	}
	return -1;
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログ情報ファイル書き込み
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($SYS) = @_;
	my ($path, $data);
	
	$path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
#	eval
	{
		open KAKO, "+> $path";
		flock KAKO, 2;
		binmode KAKO;
		truncate KAKO, 0;
		seek KAKO, 0, 0;
		foreach (keys %{$this->{'SUBJECT'}}) {
			$data = join('<>',
				$_,
				$this->{KEY}->{$_},
				$this->{SUBJECT}->{$_},
				$this->{DATE}->{$_},
				$this->{PATH}->{$_}
			);
			
			print KAKO "$data\n";
		}
		close KAKO;
		chmod $SYS->Get('PM-DAT'), $path;
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
	my $this = shift;
	my ($kind, $name, $pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	if ($kind eq 'ALL') {
		foreach $key (keys %{$this->{'KEY'}}) {
			if ($this->{'KEY'}->{$key} ne '0') {
				push @$pBuf, $key;
				$n++;
			}
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
#	情報取得
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
#	追加
#	-------------------------------------------------------------------------------------
#	@param	$key		スレッドキー
#	@param	$subject	スレッドタイトル
#	@param	$date		更新日時
#	@return	ID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($key, $subject, $date, $path) = @_;
	my ($id);
	
	$id = time;
	while (exists $this->{'KEY'}->{$id}) {
		$id++;
	}
	$this->{'KEY'}->{$id}		= $key;
	$this->{'SUBJECT'}->{$id}	= $subject;
	$this->{'DATE'}->{$id}		= $date;
	$this->{'PATH'}->{$id}		= $path;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		ID
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
#	情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除ID
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'KEY'}->{$id};
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'DATE'}->{$id};
	delete $this->{'PATH'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログ情報の更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub UpdateInfo
{
	my $this = shift;
	my ($Sys) = @_;
	my (%Dirs, @dirList, @fileList, @elem);
	my ($dir, $file, $path, $subj);
	
	require './module/earendil.pl';
	
	undef $this->{'KEY'};
	undef $this->{'SUBJECT'};
	undef $this->{'DATE'};
	undef $this->{'PATH'};
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako';
	
	# ディレクトリ情報を取得
	EARENDIL::GetFolderHierarchy($path, \%Dirs);
	EARENDIL::GetFolderList(\%Dirs, \@dirList, '');
	
	foreach $dir (@dirList) {
		EARENDIL::GetFileList("$path/$dir", \@fileList, '(\d+)\.html');
		Add($this, 0, 0, 0, $dir);
		foreach $file (@fileList) {
			@elem = split(/\./, $file);
			$subj = GetThreadSubject("$path/$dir/$file");
			if ($subj ne '') {
				Add($this, $elem[0], $subj, time, $dir);
			}
		}
		undef @fileList;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログindexの更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub UpdateIndex
{
	my $this = shift;
	my ($Sys, $Page) = @_;
	my ($Banner, %PATHES, @subDirs, @info, @dirs);
	my ($basePath, $path, $id, $dir, $key, $subj, $date);
	
	# 告知情報読み込み
	require './module/denethor.pl';
	$Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	$basePath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	# パスをキーにしてハッシュを作成
	foreach $id (keys(%{$this->{'KEY'}})) {
		$path = $this->{'PATH'}->{$id};
		$PATHES{$path} = $id;
	}
	@dirs = keys %PATHES;
	unshift @dirs, '';
	
#	eval
	{
		# パスごとにindexを生成する
		foreach $path (@dirs) {
			# 1階層下のサブフォルダを取得する
			GetSubFolders($path, \@dirs, \@subDirs);
			foreach $dir (sort @subDirs) {
				push @info, "0<>0<>0<>$dir";
			}
			
			# ログデータがあれば情報配列に追加する
			foreach $id (keys(%{$this->{'KEY'}})) {
				if ($path eq $this->{'PATH'}->{$id} && $this->{'KEY'}->{$id} ne '0') {
					$key = $this->{'KEY'}->{$id};
					$subj = $this->{'SUBJECT'}->{$id};
					$date = $this->{'DATE'}->{$id};
					push @info, "$key<>$subj<>$date<>$path";
				}
			}
			
			# indexファイルを出力する
			$Page->Clear();
			OutputIndex($Sys, $Page, $Banner, \@info, $basePath, $path);
			
			undef @info;
			undef @subDirs;
		}
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	サブフォルダを取得する
#	-------------------------------------------------------------------------------------
#	@param	$base	親フォルダパス
#	@param	$pDirs	ディレクトリ名の配列
#	@param	$pList	サブフォルダ格納配列
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetSubFolders
{
	my ($base, $pDirs, $pList) = @_;
	my ($dir, $old);
	
	$base .= '/';
	foreach $dir (@$pDirs) {
		$old = $dir;
		$old =~ s/^$base//;
		if ($old ne $dir && $old !~ /\//) {
			push @$pList, $old;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログタイトルの取得
#	-------------------------------------------------------------------------------------
#	@param	$path	取得するファイルのパス
#	@return	タイトル
#
#------------------------------------------------------------------------------------------------------------
sub GetThreadSubject
{
	my ($path) = @_;
	my ($text);
	
	if (-e $path) {
		open FILE, "< $path";
		foreach $text (<FILE>) {
			if ($text =~ /<title>(.*)<\/title>/) {
				close FILE;
				return $1;
			}
		}
	}
	close FILE;
	return '';
}

#------------------------------------------------------------------------------------------------------------
#
#	過去ログindexを出力する
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Page	THORIN
#	@param	$Banner	DENETHOR
#	@param	$pInfo	出力情報配列
#	@param	$base	掲示板トップパス
#	@param	$path	index出力パス
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub OutputIndex
{
	my ($Sys, $Page, $Banner, $pInfo, $base, $path, $Set) = @_;
	my (@elem, $info, $version);
	my ($Caption, $bbsRoot, $board);
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	$version = $Sys->Get('VERSION');
	$bbsRoot = $Sys->Get('SERVER') . '/' . $Sys->Get('BBS');
	$board = $Sys->Get('BBS');
	
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(<<HTML);
 <title>過去ログ倉庫 - $board$path</title>

</head>
<!--nobanner-->
<body>
HTML
	
	# 告知欄出力
	$Banner->Print($Page, 100, 2, 0);
	
	$Page->Print(<<HTML);

<h1 align="center" style="margin-bottom:0.2em;">過去ログ倉庫</h1>
<h2 align="center" style="margin-top:0.2em;">$board</h2>

<table border="1">
 <tr>
  <th>KEY</th>
  <th>subject</th>
  <th>date</th>
 </tr>
HTML
	
	foreach $info (@$pInfo) {
		@elem = split(/<>/, $info);
		
		# サブフォルダ情報
		if ($elem[0] eq '0') {
			$Page->Print(" <tr>\n  <td>Directory</td>\n  <td><a href=\"$elem[3]/index.html\">");
			$Page->Print("$elem[3]</a></td>\n  <td>-</td>\n </tr>\n");
		}
		# 過去ログ情報
		else {
			$Page->Print(" <tr>\n  <td>$elem[0]</td>\n  <td><a href=\"$elem[0].html\">");
			$Page->Print("$elem[1]</a></td>\n  <td>$elem[2]</td>\n </tr>\n");
		}
	}
	$Page->Print("</table>\n\n<hr>\n");
	$Page->Print(<<HTML);

<a href="$bbsRoot/">■掲示板に戻る■</a> | <a href="$bbsRoot/kako/">■過去ログトップに戻る■</a> | <a href="../">■1つ上に戻る■</a>

<hr>

<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$version
</div>
</body>
</html>
HTML
	
	# index.htmlを出力する
	$Page->Flush(1, 0666, "$base/kako$path/index.html");
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

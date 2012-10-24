#============================================================================================================
#
#	出力管理モジュール
#
#============================================================================================================
package	THORIN;

use strict;
use warnings;

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
	my $class = shift;
	
	my $obj = {
		'BUFF'	=> [],
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	バッファ出力 - Print
#	-------------------------------------------
#	引　数：$line : 出力テキスト
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($line) = @_;
	
	push @{$this->{'BUFF'}}, $line;
}

#------------------------------------------------------------------------------------------------------------
#
#	INPUTタグ出力 - HTMLInput
#	-------------------------------------------
#	引　数：$kind  : タイプ
#			$name  : 名前
#			$value : 値
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub HTMLInput
{
	my $this = shift;
	my ($kind, $name, $value) = @_;
	
	my $line = "<input type=$kind name=\"$name\" value=\"$value\">\n";
	
	push @{$this->{'BUFF'}}, $line;
}

#------------------------------------------------------------------------------------------------------------
#
#	バッファフラッシュ - Flush
#	-------------------------------------------
#	引　数：$flag       : 出力フラグ
#			$perm		: パーミッション
#			$szFilePath : 出力パス
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Flush
{
	my $this = shift;
	my ($flag, $perm, $path) = @_;
	
	# ファイルへ出力
	if ($flag) {
		if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
			flock($fh, 2);
			seek($fh, 0, 0);
			print $fh $_ foreach (@{$this->{'BUFF'}});
			truncate($fh, tell($fh));
			close($fh);
		}
		chmod $perm, $path;
	}
	# 標準出力に出力
	else {
		print $_ foreach (@{$this->{'BUFF'}});
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	バッファクリア - Clear
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	$this->{'BUFF'} = [];
}

#------------------------------------------------------------------------------------------------------------
#
#	マージ - Merge
#	-------------------------------------------
#	引　数：$thorin : THORINモジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Merge
{
	my $this = shift;
	my ($thorin) = @_;
	
	push @{$this->{'BUFF'}}, @{$thorin->{'BUFF'}};
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

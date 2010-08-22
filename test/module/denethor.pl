#============================================================================================================
#
#	バナー管理モジュール(DENETHOR)
#	denethor.pl
#	---------------------------------------
#	2003.01.24 start
#
#============================================================================================================
package	DENETHOR;

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
	my $this = shift;
	my ($obj);
	
	$obj = {
		'TEXTPC'	=> '',	# PC用テキスト
		'TEXTSB'	=> '',	# サブバナーテキスト
		'TEXTMB'	=> '',	# 携帯用テキスト
		'COLPC'		=> '',	# PC用背景色
		'COLMB'		=> ''	# 携帯用背景色
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	モジュールデストラクタ - DESTROY
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub DESTROY
{
}

#------------------------------------------------------------------------------------------------------------
#
#	オブジェクト取得 - Object
#	-------------------------------------------
#	引　数：なし
#	戻り値：オブジェクトの参照
#
#------------------------------------------------------------------------------------------------------------
sub Object
{
	my $this = shift;
	
	return $this->{'BANNER'};
}

#------------------------------------------------------------------------------------------------------------
#
#	バナー情報読み込み - Load
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：成功:0,失敗:-1
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($M) = @_;
	my (@pc, @mb, $path, $f);
	
	$this->{'TEXTPC'}	= '<tr><td>なるほど告知欄じゃねーの</td></tr>';
	$this->{'TEXTMB'}	= '<tr><td>なるほど告知欄じゃねーの</td></tr>';
	$this->{'COLPC'}	= '#ccffcc';
	$this->{'COLMB'}	= '#ccffcc';
	
	$path = '.' . $M->Get('INFO');
	$f = 0;
	
	if (-e "$path/bannerpc.cgi") {	# PC用読み込み
		$this->{'TEXTPC'} = '';
		open BANPC, "< $path/bannerpc.cgi";
		while (<BANPC>) {
			if ($f) {
				$this->{'TEXTPC'} .= $_;
			}
			else {
				chomp $_;
				$this->{'COLPC'} = $_;
				$f = 1;
			}
		}
		close BANPC;
	}
	$f = 0;
	
	if (-e "$path/bannersub.cgi") {	# サブバナー読み込み
		$this->{'TEXTSB'} = '';
		open BANSB, "< $path/bannersub.cgi";
		while (<BANSB>) {
			$this->{'TEXTSB'} .= $_;
		}
		close BANSB;
	}
	
	if (-e "$path/bannermb.cgi") {	# 携帯用読み込み
		$this->{'TEXTMB'} = '';
		open BANMB, "< $path/bannermb.cgi";
		while (<BANMB>) {
			if ($f) {
				$this->{'TEXTMB'} .= $_;
			}
			else {
				chomp $_;
				$this->{'COLMB'} = $_;
				$f = 1;
			}
		}
		close BANMB;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	バナー情報書き込み - Save
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($M) = @_;
	my (@file);
	
	$file[0] = '.' . $M->Get('INFO') . '/bannerpc.cgi';
	$file[1] = '.' . $M->Get('INFO') . '/bannermb.cgi';
	$file[2] = '.' . $M->Get('INFO') . '/bannersub.cgi';
	
	eval { chmod 0666, $file[0]; };	# PC用書き込み
	open BANPC, "> $file[0]";
	binmode BANPC;
	eval { flock BANPC, 2; };
	print BANPC "$$this{'COLPC'}\n";
	print BANPC "$$this{'TEXTPC'}";
	close BANPC;
	eval { chmod $M->Get('PM-ADM'), $file[0]; };
	
	eval { chmod 0666, $file[2]; };	# PC用書き込み
	open BANSB, "> $file[2]";
	binmode BANSB;
	eval { flock BANSB, 2; };
	print BANSB "$$this{'TEXTSB'}";
	close BANSB;
	eval { chmod $M->Get('PM-ADM'), $file[2]; };
	
	eval { chmod 0666, $file[1]; };	# 携帯用書き込み
	open BANMB, "> $file[1]";
	binmode BANMB;
	eval { flock BANMB, 2; };
	print BANMB "$$this{'COLMB'}\n";
	print BANMB "$$this{'TEXTMB'}";
	close BANMB;
	eval { chmod $M->Get('PM-ADM'), $file[1]; };
}

#------------------------------------------------------------------------------------------------------------
#
#	バナー情報設定 - Set
#	-------------------------------------------
#	引　数：$key : 設定キー
#			$val : 設定値
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $val) = @_;
	
	$this->{$key} = $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	バナー情報取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#	戻り値：取得値
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key) = @_;
	
	return $this->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	バナー出力 - Print
#	-------------------------------------------
#	引　数：$T,$M  : モジュール
#			$width : バナー幅(%)
#			$f     : 区切り表示フラグ
#	戻り値：バナー出力したら1,その他は0
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($Page, $width, $f, $mode) = @_;
	
	# 上区切り
	$Page->Print('<hr>') if ($f & 1);
	
	# 携帯用バナー表示
	if ($mode) {
		$Page->Print('<table border width="100%" ');
		$Page->Print("bgcolor=$$this{'COLMB'}>");
		$Page->Print("$$this{'TEXTMB'}</table>\n");
	}
	# PC用バナー表示
	else {
		$Page->Print("<table border=\"1\" cellspacing=\"7\" cellpadding=\"3\" width=\"$width%\"");
		$Page->Print(" bgcolor=\"$$this{'COLPC'}\" align=\"center\">\n");
		$Page->Print("$$this{'TEXTPC'}\n</table>\n");
	}
	
	# 下区切り
	$Page->Print("<hr>\n\n") if ($f & 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	サブバナー出力 - PrintSub
#	-------------------------------------------
#	引　数：$T,$M  : モジュール
#	戻り値：バナー出力したら1,その他は0
#
#------------------------------------------------------------------------------------------------------------
sub PrintSub
{
	my $this = shift;
	my ($Page) = @_;
	
	# サブバナーが存在したら表示する
	if (defined $$this{'TEXTSB'} && $$this{'TEXTSB'} ne '') {
		$Page->Print("<div style=\"margin-bottom:1.2em;\">\n");
		$Page->Print("$$this{'TEXTSB'}\n");
		$Page->Print("</div>\n");
		return 1;
	}
	return 0;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

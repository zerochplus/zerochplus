#============================================================================================================
#
#	ヘッダ・フッタ・META管理モジュール(LEGOLAS)
#	legolas.pl
#	--------------------------------------------------
#	2003.01.24 start
#	2003.02.04 Printを追加
#	2003.03.15 フッタ管理追加
#	2003.03.22 META管理統合
#
#============================================================================================================
package	LEGOLAS;

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
	my (@HEAD, $TEXT, $URL, $PATH, $FILE, $obj);
	
	undef @HEAD;
	$PATH = "";
	$FILE = "";
	
	$obj = {
		'HEAD'	=> \@HEAD,
		'TEXT'	=> $TEXT,
		'URL'	=> $URL,
		'PATH'	=> $PATH,
		'FILE'	=> $FILE
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダ・フッタの読み込み - Load
#	-------------------------------------------
#	引　数：$Sys    : モジュール
#			$kind : 種類
#	戻り値：
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys, $kind) = @_;
	my ($head, $path, $file);
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	if ($kind eq 'HEAD') { $file = 'head.txt'; }
	if ($kind eq 'FOOT') { $file = 'foot.txt'; }
	if ($kind eq 'META') { $file = 'meta.txt'; }
	
	$this->{'TEXT'} = $Sys->Get('HEADTEXT');
	$this->{'URL'} = $Sys->Get('HEADURL');
	$this->{'PATH'} = $path;
	$this->{'FILE'} = $file;
	
	$head = $this->{'HEAD'};
	
	if (-e "$path/$file") {
		open(HEAD, '<', "$path/$file");
		flock(HEAD, 1);
		@$head = <HEAD>;
		close(HEAD);
		return 0;
	}
	
	return -1;
}

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダ・フッタの書き込み - Save
#	-------------------------------------------
#	引　数：$Sys : モジュール
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $file);
	
	$path = $this->{'PATH'};
	$file = $this->{'FILE'};
	
	if ($path) {
		chmod 0666, "$path/$file";
		open(HEAD, '<+', "$path/$file");
		flock(HEAD, 2);
		seek(HEAD, 0, 0);
		print HEAD @{$this->{'HEAD'}};
		truncate(HEAD, tell(HEAD));
		close(HEAD);
		chmod $Sys->Get('PM-TXT'), "$path/$file";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	内容の設定 - Set
#	-------------------------------------------
#	引　数：$head : 設定内容
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($head) = @_;
	my @work;
	
	undef @{$this->{'HEAD'}};
	
	@work = split(/\n/, $$head);
	foreach (@work) {
		push @{$this->{'HEAD'}}, "$_\n";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	内容の取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	内容の参照
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	
	return \@{$this->{'HEAD'}};
}

#------------------------------------------------------------------------------------------------------------
#
#	内容の表示
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Set	ISILDUR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($Page, $Set) = @_;
	my ($bbs, $tcol, $text, $url);
	
	# head.txtの場合はヘッダ全てを表示する
	if ($this->{'FILE'} eq 'head.txt') {
		$bbs = $Set->Get('BBS_SUBTITLE');
		$tcol = $Set->Get('BBS_MENU_COLOR');
		$text = $this->{'TEXT'};
		$url = $this->{'URL'};
	
	$Page->Print(<<HEAD);
<a name="info"></a>
<table border="1" cellspacing="7" cellpadding="3" width="95%" bgcolor="$tcol" style="margin-bottom:1.2em;" align="center">
 <tr>
  <td>
  <table border="0" width="100%">
   <tr>
    <td><font size="+1"><b>$bbs</b></font></td>
    <td align="right"><a href="#menu">■</a> <a href="#1">▼</a></td>
   </tr>
   <tr>
    <td colspan="2">
HEAD
		
		foreach (@{$this->{'HEAD'}}) {
			$Page->Print("    $_");
		}
		
		$Page->Print("    </td>\n");
		$Page->Print("   </tr>\n");
		$Page->Print("  </table>\n");
		$Page->Print("  </td>\n");
		$Page->Print(" </tr>\n");
		
		if ($text ne "") {
			$Page->Print(" <tr>\n");
			$Page->Print("  <td align=\"center\"><a href=\"$url\" target=\"_blank\">$text</a></td>\n");
			$Page->Print(" </tr>\n");
		}
		
		$Page->Print("</table>\n\n");
		#$Page->Print("<br>\n");
	}
	# META.txtはインデント
	elsif ($this->{'FILE'} eq 'meta.txt') {
		foreach (@{$this->{'HEAD'}}) {
			$Page->Print(" $_");
		}
		$Page->Print("\n");
	}
	# その他は内容をそのまま表示
	else {
		foreach (@{$this->{'HEAD'}}) {
			$Page->Print("$_");
		}
	}
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

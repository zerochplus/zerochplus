#============================================================================================================
#
#	管理CGIベースモジュール
#
#============================================================================================================
package	SAURON;

use strict;
use warnings;

require './module/thorin.pl';

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
		'SYS'		=> undef,		# MELKOR保持
		'FORM'		=> undef,		# SAMWISE保持
		'INN'		=> undef,		# THORIN保持
		'MENU'		=> undef,		# 機能リスト
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	オブジェクト生成
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$Form		SAMWISE
#	@return	THORINモジュール
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($Sys, $Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= THORIN->new;
	$this->{'MENU'}		= [];
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューの設定
#	-------------------------------------------------------------------------------------
#	@param	$str	表示文字列
#	@param	$url	ジャンプURL
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my $this = shift;
	my ($str, $url) = @_;
	
	push @{$this->{'MENU'}}, {
		'str'	=> $str,
		'url'	=> $url,
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	ページ出力
#	-------------------------------------------------------------------------------------
#	@param	$title	ページタイトル
#	@param	$mode	
#	@param	$indata	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($title, $mode, $indata) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $CGI = $Sys->Get('ADMIN');
	
	my $Page = THORIN->new;
	$Page->Init('admin.tt');
	$Page->Set({
		'title'		=> $title,
		'datapath'	=> $Sys->Get('DATA'),
		'version'	=> $Sys->Get('VERSION'),
	});
	
	if ($mode) {
		$Page->Set({
			'mode'		=> $mode,
			'menu'		=> $this->{'MENU'},
			'username'	=> $Form->Get('UserName'),
			'sid'		=> $Form->Get('SessionID'),
			'isupdate'	=> $CGI->{'NEWRELEASE'}->Get('Update'),
		});
	}
	
	if (defined $indata) {
		$Page->Set($indata);
	} else {
		warn;
		$this->{'INN'}->Flush(0, 0, \my $inner);
		$Page->Set({'innerhtml' => $inner});
	}
	
	$Page->OutputContentType('text/html');
	$Page->Output;
	
	my ($user, $system, $cuser, $csystem) = times;
	print STDERR "user:$user system:$system cuser:$cuser csystem:$csystem\n";
	
	#foreach my $key (sort keys %INC) {
	#	print STDERR "$key\n" if ($key =~ m/Template/);
	#}
}

#------------------------------------------------------------------------------------------------------------
#
#	完了画面の出力
#	-------------------------------------------------------------------------------------
#	@param	$name	処理名
#	@param	$LogArr	処理ログ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageComplete
{
	my $this = shift;
	my ($name, $LogArr) = @_;
	
	my $indata = {
		'title'		=> 'Process Complete',
		'intmpl'	=> 'complete',
		'pname'		=> $name,
		'log'		=> $LogArr,
	};
	
	return $indata;
}

sub PrintComplete
{
	my $this = shift;
	my ($name, $LogArr) = @_;
	
	my $PageIn = $this->{'INN'};
	
	$PageIn->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="oExcuted">
     $nameを正常に完了しました。
    </div>
   
    <div class="LogExport">処理ログ</div>
    <hr>
    <blockquote class="LogExport">
HTML
	
	# ログの表示
	foreach my $text (@$LogArr) {
		$PageIn->Print("     $text<br>\n");
	}
	
	$PageIn->Print(<<HTML);
    </blockquote>
    <hr>
    </td>
   </tr>
  </table>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	エラーの表示
#	-------------------------------------------------------------------------------------
#	@param	$LogArr	ログ用
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageError
{
	my $this = shift;
	my ($LogArr) = @_;
	
	my %err2mes = (
		0		=> '不明なエラーが発生しました。',
		1000	=> '本機能の処理を実行する権限がありません。',
		1001	=> '入力必須項目が空欄になっています。',
		1002	=> '設定項目に規定外の文字が使用されています。',
		2000	=> '掲示板ディレクトリの作成に失敗しました。'
				 . 'パーミッション、または既に同名の掲示板が作成されていないかを確認してください。',
		2001	=> 'SETTING.TXTの生成に失敗しました。',
		2002	=> '掲示板構成要素の生成に失敗しました。',
		2003	=> '過去ログ初期情報の生成に失敗しました。',
		2004	=> '掲示板情報の更新に失敗しました。',
	);
	
	my $errnum = pop(@$LogArr);
	my $errmes = $err2mes{$errnum};
	$errmes = $err2mes{0} if (!defined $errmes);
	
	my $indata = {
		'title'		=> 'Process Failed',
		'intmpl'	=> 'error',
		'errnum'	=> $errnum,
		'errmes'	=> $errmes,
		'log'		=> $LogArr,
	};
	
	return $indata;
}

sub PrintError
{
	my $this = shift;
	my ($LogArr) = @_;
	
	my $PageIn = $this->{'INN'};
	
	# エラーコードの抽出
	my $ecode = pop @$LogArr;
	
	$PageIn->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="xExcuted">
HTML
	
	if ($ecode == 1000) {
		$PageIn->Print("     ERROR:$ecode - 本機能\の処理を実行する権限がありません。\n");
	}
	elsif ($ecode == 1001) {
		$PageIn->Print("     ERROR:$ecode - 入力必須項目が空欄になっています。\n");
	}
	elsif ($ecode == 1002) {
		$PageIn->Print("     ERROR:$ecode - 設定項目に規定外の文字が使用されています。\n");
	}
	elsif ($ecode == 2000) {
		$PageIn->Print("     ERROR:$ecode - 掲示板ディレクトリの作成に失敗しました。<br>\n");
		$PageIn->Print("     パーミッション、または既に同名の掲示板が作成されていないかを確認してください。\n");
	}
	elsif ($ecode == 2001) {
		$PageIn->Print("     ERROR:$ecode - SETTING.TXTの生成に失敗しました。\n");
	}
	elsif ($ecode == 2002) {
		$PageIn->Print("     ERROR:$ecode - 掲示板構\成要素の生成に失敗しました。\n");
	}
	elsif ($ecode == 2003) {
		$PageIn->Print("     ERROR:$ecode - 過去ログ初期情報の生成に失敗しました。\n");
	}
	elsif ($ecode == 2004) {
		$PageIn->Print("     ERROR:$ecode - 掲示板情報の更新に失敗しました。\n");
	}
	else {
		$PageIn->Print("     ERROR:$ecode - 不明なエラーが発生しました。\n");
	}
	
	$PageIn->Print(<<HTML);
    </div>
    
HTML

	# エラーログがあれば出力する
	if (scalar(@$LogArr)) {
		$PageIn->Print('<hr>');
		$PageIn->Print("    <blockquote>");
		foreach my $text (@$LogArr) {
			$PageIn->Print("    $text<br>\n");
		}
		$PageIn->Print("    </blockquote>");
		$PageIn->Print('<hr>');
	}
	
	$PageIn->Print(<<HTML);
    </td>
   </tr>
  </table>
HTML
	
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

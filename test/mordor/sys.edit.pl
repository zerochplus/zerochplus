#============================================================================================================
#
#	システム管理 - 編集 モジュール
#
#============================================================================================================
package	MODULE;

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
		'LOG'	=> [],
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	# 管理マスタオブジェクトの生成
	require './mordor/sauron.pl';
	my $Base = SAURON->new;
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# PC用告知編集画面
	if ($subMode eq 'BANNER_PC') {
		$indata = PreparePageBannerForPCEdit($Sys, $Form);
	}
	# 携帯用告知編集画面
	elsif ($subMode eq 'BANNER_MOBILE') {
		$indata = PreparePageBannerForMobileEdit($Sys, $Form);
	}
	# サブ告知編集画面
	elsif ($subMode eq 'BANNER_SUB') {
		$indata = PreparePageBannerForSubEdit($Sys, $Form);
	}
	# システム設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('システム編集処理', $this->{'LOG'});
	}
	# システム設定失敗画面
	elsif ($subMode eq 'FALSE') {
		$indata = $Base->PreparePageError($this->{'LOG'});
	}
	
	$Base->Print($Sys->Get('_TITLE'), 1, $indata);
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	my $subMode = $Form->Get('MODE_SUB');
	my $err = 0;
	
	# PC用告知
	if ($subMode eq 'BANNER_PC') {
		$err = FunctionBannerEdit($Sys, $Form, 1, $this->{'LOG'});
	}
	# 携帯用告知
	elsif ($subMode eq 'BANNER_MOBILE') {
		$err = FunctionBannerEdit($Sys, $Form, 2, $this->{'LOG'});
	}
	# サブバナー
	elsif ($subMode eq 'BANNER_SUB') {
		$err = FunctionBannerEdit($Sys, $Form, 3, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_EDIT($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_EDIT($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	$Base->SetMenu('告知編集(PC用)', "'sys.edit','DISP','BANNER_PC'");
	$Base->SetMenu('告知編集(携帯用)', "'sys.edit','DISP','BANNER_MOBILE'");
	$Base->SetMenu('告知編集(サブ)', "'sys.edit','DISP','BANNER_SUB'");
}

#------------------------------------------------------------------------------------------------------------
#
#	告知欄(PC)編集画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForPCEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $bgColor;
	my $content;
	
	# 告知欄プレビュー表示
	if ($Form->IsExist('PC_CONTENT')) {
		$Banner->Set('COLPC', $Form->Get('PC_BGCOLOR'));
		$Banner->Set('TEXTPC', $Form->Get('PC_CONTENT'));
		$bgColor = $Form->Get('PC_BGCOLOR');
		$content = $Form->Get('PC_CONTENT');
	}
	else {
		$bgColor = $Banner->Get('COLPC');
		$content = $Banner->Get('TEXTPC');
	}
	
	# プレビューデータの作成
	my $bdata = $Banner->Prepare(100, 0, 0);
	
	my $indata = {
		'title'		=> 'PC Banner Edit',
		'intmpl'	=> 'sys.edit.bannerpc',
		'banner'	=> $bdata,
		'bgcolor'	=> $bgColor,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	告知欄(携帯)編集画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForMobileEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $bgColor;
	my $content;
	
	# 告知欄プレビュー表示
	if ($Form->IsExist('MOBILE_CONTENT')) {
		$Banner->Set('COLMB', $Form->Get('MOBILE_BGCOLOR'));
		$Banner->Set('TEXTMB', $Form->Get('MOBILE_CONTENT'));
		$bgColor = $Form->Get('MOBILE_BGCOLOR');
		$content = $Form->Get('MOBILE_CONTENT');
	}
	else {
		$bgColor = $Banner->Get('COLMB');
		$content = $Banner->Get('TEXTMB');
	}
	
	# プレビューデータの作成
	my $bdata = $Banner->Prepare(100, 0, 1);
	
	my $indata = {
		'title'		=> 'Mobile Banner Edit',
		'intmpl'	=> 'sys.edit.bannermb',
		'banner'	=> $bdata,
		'bgcolor'	=> $bgColor,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	告知欄(サブ)編集画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBannerForSubEdit
{
	my ($Sys, $Form) = @_;
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $content;
	
	# 告知欄プレビュー表示
	if ($Form->IsExist('SUB_CONTENT')) {
		$Banner->Set('TEXTSB', $Form->Get('SUB_CONTENT'));
		$content = $Form->Get('SUB_CONTENT');
	}
	else {
		$content = $Banner->Get('TEXTSB');
	}
	
	# プレビューデータの作成
	my $bdata = $Banner->PrepareSub();
	
	my $indata = {
		'title'		=> 'Sub Banner Edit',
		'intmpl'	=> 'sys.edit.bannersub',
		'banner'	=> $bdata,
		'content'	=> $content,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	告知欄編集
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBannerEdit
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# 入力チェック
	if ($mode == 1) {
		return 1001 if (!$Form->IsInput([qw(PC_CONTENT PC_BGCOLOR)]));
	} elsif ($mode == 2) {
		return 1001 if (!$Form->IsInput([qw(MOBILE_CONTENT MOBILE_BGCOLOR)]));
	}
	
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	if ($mode == 1) {
		$Banner->Set('TEXTPC', $Form->Get('PC_CONTENT'));
		$Banner->Set('COLPC', $Form->Get('PC_BGCOLOR'));
		push @$pLog, 'PC用告知欄を設定しました。';
	}
	elsif ($mode == 2) {
		$Banner->Set('TEXTMB', $Form->Get('MOBILE_CONTENT'));
		$Banner->Set('COLMB', $Form->Get('MOBILE_BGCOLOR'));
		push @$pLog, '携帯用告知欄を設定しました。';
	}
	elsif ($mode == 3) {
		$Banner->Set('TEXTSB', $Form->Get('SUB_CONTENT'));
		push @$pLog, 'サブバナーを設定しました。';
	}
	
	# 設定の保存
	$Banner->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

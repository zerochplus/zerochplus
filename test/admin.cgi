#!/usr/bin/perl
#============================================================================================================
#
#	システム管理CGI
#	admin.cgi
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================

use strict;
use warnings;
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
no warnings 'once';

BEGIN { use lib './perllib'; }

# CGIの実行結果を終了コードとする
exit(AdminCGI());

#------------------------------------------------------------------------------------------------------------
#
#	admin.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub AdminCGI
{
	my ($Sys, $Form, %SYS);
	my ($oModule, $modName, $userID, $name, $pass);
	
	# システム初期設定
	SystemSetting(\%SYS);
	
	# 0chシステム情報を取得
	require "./module/melkor.pl";
	$Sys = new MELKOR;
	$Sys->Init();
	$Sys->Set('ADMIN', \%SYS);
	$SYS{'SECINFO'}->Init($Sys);
	
	$Sys->Set('BBS', '');
	
	# フォーム情報を取得
	require "./module/samwise.pl";
	$Form = SAMWISE->new(0);
	$Form->DecodeForm(0);
	$Form->Set('FALSE', 0);
	
	$name = $Form->Get('UserName', '');
	$pass = $Form->Get('PassWord', '');
	
	# ログインユーザ設定
	$userID = $SYS{'SECINFO'}->IsLogin($name, $pass);
	$SYS{'USER'} = $userID;
	
	# 処理モジュール名を取得
	$modName = $Form->Get('MODULE', 'login');
	$modName = 'login' if (! $userID);
	
	# バージョンチェック
	$upcheck = $Sys->Get('UPCHECK', 1) - 0;
	$SYS{'NEWRELEASE'}->Init($Sys);
	if ($upcheck) {
		$SYS{'NEWRELEASE'}->Set('Interval', 24*60*60*$upcheck);
		$SYS{'NEWRELEASE'}->Check;
	}
	
	# 処理モジュールオブジェクトの生成
	require "./mordor/$modName.pl";
	$oModule = new MODULE;
	
	# 表示モード
	if ($Form->Get('MODE', '') eq 'DISP') {
		$oModule->DoPrint($Sys, $Form, \%SYS);
	}
	# 機能モード
	elsif ($Form->Get('MODE', '') eq 'FUNC') {
		$oModule->DoFunction($Sys, $Form, \%SYS);
	}
	# ログイン
	else {
		$oModule->DoPrint($Sys, $Form, \%SYS);
	}
	$SYS{'LOGGER'}->Write();
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	管理システム設定
#	-------------------------------------------------------------------------------------
#	@param	$pSYS	システム管理ハッシュの参照
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SystemSetting
{
	my ($pSYS) = @_;
	
	%$pSYS = (
		'SECINFO'	=> undef,		# セキュリティ情報
		'LOGGER'	=> undef,		# ログオブジェクト
		'AD_BBS'	=> undef,		# BBS情報オブジェクト
		'AD_DAT'	=> undef,		# dat情報オブジェクト
		'USER'		=> undef,		# ログインユーザID
		'NEWRELEASE'=> undef,		# バージョンチェック
	);
	
	require './module/elves.pl';
	require './module/imrahil.pl';
	require './module/newrelease.pl';
	
	$pSYS->{'SECINFO'}	= new ARWEN;
	$pSYS->{'LOGGER'}	= new IMRAHIL;
	$pSYS->{'LOGGER'}->Open('./info/AdminLog', 100, 2 | 4);
	$pSYS->{'NEWRELEASE'} = ZP_NEWRELEASE->new;
}


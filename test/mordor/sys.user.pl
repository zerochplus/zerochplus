#============================================================================================================
#
#	システム管理 - ユーザ モジュール
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
	
	# スレッド一覧画面
	if ($subMode eq 'LIST') {
		$indata = PreparePageUserList($Sys, $Form);
	}
	# ユーザ作成画面
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageUserSetting($Sys, $Form, 0);
	}
	# ユーザ編集画面
	elsif ($subMode eq 'EDIT') {
		$indata = PreparePageUserSetting($Sys, $Form, 1);
	}
	# ユーザ削除確認画面
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageUserDelete($Sys, $Form);
	}
	# ユーザ設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('ユーザー処理', $this->{'LOG'});
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
	
	# ユーザ作成
	if ($subMode eq 'CREATE') {
		$err = FuncUserSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# ユーザ編集
	elsif ($subMode eq 'EDIT') {
		$err = FuncUserSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# ユーザ削除
	elsif ($subMode eq 'DELETE') {
		$err = FuncUserDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "USER($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"USER($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	メニューリスト設定
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	# 共通表示メニュー
	$Base->SetMenu('ユーザー一覧', "'sys.user','DISP','LIST'");
	
	# システム管理権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('ユーザー登録', "'sys.user','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# ユーザ情報の読み込み
	require './module/elves.pl';
	my @userSet = ();
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# 表示数の設定
	my $listnum = scalar(@userSet);
	my $dispnum = int($Form->Get('DISPNUM', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	# 通知一覧を出力
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $userSet[$nextnum++];
		
		push @$displist, {
			'id'	=> $id,
			'name'	=> $User->Get('NAME', $id),
			'full'	=> $User->Get('FULL', $id),
			'expl'	=> $User->Get('EXPL', $id),
		};
		last if (scalar(@$displist) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Users List',
		'intmpl'	=> 'sys.user.userlist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'users'		=> $displist,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ設定の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	作成の場合:0, 編集の場合:1
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# ユーザ情報の読み込み
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	my $user = {
		'name'	=> '',
		'pass'	=> '',
		'expl'	=> '',
		'full'	=> '',
		'sysad'	=> 0,
	};
	
	my $seluser = '';
	
	# 編集モードならユーザ情報を取得する
	if ($mode) {
		$seluser = $Form->Get('SELECT_USER');
		$user->{'name'} = $User->Get('NAME', $seluser);
		$user->{'pass'} = $User->Get('PASS', $seluser);
		$user->{'expl'} = $User->Get('EXPL', $seluser);
		$user->{'full'} = $User->Get('FULL', $seluser);
		$user->{'sysad'} = $User->Get('SYSAD', $seluser);
	}
	
	my $indata = {
		'title'		=> 'Users '.($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.user.useredit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'seluser'	=> $seluser,
		'user'		=> $user,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ削除確認画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageUserDelete
{
	my ($Sys, $Form) = @_;
	
	# ユーザ情報の読み込み
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# 通知一覧を出力
	my $users = [];
	my @userSet = $Form->GetAtArray('USERS');
	foreach my $id (@userSet) {
		next if (!defined $User->Get('NAME', $id));
		push @$users, {
			'id'	=> $id,
			'name'	=> $User->Get('NAME', $id),
			'full'	=> $User->Get('FULL', $id),
			'expl'	=> $User->Get('EXPL', $id),
		};
	}
	
	my $indata = {
		'title'		=> 'User Delete Confirm',
		'intmpl'	=> 'sys.user.userdelete',
		'users'		=> $users,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ作成/編集
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	編集:1, 作成:0
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FuncUserSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# 入力チェック
	return 1001 if (!$Form->IsInput([qw(NAME PASS)]));
	return 1002 if (!$Form->IsAlphabet([qw(NAME PASS)]));
	
	# ユーザ情報の読み込み
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# 設定入力情報を取得
	my $name = $Form->Get('NAME');
	my $pass = $Form->Get('PASS');
	my $expl = $Form->Get('EXPL');
	my $full = $Form->Get('FULL');
	my $sysad = $Form->Equal('SYSAD', 'on') ? 1 : 0;
	my $chg	= 0;
	
	# 編集モード
	if ($mode) {
		my $id = $Form->Get('SELECT_USER');
		# パスワードが変更されていたら再設定する
		if ($pass ne $User->Get('PASS', $id)) {
			$User->Set($id, 'PASS', $pass);
			$chg = 1;
		}
		$User->Set($id, 'NAME', $name);
		$User->Set($id, 'EXPL', $expl);
		$User->Set($id, 'FULL', $full);
		$User->Set($id, 'SYSAD', $sysad);
	}
	# 登録モード
	else {
		$User->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# 設定情報を保存
	$User->Save($Sys);
	
	# ログの設定
	push @$pLog, "■ ユーザ [ $name ] " . ($mode ? '設定' : '作成');
	push @$pLog, '　　　　パスワード：' . ($chg ? '********' : '変更なし');
	push @$pLog, "　　　　フルネーム：$full";
	push @$pLog, "　　　　説明：$expl";
	push @$pLog, '　　　　システム管理：' . ($sysad ? '有り' : '無し');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FuncUserDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ユーザ情報の読み込み
	require './module/elves.pl';
	my $User = GLORFINDEL->new;
	$User->Load($Sys);
	
	# 選択ユーザを全削除
	my @userSet = $Form->GetAtArray('USERS');
	foreach my $id (@userSet) {
		my $name = $User->Get('NAME', $id);
		next if (!defined $name);
		
		# Administratorは削除不可
		if ($id eq '0000000001') {
			push @$pLog, "□ ユーザ [ $name ] は削除できませんでした。";
		}
		# 自分自身も削除不可
		elsif ($id eq $cuser) {
			push @$pLog, "□ ユーザ [ $name ] は自分自身のため削除できませんでした。";
		}
		# それ以外は削除可
		else {
			push @$pLog, "■ ユーザ [ $name ] を削除しました。";
			$User->Delete($id);
		}
	}
	
	# 設定情報を保存
	$User->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

#============================================================================================================
#
#	システム管理 - キャップ モジュール
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
		$indata = PreparePageCapList($Sys, $Form);
	}
	# キャップ作成画面
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageCapSetting($Sys, $Form, 0);
	}
	# キャップ編集画面
	elsif ($subMode eq 'EDIT') {
		$indata = PreparePageCapSetting($Sys, $Form, 1);
	}
	# キャップ削除確認画面
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageCapDelete($Sys, $Form);
	}
	# キャップ設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('キャップ処理', $this->{'LOG'});
	}
	# キャップ設定失敗画面
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
	
	# キャップ作成
	if ($subMode eq 'CREATE') {
		$err = FuncCapSetting($Sys, $Form, 0, $this->{'LOG'});
	}
	# キャップ編集
	elsif ($subMode eq 'EDIT') {
		$err = FuncCapSetting($Sys, $Form, 1, $this->{'LOG'});
	}
	# キャップ削除
	elsif ($subMode eq 'DELETE') {
		$err = FuncCapDelete($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"CAP($subMode)", 'COMPLETE');
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
	$Base->SetMenu('キャップ一覧', "'sys.cap','DISP','LIST'");
	
	# システム管理権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('キャップ登録', "'sys.cap','DISP','CREATE'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapList
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $cuser = $CGI->{'USER'};
	
	my $issysad = $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*');
	
	# キャップ情報の読み込み
	require './module/ungoliants.pl';
	my @capSet;
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	$Cap->GetKeySet('ALL', '', \@capSet);
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# 表示数の設定
	my $listnum = scalar(@capSet);
	my $dispnum = int($Form->Get('DISPNUM', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	# キャップ一覧を出力
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $capSet[$nextnum++];
		
		push @$displist, {
			'id'	=> $id,
			'name'	=> $Cap->Get('NAME', $id),
			'full'	=> $Cap->Get('FULL', $id),
			'expl'	=> $Cap->Get('EXPL', $id),
		};
		last if (scalar(@$displist) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Caps List',
		'intmpl'	=> 'sys.cap.caplist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'caps'		=> $displist,
		'issysad'	=> $issysad,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ設定の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	作成の場合:0, 編集の場合:1
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapSetting
{
	my ($Sys, $Form, $mode) = @_;
	
	# キャップ情報の読み込み
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	my $cap = {
		'name'	=> '',
		'pass'	=> '',
		'expl'	=> '',
		'full'	=> '',
		'sysad'	=> 0,
	};
	
	my $selcap = '';
	
	# 編集モードならキャップ情報を取得する
	if ($mode) {
		$selcap = $Form->Get('SELECT_CAP');
		$cap->{'name'} = $Cap->Get('NAME', $selcap);
		$cap->{'pass'} = $Cap->Get('PASS', $selcap);
		$cap->{'expl'} = $Cap->Get('EXPL', $selcap);
		$cap->{'full'} = $Cap->Get('FULL', $selcap);
		$cap->{'sysad'} = $Cap->Get('SYSAD', $selcap);
	}
	
	my $indata = {
		'title'		=> 'Cap ' . ($mode ? 'Edit' : 'Create'),
		'intmpl'	=> 'sys.cap.capedit',
		'modesub'	=> $Form->Get('MODE_SUB'),
		'selcap'	=> $selcap,
		'cap'		=> $cap,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ削除確認画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCapDelete
{
	my ($Sys, $Form) = @_;
	
	# キャップ情報の読み込み
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# 通知一覧を出力
	my $caps = [];
	my @capSet = $Form->GetAtArray('CAPS');
	foreach my $id (@capSet) {
		next if (!defined $Cap->Get('NAME', $id));
		push @$caps, {
			'id'	=> $id,
			'name'	=> $Cap->Get('NAME', $id),
			'full'	=> $Cap->Get('FULL', $id),
			'expl'	=> $Cap->Get('EXPL', $id),
		};
	}
	
	my $indata = {
		'title'		=> 'Cap Delete Confirm',
		'intmpl'	=> 'sys.cap.capdelete',
		'caps'		=> $caps,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ作成/編集
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$mode	編集:1, 作成:0
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FuncCapSetting
{
	my ($Sys, $Form, $mode, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# 入力チェック
	return 1001 if (!$Form->IsInput([qw(PASS)]));
	return 1002 if (!$Form->IsCapKey([qw(PASS)]));
	
	# キャップ情報の読み込み
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# 設定入力情報を取得
	my $name = $Form->Get('NAME');
	my $pass = $Form->Get('PASS');
	my $expl = $Form->Get('EXPL');
	my $full = $Form->Get('FULL');
	my $sysad = $Form->Equal('SYSAD', 'on') ? 1 : 0;
	my $chg	= 0;
	
	# 編集モード
	if ($mode) {
		my $id = $Form->Get('SELECT_CAP');
		# パスワードが変更されていたら再設定する
		if ($pass ne $Cap->Get('PASS', $id)){
			$Cap->Set($id, 'PASS', $pass);
			$chg = 1;
		}
		$Cap->Set($id, 'NAME', $name);
		$Cap->Set($id, 'EXPL', $expl);
		$Cap->Set($id, 'FULL', $full);
		$Cap->Set($id, 'SYSAD', $sysad);
	}
	# 登録モード
	else {
		$Cap->Add($name, $pass, $full, $expl, $sysad);
		$chg = 1;
	}
	
	# 設定情報を保存
	$Cap->Save($Sys);
	
	# ログの設定
	push @$pLog, "■ キャップ [ $name ] " . ($mode ? '設定' : '作成');
	push @$pLog, '　　　　パスワード：' . ($chg ? '********' : '変更なし');
	push @$pLog, "　　　　フルネーム：$full";
	push @$pLog, "　　　　説明：$expl";
	push @$pLog, '　　　　システム管理：' . ($sysad ? '有り' : '無し');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	キャップ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FuncCapDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# キャップ情報の読み込み
	require './module/ungoliants.pl';
	my $Cap = UNGOLIANT->new;
	$Cap->Load($Sys);
	
	# 選択キャップを全削除
	my @capSet = $Form->GetAtArray('CAPS');
	foreach my $id (@capSet) {
		my $name = $Cap->Get('NAME', $id);
		next if (!defined $name);
		
		my $pass = $Cap->Get('PASS', $id);
		push @$pLog, "■ キャップ [ $name ] を削除しました。";
		$Cap->Delete($id);
	}
	
	# 設定情報を保存
	$Cap->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

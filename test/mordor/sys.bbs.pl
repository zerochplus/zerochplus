#============================================================================================================
#
#	システム管理 - 掲示板 モジュール
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
	
	# 掲示板一覧画面
	if ($subMode eq 'LIST') {
		$indata = PreparePageBBSList($Sys, $Form);
	}
	# 掲示板作成画面
	elsif ($subMode eq 'CREATE') {
		$indata = PreparePageBBSCreate($Sys, $Form);
	}
	# 掲示板削除確認画面
	elsif ($subMode eq 'DELETE') {
		$indata = PreparePageBBSDelete($Sys, $Form);
	}
	# 掲示板カテゴリ変更画面
	elsif ($subMode eq 'CATCHANGE') {
		$indata = PreparePageBBScategoryChange($Sys, $Form);
	}
	# カテゴリ一覧画面
	elsif ($subMode eq 'CATEGORY') {
		$indata = PreparePageCategoryList($Sys, $Form);
	}
	# カテゴリ追加画面
	elsif ($subMode eq 'CATEGORYADD') {
		$indata = PreparePageCategoryAdd($Sys, $Form);
	}
	# カテゴリ削除画面
	elsif ($subMode eq 'CATEGORYDEL') {
		$indata = PreparePageCategoryDelete($Sys, $Form);
	}
	# 処理完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('掲示板処理', $this->{'LOG'});
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
	
	# 掲示板作成
	if ($subMode eq 'CREATE') {
		$err = FunctionBBSCreate($Sys, $Form, $this->{'LOG'});
	}
	# 掲示板削除
	elsif ($subMode eq 'DELETE') {
		$err = FunctionBBSDelete($Sys, $Form, $this->{'LOG'});
	}
	# カテゴリ変更
	elsif ($subMode eq 'CATCHANGE') {
		$err = FunctionCategoryChange($Sys, $Form, $this->{'LOG'});
	}
	# カテゴリ追加
	elsif ($subMode eq 'CATADD') {
		$err = FunctionCategoryAdd($Sys, $Form, $this->{'LOG'});
	}
	# カテゴリ削除
	elsif ($subMode eq 'CATDEL') {
		$err = FunctionCategoryDelete($Sys, $Form, $this->{'LOG'});
	}
	# 掲示板情報更新
	elsif ($subMode eq 'UPDATE') {
		$err = FunctionBBSInfoUpdate($Sys, $Form, $this->{'LOG'});
	}
	# 掲示板更新
	elsif ($subMode eq 'UPDATEBBS') {
		$err = FunctionBBSUpdate($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "BBS($subMode)", 'COMPLETE');
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
	
	$Base->SetMenu('掲示板一覧', "'sys.bbs','DISP','LIST'");
	
	# システム管理権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('掲示板作成', "'sys.bbs','DISP','CREATE'");
		$Base->SetMenu('', '');
		$Base->SetMenu('掲示板カテゴリ一覧', "'sys.bbs','DISP','CATEGORY'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSList
{
	my ($Sys, $Form) = @_;
	
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# カテゴリリストを出力
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	# ユーザ所属のBBS一覧を取得
	my @belongBoard = ();
	$Sec->GetBelongBBSList($cuser, $Boards, \@belongBoard);
	
	# 掲示板情報を取得
	my @bbsSet = ();
	my $scat = $Form->Get('BBS_CATEGORY', '');
	my $subtitle = '';
	if ($scat eq '' || $scat eq 'ALL') {
		$Boards->GetKeySet('ALL', '', \@bbsSet);
	}
	else {
		$Boards->GetKeySet('CATEGORY', $scat, \@bbsSet);
		$subtitle = $Category->Get('NAME',$scat);
	}
	
	# 掲示板リストを出力
	my $boards = [];
	foreach my $id (sort @bbsSet) {
		# 所属掲示板のみ表示
		foreach (@belongBoard) {
			next if ($id ne $_);
			push @$boards, {
				'id'		=> $id,
				'name'		=> $Boards->Get('NAME', $id),
				'subject'	=> $Boards->Get('SUBJECT', $id),
				'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
			};
			last;
		}
	}
	
	my $indata = {
		'title'			=> 'BBS List' . ($subtitle ? " - $subtitle" : ''),
		'intmpl'		=> 'sys.bbs.bbslist',
		'scategory'		=> $scat,
		'categories'	=> $categories,
		'boards'		=> $boards,
		'issysad'		=> $Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板作成画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSCreate
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# カテゴリリストを出力
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	# 掲示板リストを出力
	my $boards = [];
	my @bbsSet = ();
	$Boards->GetKeySet('ALL', '', \@bbsSet);
	foreach my $id (sort @bbsSet) {
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'BBS Create',
		'intmpl'		=> 'sys.bbs.bbscreate',
		'categories'	=> $categories,
		'boards'		=> $boards,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板削除確認画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBSDelete
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# 掲示板リストを出力
	my $boards = [];
	my @bbsSet = $Form->GetAtArray('BBSS');
	foreach my $id (sort @bbsSet) {
		next if (!defined $Boards->Get('NAME', $id));
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
			'subject'	=> $Boards->Get('SUBJECT', $id),
			'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
		};
	}
	
	my $indata = {
		'title'			=> 'BBS Delete Confirm',
		'intmpl'		=> 'sys.bbs.bbsdelete',
		'boards'		=> $boards,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板カテゴリ変更画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBBScategoryChange
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# 掲示板リストを出力
	my $boards = [];
	my @bbsSet = $Form->GetAtArray('BBSS');
	foreach my $id (sort @bbsSet) {
		next if (!defined $Boards->Get('NAME', $id));
		push @$boards, {
			'id'		=> $id,
			'name'		=> $Boards->Get('NAME', $id),
			'subject'	=> $Boards->Get('SUBJECT', $id),
			'category'	=> $Category->Get('NAME', $Boards->Get('CATEGORY', $id)),
		};
	}
	
	# カテゴリリストを出力
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		push @$categories, {
			'id'	=> $id,
			'name'	=> $Category->Get('NAME', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'Category Change',
		'intmpl'		=> 'sys.bbs.catchange',
		'boards'		=> $boards,
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ一覧画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryList
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	# カテゴリリストを出力
	my $categories = [];
	my @catSet = ();
	$Category->GetKeySet(\@catSet);
	foreach my $id (sort @catSet) {
		my @bbsSet = ();
		$Boards->GetKeySet('CATEGORY', $id, \@bbsSet);
		push @$categories, {
			'id'		=> $id,
			'name'		=> $Category->Get('NAME', $id),
			'subject'	=> $Category->Get('SUBJECT', $id),
			'num'		=> scalar(@bbsSet),
		};
	}
	
	my $indata = {
		'title'			=> 'Category List',
		'intmpl'		=> 'sys.bbs.catlist',
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ追加画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryAdd
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'			=> 'Category Add',
		'intmpl'		=> 'sys.bbs.catadd',
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリ削除画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageCategoryDelete
{
	my ($Sys, $Form) = @_;
	
	require './module/nazguls.pl';
	my $Category = ANGMAR->new;
	$Category->Load($Sys);
	
	my @catSet = $Form->GetAtArray('CATS');
	
	# カテゴリリストを出力
	my $categories = [];
	foreach my $id (sort @catSet) {
		my @bbsSet = ();
		push @$categories, {
			'id'		=> $id,
			'name'		=> $Category->Get('NAME', $id),
			'subject'	=> $Category->Get('SUBJECT', $id),
		};
	}
	
	my $indata = {
		'title'			=> 'Category Delete Confirm',
		'intmpl'		=> 'sys.bbs.catdelete',
		'categories'	=> $categories,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の生成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSCreate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# 入力チェック
	return 1001 if (!$Form->IsInput([qw(BBS_DIR BBS_NAME BBS_CATEGORY)]));
	return 1002 if (!$Form->IsBBSDir([qw(BBS_DIR)]));
	
	require './module/earendil.pl';
	
	# POSTデータの取得
	my $bbsCategory		= $Form->Get('BBS_CATEGORY');
	my $bbsDir			= $Form->Get('BBS_DIR');
	my $bbsName			= $Form->Get('BBS_NAME');
	my $bbsExplanation	= $Form->Get('BBS_EXPLANATION');
	my $bbsInherit		= $Form->Get('BBS_INHERIT');
	
	# パスの設定
	my $createPath	= $Sys->Get('BBSPATH').'/'.$bbsDir;
	my $dataPath	= '.'.$Sys->Get('DATA');
	
	# 掲示板ディレクトリの作成に成功したら、その下のディレクトリを作成する
	if (!EARENDIL::CreateDirectory($createPath, $Sys->Get('PM-BDIR'))) {
		return 2000;
	}
	
	# サブディレクトリ生成
	EARENDIL::CreateDirectory("$createPath/i", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/dat", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/log", $Sys->Get('PM-LDIR'));
	EARENDIL::CreateDirectory("$createPath/kako", $Sys->Get('PM-BDIR'));
	EARENDIL::CreateDirectory("$createPath/pool", $Sys->Get('PM-ADIR'));
	EARENDIL::CreateDirectory("$createPath/info", $Sys->Get('PM-ADIR'));
	
	# デフォルトデータのコピー
	EARENDIL::Copy("$dataPath/default_img.gif", "$createPath/kanban.gif");
	EARENDIL::Copy("$dataPath/default_bac.gif", "$createPath/ba.gif");
	EARENDIL::Copy("$dataPath/default_hed.txt", "$createPath/head.txt");
	EARENDIL::Copy("$dataPath/default_fot.txt", "$createPath/foot.txt");
	
	push @$pLog, "■掲示板ディレクトリ生成完了...[$createPath]";
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	$Boards->Load($Sys);
	
	# 設定継承情報のコピー
	if ($bbsInherit ne '') {
		my $inheritPath = $Sys->Get('BBSPATH').'/'.$Boards->Get('DIR', $bbsInherit);
		EARENDIL::Copy("$inheritPath/SETTING.TXT", "$createPath/SETTING.TXT");
		EARENDIL::Copy("$inheritPath/info/groups.cgi", "$createPath/info/groups.cgi");
		EARENDIL::Copy("$inheritPath/info/capgroups.cgi", "$createPath/info/capgroups.cgi");
		
		push @$pLog, "■設定継承完了...[$inheritPath]";
	}
	
	# 掲示板設定情報生成
	require './module/isildur.pl';
	my $bbsSetting = ISILDUR->new;
	
	$Sys->Set('BBS', $bbsDir);
	$bbsSetting->Load($Sys);
	
	require './module/galadriel.pl';
	my $createPath2 = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $createPath);
	my $cookiePath = GALADRIEL::MakePath($Sys->Get('CGIPATH'), $Sys->Get('BBSPATH'));
	$bbsSetting->Set('BBS_TITLE', $bbsName);
	$bbsSetting->Set('BBS_SUBTITLE', $bbsExplanation);
	$bbsSetting->Set('BBS_BG_PICTURE', "$createPath2/ba.gif");
	$bbsSetting->Set('BBS_TITLE_PICTURE', "$createPath2/kanban.gif");
	$bbsSetting->Set('BBS_COOKIEPATH', "$cookiePath/");
	
	$bbsSetting->Save($Sys);
	
	push @$pLog, '■掲示板設定完了...';
	
	# 掲示板構成要素生成
	my ($BBSAid);
	require './module/varda.pl';
	$BBSAid = VARDA->new;
	
	$Sys->Set('MODE', 'CREATE');
	$BBSAid->Init($Sys, $bbsSetting);
	$BBSAid->CreateIndex();
	$BBSAid->CreateIIndex();
	$BBSAid->CreateSubback();
	
	push @$pLog, '■掲示板構\成要素生成完了...';
	
	# 過去ログインデクス生成
	require './module/thorin.pl';
	require './module/celeborn.pl';
	my $PastLog = CELEBORN->new;
	my $Page = THORIN->new;
	$PastLog->Load($Sys);
	$PastLog->UpdateInfo($Sys);
	$PastLog->UpdateIndex($Sys, $Page);
	$PastLog->Save($Sys);
	
	push @$pLog, '■過去ログインデクス生成完了...';
	
	# 掲示板情報に追加
	$Boards->Add($bbsName, $bbsDir, $bbsExplanation, $bbsCategory);
	$Boards->Save($Sys);
	
	push @$pLog, '■掲示板情報追加完了';
	push @$pLog, "　　　　名前：$bbsName";
	push @$pLog, "　　　　サブジェクト：$bbsExplanation";
	push @$pLog, "　　　　カテゴリ：$bbsCategory";
	push @$pLog, '<hr>以下のURLに掲示板を作成しました。';
	push @$pLog, "<a href=\"$createPath/\" target=_blank>$createPath/</a>";
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	require './module/nazguls.pl';
	require './module/varda.pl';
	my $Boards = NAZGUL->new;
	my $BBSAid = VARDA->new;
	
	$Boards->Load($Sys);
	
	my @bbsSet = $Form->GetAtArray('BBSS');
	
	foreach my $id (@bbsSet) {
		my $bbs = $Boards->Get('DIR', $id, '');
		next if ($bbs eq '');
		my $name = $Boards->Get('NAME', $id);
		$Sys->Set('BBS', $bbs);
		$Sys->Set('MODE', 'CREATE');
		$BBSAid->Init($Sys, undef);
		$BBSAid->CreateIndex();
		$BBSAid->CreateIIndex();
		$BBSAid->CreateSubback();
		
		push @$pLog, "■掲示板「$name」を更新しました。";
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板情報の更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSInfoUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	
	$Boards->Load($Sys);
	$Boards->Update($Sys, '');
	$Boards->Save($Sys);
	
	push @$pLog, '■掲示板情報の更新が正常に終了しました。';
	push @$pLog, '※カテゴリは全て「一般」に設定されたので、再設定してください。';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板の削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBBSDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	require './module/earendil.pl';
	my $Boards = NAZGUL->new;
	$Boards->Load($Sys);
	
	my @bbsSet = $Form->GetAtArray('BBSS');
	
	foreach my $id (@bbsSet) {
		my $dir = $Boards->Get('DIR', $id, '');
		next if ($dir ne '');
		my $name = $Boards->Get('NAME', $id);
		my $path = $Sys->Get('BBSPATH') . "/$dir";
		
		# 掲示板ディレクトリと掲示板情報の削除
		EARENDIL::DeleteDirectory($path);
		$Boards->Delete($id);
		
		push @$pLog, "■掲示板「$name($dir)」を削除しました。<br>";
	}
	
	$Boards->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの追加
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryAdd
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Category = ANGMAR->new;
	$Category->Load($Sys);
	
	my $name = $Form->Get('NAME');
	my $subj = $Form->Get('SUBJ');
	
	$Category->Add($name, $subj);
	$Category->Save($Sys);
	
	# ログの設定
	push @$pLog, '■ カテゴリ追加';
	push @$pLog, "カテゴリ名称：$name";
	push @$pLog, "カテゴリ説明：$subj";
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	my @catSet = $Form->GetAtArray('CATS');
	
	foreach my $id (@catSet) {
		if ($id ne '0000000001') {
			my $name = $Category->Get('NAME', $id);
			my @bbsSet = ();
			$Boards->GetKeySet('CATEGORY', $id, \@bbsSet);
			foreach my $bbsid (@bbsSet) {
				$Boards->Set($bbsid, 'CATEGORY', '0000000001');
			}
			$Category->Delete($id);
			push @$pLog, "カテゴリ「$name」を削除";
		}
	}
	
	$Boards->Save($Sys);
	$Category->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	カテゴリの変更
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionCategoryChange
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/nazguls.pl';
	my $Boards = NAZGUL->new;
	my $Category = ANGMAR->new;
	$Boards->Load($Sys);
	$Category->Load($Sys);
	
	my @bbsSet	= $Form->GetAtArray('BBSS');
	my $catid	= $Form->Get('SEL_CATEGORY');
	my $catname	= $Category->Get('NAME', $catid);
	
	foreach my $id (@bbsSet) {
		$Boards->Set($id, 'CATEGORY', $catid);
		my $bbsname = $Boards->Get('NAME', $id);
		push @$pLog, "「$bbsname」のカテゴリを「$catname」に変更";
	}
	
	$Boards->Save($Sys);
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

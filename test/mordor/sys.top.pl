#============================================================================================================
#
#	システム管理 - ユーザ モジュール
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;
no warnings 'redefine';

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
	
	# 通知一覧画面
	if ($subMode eq 'NOTICE') {
		CheckVersionUpdate($Sys);
		$indata = PreparePageNoticeList($Sys, $Form);
	}
	# 通知一覧画面
	elsif ($subMode eq 'NOTICE_CREATE') {
		$indata = PreparePageNoticeCreate($Sys, $Form);
	}
	# ログ閲覧画面
	elsif ($subMode eq 'ADMINLOG') {
		$indata = PreparePageAdminLog($Sys, $Form, $CGI->{'LOGGER'});
	}
	# 設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('ユーザ通知処理', $this->{'LOG'});
	}
	# 設定失敗画面
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
	
	# 通知作成
	if ($subMode eq 'CREATE') {
		$err = FunctionNoticeCreate($Sys, $Form, $this->{'LOG'});
	}
	# 通知削除
	elsif ($subMode eq 'DELETE') {
		$err = FunctionNoticeDelete($Sys, $Form, $this->{'LOG'});
	}
	# 操作ログ削除
	elsif ($subMode eq 'LOG_REMOVE') {
		$err = FunctionLogRemove($Sys, $Form, $CGI->{'LOGGER'}, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", 'COMPLETE');
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
	
	# 共通表示メニュー
	$Base->SetMenu('ユーザ通知一覧', "'sys.top','DISP','NOTICE'");
	$Base->SetMenu('ユーザ通知作成', "'sys.top','DISP','NOTICE_CREATE'");
	
	# システム管理権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('', '');
		$Base->SetMenu('操作ログ閲覧', "'sys.top','DISP','ADMINLOG'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知一覧の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageNoticeList
{
	my ($Sys, $Form) = @_;
	
	require './module/galadriel.pl';
	require './module/gandalf.pl';
	
	# 通知情報の読み込み
	my $Notices = GANDALF->new;
	$Notices->Load($Sys);
	
	my @noticeSet = ();
	$Notices->GetKeySet('ALL', '', \@noticeSet);
	@noticeSet = reverse sort @noticeSet;
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# 表示数の設定
	my $listnum = scalar(@noticeSet);
	my $dispnum = int($Form->Get('DISPNUM_NOTICE', 5) || 5);
	my $dispst = &$max(int($Form->Get('DISPST_NOTICE') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	my $CGI = $Sys->Get('ADMIN');
	my $user = $CGI->{'USER'};
	
	# 通知一覧を出力
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $noticeSet[$nextnum++];
		
		if ($Notices->IsInclude($id, $user) && ! $Notices->IsLimitOut($id)) {
			my $from;
			if ($Notices->Get('FROM', $id) eq '0000000000') {
				$from = '0ch+管理システム';
			}
			else {
				$from = $CGI->{'SECINFO'}->{'USER'}->Get('NAME', $Notices->Get('FROM', $id));
			}
			
			push @$displist, {
				'id'		=> $id,
				'from'		=> $from,
				'subject'	=> $Notices->Get('SUBJECT', $id),
				'text'		=> $Notices->Get('TEXT', $id),
				'date'		=> GALADRIEL->GetDateFromSerial($Notices->Get('DATE', $id), 0),
			};
			last if (scalar(@$displist) >= $dispnum);
		}
	}
	
	my $indata = {
		'title'		=> 'User Notice List',
		'intmpl'	=> 'sys.top.noticelist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'notices'	=> $displist,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知作成画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageNoticeCreate
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $User = $Sec->{'USER'};
	
	my $issysad = $Sec->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*');
	
	my @userSet = ();
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $users = [];
	foreach my $id (@userSet) {
		push @$users, {
			'id'		=> $id,
			'name'		=> $User->Get('NAME', $id),
			'fullname'	=> $User->Get('FULL', $id),
		};
	}
	my $indata = {
		'title'		=> 'User Notice Create',
		'intmpl'	=> 'sys.top.noticecreate',
		'issysad'	=> $issysad,
		'users'		=> $users,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	管理操作ログ閲覧画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageAdminLog
{
	my ($Sys, $Form, $Logger) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# 表示数の設定
	my $listnum = $Logger->Size();
	my $dispnum = int($Form->Get('DISPNUM_LOG', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST_LOG') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	require './module/galadriel.pl';
	
	# ログ一覧を出力
	my $displog = [];
	while ($nextnum < $listnum) {
		my $data = $Logger->Get($listnum - $nextnum++ - 1);
		my @elem = split(/<>/, $data, -1);
		
		push @$displog, {
			'date'		=> $elem[0],
			'user'		=> $elem[1],
			'operation'	=> $elem[2],
			'result'	=> $elem[3],
		};
		last if (scalar(@$displog) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Operation Log',
		'intmpl'	=> 'sys.top.adminlog',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'logs'		=> $displog,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	ユーザ通知作成
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeCreate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$cuser) {
		return 1000;
	}
	
	# 入力チェック
	if ('input check') {
		my $inList = ['NOTICE_TITLE', 'NOTICE_CONTENT'];
		if (!$Form->IsInput($inList)) {
			return 1001;
		}
		$inList = ['NOTICE_LIMIT'];
		if ($Form->Equal('NOTICE_KIND', 'ALL') && !$Form->IsInput($inList)) {
			return 1001;
		}
		$inList = ['NOTICE_USERS'];
		if ($Form->Equal('NOTICE_KIND', 'ONE') && !$Form->IsInput($inList)) {
			return 1001;
		}
	}
	
	require './module/gandalf.pl';
	my $Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	my $date = time;
	my $subject = $Form->Get('NOTICE_TITLE');
	my $content = $Form->Get('NOTICE_CONTENT');
	my $users = '*';
	my $limit = 0;
	
	require './module/galadriel.pl';
	GALADRIEL->ConvertCharacter1(\$subject, 0);
	GALADRIEL->ConvertCharacter1(\$content, 2);
	
	if ($Form->Equal('NOTICE_KIND', 'ALL')) {
		$limit = int($Form->Get('NOTICE_LIMIT', 0) || 0);
		$limit = $date + ($limit * 24 * 60 * 60);
	}
	else {
		$users = join(',', $Form->GetAtArray('NOTICE_USERS'));
	}
	
	# 通知情報を追加
	$Notice->Add($users, $cuser, $subject, $content, $limit);
	$Notice->Save($Sys);
	
	push @$pLog, 'ユーザへの通知終了';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	通知削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$cuser) {
		return 1000;
	}
	
	require './module/gandalf.pl';
	my $Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	foreach my $id ($Form->GetAtArray('NOTICES')) {
		my $subj = $Notice->Get('SUBJECT', $id);
		# 存在しない通知
		next if (!defined $subj);
		# 全体通知
		if ($Notice->Get('TO', $id) eq '*') {
			if ($Notice->Get('FROM', $id) ne $cuser) {
				push @$pLog, "通知「$subj」は全体通知なので削除できませんでした。";
			}
			else {
				$Notice->Delete($id);
				push @$pLog, "全体通知「$subj」を削除しました。";
			}
		}
		# 個別通知
		else {
			$Notice->RemoveToUser($id, $cuser);
			push @$pLog, "通知「$subj」を削除しました。";
		}
	}
	
	$Notice->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	操作ログ削除
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$Logger	
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogRemove
{
	my ($Sys, $Form, $Logger, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*')) {
		return 1000;
	}
	
	$Logger->Clear();
	push @$pLog, '操作ログを削除しました。';
	
	return 0;
}


sub CheckVersionUpdate
{
	my ($Sys) = @_;
	
	my $Release = $Sys->Get('ADMIN')->{'NEWRELEASE'};
	
	if ($Release->Get('Update')) {
		my $newver = $Release->Get('Ver');
		my $reldate = $Release->Get('Date');
		
		# ユーザ通知 準備
		require './module/gandalf.pl';
		my $Notice = GANDALF->new;
		$Notice->Load($Sys);
		my $nid = 'verupnotif';
		
		# 通知時刻
		use Time::Local;
		$_ = [split /\./, $reldate];
		my $date = timelocal(0, 0, 0, $_->[2], $_->[1]-1, $_->[0]);
		my $limit = 0;
		
		# 通知内容
		my $note = join('<br>', @{$Release->Get('Detail')});
		my $subject = "0ch+ New Version $newver is Released.";
		my $content = "<!-- \*Ver=$newver\* --> $note";
		
		# 通知者 0ch+管理システム
		my $from = '0000000000';
		
		# 通知先 管理者権限を持つユーザ
		require './module/elves.pl';
		my $User = GLORFINDEL->new;
		$User->Load($Sys);
		my @toSet = ();
		$User->GetKeySet('SYSAD', 1, \@toSet);
		my $users = join(',', @toSet, 'nouser');
		
		# 通知を追加
		if ($Notice->Get('TEXT', $nid, '') =~ /\*Ver=(.+?)\*/ && $1 eq $newver) {
			$Notice->{'TO'}->{$nid}			= $users;
			$Notice->{'TEXT'}->{$nid}		= $content;
			$Notice->{'DATE'}->{$nid}		= $date;
		}
		else {
			#$Notice->Add($users, $from, $subject, $content, $limit);
			$Notice->{'TO'}->{$nid}			= $users;
			$Notice->{'FROM'}->{$nid}		= $from;
			$Notice->{'SUBJECT'}->{$nid}	= $subject;
			$Notice->{'TEXT'}->{$nid}		= $content;
			$Notice->{'DATE'}->{$nid}		= $date;
			$Notice->{'LIMIT'}->{$nid}		= $limit;
			$Notice->Save($Sys);
		}
	}
	
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

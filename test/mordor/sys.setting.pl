#============================================================================================================
#
#	システム管理 - 設定 モジュール
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
my $Page = 
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# メニューの設定
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# システム情報画面
	if ($subMode eq 'INFO') {
		$indata = PreparePageSystemInfo($Sys, $Form);
	}
	# 基本設定画面
	elsif ($subMode eq 'BASIC') {
		$indata = PreparePageBasicSetting($Sys, $Form);
	}
	# パーミッション設定画面
	elsif ($subMode eq 'PERMISSION') {
		$indata = PreparePagePermissionSetting($Sys, $Form);
	}
	# リミッタ設定画面
	elsif ($subMode eq 'LIMITTER') {
		$indata = PreparePageLimitterSetting($Sys, $Form);
	}
	# その他設定画面
	elsif ($subMode eq 'OTHER') {
		$indata = PreparePageOtherSetting($Sys, $Form);
	}
	# 表示設定
	elsif ($subMode eq 'VIEW') {
		$indata = PreparePageViewSetting($Sys, $Form);
	}
	# 規制設定
	elsif ($subMode eq 'SEC') {
		$indata = PreparePageSecSetting($Sys, $Form);
	}
	# 拡張機能設定画面
	elsif ($subMode eq 'PLUGIN') {
		$indata = PreparePagePluginSetting($Sys, $Form);
	}
	# 拡張機能個別設定設定画面
	elsif ($subMode eq 'PLUGINCONF') {
		$indata = PreparePagePluginOptionSetting($Sys, $Form);
	}
	# システム設定完了画面
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('システム設定処理', $this->{'LOG'});
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
	
	# 基本設定
	if ($subMode eq 'BASIC') {
		$err = FunctionBasicSetting($Sys, $Form, $this->{'LOG'});
	}
	# パーミッション設定
	elsif ($subMode eq 'PERMISSION') {
		$err = FunctionPermissionSetting($Sys, $Form, $this->{'LOG'});
	}
	# 制限設定
	elsif ($subMode eq 'LIMITTER') {
		$err = FunctionLimitterSetting($Sys, $Form, $this->{'LOG'});
	}
	# その他設定
	elsif ($subMode eq 'OTHER') {
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
	# 表示設定
	elsif ($subMode eq 'VIEW') {
		$err = FunctionPlusViewSetting($Sys, $Form, $this->{'LOG'});
	}
	# 規制設定
	elsif ($subMode eq 'SEC') {
		$err = FunctionPlusSecSetting($Sys, $Form, $this->{'LOG'});
	}
	# 拡張機能情報設定
	elsif ($subMode eq 'SET_PLUGIN') {
		$err = FunctionPluginSetting($Sys, $Form, $this->{'LOG'});
	}
	# 拡張機能情報更新
	elsif ($subMode eq 'UPDATE_PLUGIN') {
		$err = FunctionPluginUpdate($Sys, $Form, $this->{'LOG'});
	}
	# 拡張機能個別設定設定
	elsif ($subMode eq 'SET_PLUGINCONF') {
		$err = FunctionPluginOptionSetting($Sys, $Form, $this->{'LOG'});
	}
	
	# 処理結果表示
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", 'COMPLETE');
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
	$Base->SetMenu('情報', "'sys.setting','DISP','INFO'");
	
	# システム管理権限のみ
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('', '');
		$Base->SetMenu('基本設定', "'sys.setting','DISP','BASIC'");
		$Base->SetMenu('パーミッション設定', "'sys.setting','DISP','PERMISSION'");
		$Base->SetMenu('リミッタ設定', "'sys.setting','DISP','LIMITTER'");
		$Base->SetMenu('その他設定', "'sys.setting','DISP','OTHER'");
		$Base->SetMenu('', '');
		$Base->SetMenu('表示設定', "'sys.setting','DISP','VIEW'");
		$Base->SetMenu('規制設定', "'sys.setting','DISP','SEC'");
		$Base->SetMenu('', '');
		$Base->SetMenu('拡張機能\設定', "'sys.setting','DISP','PLUGIN'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	システム情報画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageSystemInfo
{
	my ($Sys, $Form) = @_;
	
	my @checklist = qw(
		Encode
		Time::HiRes
		Time::Local
		Socket
		
		Template
		CGI::Session
		Storable
		Digest::SHA::PurePerl
		Net::DNS::Lite
		List::MoreUtils
		LWP::UserAgent
		XML::Simple
		
		Net::DNS
	);
	
	my $core = {};
	eval {
		require Module::CoreList;
		$core = $Module::CoreList::version{$]};
	};
	
	my $vers = [];
	foreach my $pkg (@checklist) {
		my $var = eval("require $pkg;return \${${pkg}::VERSION};");
		push @$vers, {
			'name'		=> $pkg,
			'version'	=> $var,
			'core'		=> $core->{$pkg},
		};
	}
	
	my $indata = {
		'title'			=> '0ch+ Administrator Information',
		'intmpl'		=> 'sys.setting.sysinfo',
		'zerover'		=> $Sys->Get('VERSION'),
		'perlver'		=> $],
		'perlpath'		=> $^X,
		'filename'		=> $ENV{'SCRIPT_FILENAME'} || $0,
		'serverhost'	=> $ENV{'HTTP_HOST'},
		'servername'	=> $ENV{'SERVER_NAME'},
		'serversoft'	=> $ENV{'SERVER_SOFTWARE'},
		'versions'		=> $vers,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	システム基本設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBasicSetting
{
	my ($Sys, $Form) = @_;
	
	my $server = $Sys->Get('SERVER');
	my $cgipath = $Sys->Get('CGIPATH');
	
	if ($server eq '') {
		my $sname = $ENV{'SERVER_NAME'};
		$server = "http://$sname";
	}
	if ($cgipath eq '') {
		my $path = $ENV{'SCRIPT_NAME'};
		$path =~ s|/[^/]+/[^/]+$||;
		$cgipath = "$path$cgipath";
	}
	
	my $indata = {
		'title'		=> 'System Base Setting',
		'intmpl'	=> 'sys.setting.basic',
		'server'	=> $server,
		'cgipath'	=> $cgipath,
		'bbspath'	=> $Sys->Get('BBSPATH'),
		'infopath'	=> $Sys->Get('INFO'),
		'datapath'	=> $Sys->Get('DATA'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePermissionSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Permission Setting',
		'intmpl'	=> 'sys.setting.perm',
		'datP'		=> sprintf('%o', $Sys->Get('PM-DAT')),
		'txtP'		=> sprintf('%o', $Sys->Get('PM-TXT')),
		'logP'		=> sprintf('%o', $Sys->Get('PM-LOG')),
		'admP'		=> sprintf('%o', $Sys->Get('PM-ADM')),
		'stopP'		=> sprintf('%o', $Sys->Get('PM-STOP')),
		'admDP'		=> sprintf('%o', $Sys->Get('PM-ADIR')),
		'bbsDP'		=> sprintf('%o', $Sys->Get('PM-BDIR')),
		'logDP'		=> sprintf('%o', $Sys->Get('PM-LDIR')),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	制限設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageLimitterSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Limitter Setting',
		'intmpl'	=> 'sys.setting.limit',
		'resmax'	=> $Sys->Get('RESMAX'),
		'submax'	=> $Sys->Get('SUBMAX'),
		'anchors'	=> $Sys->Get('ANKERS'),
		'errmax'	=> $Sys->Get('ERRMAX'),
		'hstmax'	=> $Sys->Get('HSTMAX'),
		'admmax'	=> $Sys->Get('ADMMAX'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageOtherSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Other Setting',
		'intmpl'	=> 'sys.setting.other',
		'urllink'	=> $Sys->Get('URLLINK'),
		'linkst'	=> $Sys->Get('LINKST'),
		'linked'	=> $Sys->Get('LINKED'),
		'pathkind'	=> $Sys->Get('PATHKIND'),
		'headtext'	=> $Sys->Get('HEADTEXT'),
		'headurl'	=> $Sys->Get('HEADURL'),
		'fastmode'	=> $Sys->Get('FASTMODE'),
		'bbsget'	=> $Sys->Get('BBSGET'),
		'upcheck'	=> $Sys->Get('UPCHECK'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageViewSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System View Setting',
		'intmpl'	=> 'sys.setting.view',
		'banner'	=> $Sys->Get('BANNER'),
		'counter'	=> $Sys->Get('COUNTER'),
		'prtext'	=> $Sys->Get('PRTEXT'),
		'prlink'	=> $Sys->Get('PRLINK'),
		'msec'		=> $Sys->Get('MSEC'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageSecSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Regulation Setting',
		'intmpl'	=> 'sys.setting.reg',
		'kakiko'	=> $Sys->Get('KAKIKO'),
		'samba'		=> $Sys->Get('SAMBATM'),
		'defsamba'	=> $Sys->Get('DEFSAMBA'),
		'defhoushi'	=> $Sys->Get('DEFHOUSHI'),
		'trip12'	=> $Sys->Get('TRIP12'),
		'bbq'		=> $Sys->Get('BBQ'),
		'bbx'		=> $Sys->Get('BBX'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePluginSetting
{
	my ($Sys, $Form) = @_;
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my @pluginSet = ();
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	
	my $plugins = [];
	foreach my $id (@pluginSet) {
		push @$plugins, {
			'id'		=> $id,
			'file'		=> $Plugin->Get('FILE', $id),
			'class'		=> $Plugin->Get('CLASS', $id),
			'name'		=> $Plugin->Get('NAME', $id),
			'expl'		=> $Plugin->Get('EXPL', $id),
			'valid'		=> $Plugin->Get('VALID', $id),
			'hascfg'	=> $Plugin->HasConfig($id),
		};
	}
	
	my $indata = {
		'title'		=> 'System Plugin Setting',
		'intmpl'	=> 'sys.setting.plugin',
		'plugins'	=> $plugins,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能個別設定設定画面の表示
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePluginOptionSetting
{
	my ($Sys, $Form) = @_;
	
	my $id = $Form->Get('PLGID');
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	my $Config = PLUGINCONF->new($Plugin, $id);
	
	my $name = $Plugin->Get('NAME', $id);
	my $class = $Plugin->Get('CLASS', $id);
	my $conf = {};
	if ($class->can('getConfig')) {
		$conf = $class->getConfig();
	}
	
	my $type2str = [undef, '数値','文字列','真偽値'];
	
	my $configs = [];
	foreach my $key (sort keys %$conf) {
		push @$configs, {
			'key'		=> $key,
			'keyenc'	=> unpack('H*', $key),
			'val'		=> $Config->GetConfig($key),
			'type'		=> $_ = $conf->{$key}->{'valuetype'},
			'typestr'	=> $type2str->[$_],
			'desc'		=> $conf->{$key}->{'description'},
		};
	}
	
	my $indata = {
		'title'		=> 'System Plugin Option Setting - '.$name,
		'intmpl'	=> 'sys.setting.pluginconf',
		'configs'	=> $configs,
		'plgid'		=> $id,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	基本設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBasicSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# 入力チェック
	return 1001 if (!$Form->IsInput([qw(SERVER CGIPATH BBSPATH INFO DATA)]));
	
	$Sys->Set('SERVER', $Form->Get('SERVER'));
	$Sys->Set('CGIPATH', $Form->Get('CGIPATH'));
	$Sys->Set('BBSPATH', $Form->Get('BBSPATH'));
	$Sys->Set('INFO', $Form->Get('INFO'));
	$Sys->Set('DATA', $Form->Get('DATA'));
	$Sys->Save;
	
	# ログの設定
	push @$pLog, '■ 基本設定';
	push @$pLog, '　　　 サーバ：' . $Form->Get('SERVER');
	push @$pLog, '　　　 CGIパス：' . $Form->Get('CGIPATH');
	push @$pLog, '　　　 掲示板パス：' . $Form->Get('BBSPATH');
	push @$pLog, '　　　 管理データフォルダ：' . $Form->Get('INFO');
	push @$pLog, '　　　 基本データフォルダ：' . $Form->Get('DATA');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	パーミッション設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPermissionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('PM-DAT', oct($Form->Get('PERM_DAT')));
	$Sys->Set('PM-TXT', oct($Form->Get('PERM_TXT')));
	$Sys->Set('PM-LOG', oct($Form->Get('PERM_LOG')));
	$Sys->Set('PM-ADM', oct($Form->Get('PERM_ADMIN')));
	$Sys->Set('PM-STOP', oct($Form->Get('PERM_STOP')));
	$Sys->Set('PM-ADIR', oct($Form->Get('PERM_ADMIN_DIR')));
	$Sys->Set('PM-BDIR', oct($Form->Get('PERM_BBS_DIR')));
	$Sys->Set('PM-LDIR', oct($Form->Get('PERM_LOG_DIR')));
	$Sys->Save;
	
	# ログの設定
	push @$pLog, '■ 基本設定';
	push @$pLog, '　　　 datパーミッション：' . $Form->Get('PERM_DAT');
	push @$pLog, '　　　 txtパーミッション：' . $Form->Get('PERM_TXT');
	push @$pLog, '　　　 logパーミッション：' . $Form->Get('PERM_LOG');
	push @$pLog, '　　　 管理ファイルパーミッション：' . $Form->Get('PERM_ADMIN');
	push @$pLog, '　　　 停止スレッドパーミッション：' . $Form->Get('PERM_STOP');
	push @$pLog, '　　　 管理DIRパーミッション：' . $Form->Get('PERM_ADMIN_DIR');
	push @$pLog, '　　　 掲示板DIRパーミッション：' . $Form->Get('PERM_BBS_DIR');
	push @$pLog, '　　　 ログDIRパーミッション：' . $Form->Get('PERM_LOG_DIR');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	制限値設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitterSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('RESMAX', $Form->Get('RESMAX'));
	$Sys->Set('SUBMAX', $Form->Get('SUBMAX'));
	$Sys->Set('ANKERS', $Form->Get('ANKERS'));
	$Sys->Set('ERRMAX', $Form->Get('ERRMAX'));
	$Sys->Set('HSTMAX', $Form->Get('HSTMAX'));
	$Sys->Set('ADMMAX', $Form->Get('ADMMAX'));
	$Sys->Save;
	
	# ログの設定
	push @$pLog, '■ 基本設定';
	push @$pLog, '　　　 subject最大数：' . $Form->Get('SUBMAX');
	push @$pLog, '　　　 レス最大数：' . $Form->Get('RESMAX');
	push @$pLog, '　　　 アンカー最大数：' . $Form->Get('ANKERS');
	push @$pLog, '　　　 エラーログ最大数：' . $Form->Get('ERRMAX');
	push @$pLog, '　　　 ホストログ最大数：' . $Form->Get('HSTMAX');
	push @$pLog, '　　　 管理操作ログ最大数：' . $Form->Get('ADMMAX');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	その他設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('HEADTEXT', $Form->Get('HEADTEXT'));
	$Sys->Set('HEADURL', $Form->Get('HEADURL'));
	$Sys->Set('URLLINK', ($Form->Equal('URLLINK', 'on') ? 'TRUE' : 'FALSE'));
	$Sys->Set('LINKST', $Form->Get('LINKST'));
	$Sys->Set('LINKED', $Form->Get('LINKED'));
	$Sys->Set('PATHKIND', $Form->Get('PATHKIND'));
	$Sys->Set('FASTMODE', ($Form->Equal('FASTMODE', 'on') ? 1 : 0));
	$Sys->Set('BBSGET', ($Form->Equal('BBSGET', 'on') ? 1 : 0));
	$Sys->Set('UPCHECK', $Form->Get('UPCHECK'));
	$Sys->Save();
	
	# ログの設定
	push @$pLog, '■ その他設定';
	push @$pLog, '　　　 ヘッダテキスト：' . $Sys->Get('HEADTEXT');
	push @$pLog, '　　　 ヘッダURL：' . $Sys->Get('HEADURL');
	push @$pLog, '　　　 URL自動リンク：' . $Sys->Get('URLLINK');
	push @$pLog, '　　　 　開始時間：' . $Sys->Get('LINKST');
	push @$pLog, '　　　 　終了時間：' . $Sys->Get('LINKED');
	push @$pLog, '　　　 PATH種別：' . $Sys->Get('PATHKIND');
	push @$pLog, '　　　 index.htmlを更新しない：' . $Sys->Get('FASTMODE');
	push @$pLog, '　　　 bbs.cgiのGETメソ\ッド：' . $Sys->Get('BBSGET');
	push @$pLog, '　　　 更新チェック間隔：' . $Sys->Get('UPCHECK');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusViewSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('COUNTER', $Form->Get('COUNTER'));
	$Sys->Set('PRTEXT', $Form->Get('PRTEXT'));
	$Sys->Set('PRLINK', $Form->Get('PRLINK'));
	$Sys->Set('BANNER', ($Form->Equal('BANNER', 'on') ? 1 : 0));
	$Sys->Set('MSEC', ($Form->Equal('MSEC', 'on') ? 1 : 0));
	$Sys->Save;
	
	# ログの設定
	push @$pLog, '■ 表示設定';
	push @$pLog, '　　　 カウンターアカウント：' . $Sys->Get('COUNTER');
	push @$pLog, '　　　 PR欄表\示文字列：' . $Sys->Get('PRTEXT');
	push @$pLog, '　　　 PR欄リンクURL：' . $Sys->Get('PRLINK');
	push @$pLog, '　　　 バナー表\示：' . $Sys->Get('BANNER');
	push @$pLog, '　　　 ミリ秒表示：' . $Sys->Get('MSEC');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	規制設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusSecSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('KAKIKO', ($Form->Equal('KAKIKO', 'on') ? 1 : 0));
	$Sys->Set('SAMBATM', $Form->Get('SAMBATM'));
	$Sys->Set('DEFSAMBA', $Form->Get('DEFSAMBA'));
	$Sys->Set('DEFHOUSHI', $Form->Get('DEFHOUSHI'));
	$Sys->Set('TRIP12', ($Form->Equal('TRIP12', 'on') ? 1 : 0));
	$Sys->Set('BBQ', ($Form->Equal('BBQ', 'on') ? 1 : 0));
	$Sys->Set('BBX', ($Form->Equal('BBX', 'on') ? 1 : 0));
	$Sys->Save;
	
	# ログの設定
	push @$pLog, '■ 規制設定';
	push @$pLog, '　　　 2重カキコ規制：' . $Sys->Get('KAKIKO');
	push @$pLog, '　　　 連続投稿規制秒数：' . $Sys->Get('SAMBATM');
	push @$pLog, '　　　 Samba待機秒数：' . $Sys->Get('DEFSAMBA');
	push @$pLog, '　　　 Samba奉仕時間：' . $Sys->Get('DEFHOUSHI');
	push @$pLog, '　　　 12桁トリップ：' . $Sys->Get('TRIP12');
	push @$pLog, '　　　 BBQ：' . $Sys->Get('BBQ');
	push @$pLog, '　　　 BBX：' . $Sys->Get('BBX');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my @pluginSet = ();
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	my @validSet = $Form->GetAtArray('PLUGIN_VALID');
	
	my %order = ();
	for (my $i = 0; $i < scalar(@pluginSet); $i++) {
		my $id = $pluginSet[$i];
		
		my $valid = 0;
		foreach (@validSet) {
			if ($_ eq $id) {
				$valid = 1;
				last;
			}
		}
		$Plugin->Set($id, 'VALID', $valid);
		push @$pLog, $Plugin->Get('NAME', $id) . ' を' . ($valid ? '有効' : '無効') . 'に設定しました。';
		
		$_ = $Form->Get("PLUGIN_${id}_ORDER", $i + 1);
		$_ = $i + 1 if ($_ ne ($_ - 0));
		$_ -= 0;
		$order{$_} = [] if (!exists $order{$_});
		push @{$order{$_}}, $id;
	}
	
	$Plugin->{'ORDER'} = [map { @{$order{$_}} } sort {$a <=> $b} keys %order];
	$Plugin->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報更新
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	
	# 情報の更新と保存
	$Plugin->Load($Sys);
	$Plugin->Update;
	$Plugin->Save($Sys);
	
	# ログの設定
	push @$pLog, '■ プラグイン情報の更新';
	push @$pLog, '　プラグイン情報の更新を完了しました。';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能個別設定設定
#	-------------------------------------------------------------------------------------
#	@param	$Sys	システム変数
#	@param	$Form	フォーム変数
#	@param	$pLog	ログ用
#	@return	エラーコード
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginOptionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# 権限チェック
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	my $id = $Form->Get('PLGID');
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	my $Config = PLUGINCONF->new($Plugin, $id);
	
	my $class = $Plugin->Get('CLASS', $id);
	
	if ($class->can('getConfig')) {
		my $conf = $class->getConfig();
		push @$pLog, "$class";
		
		foreach my $key (keys %$conf) {
			my $val = $Form->Get('PLUGIN_OPT_'.unpack('H*', $key));
			$Config->SetConfig($key, $val);
			push @$pLog, "$key を設定しました。";
		}
	}
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

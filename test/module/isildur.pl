#============================================================================================================
#
#	SETTINGデータ管理モジュール(ISILDUR)
#	isuldur.pl
#	--------------------------------------------
#	2002.12.03 start
#	2003.02.15 データ構造の変更
#
#============================================================================================================
package	ISILDUR;

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
	my $this = shift;
	my (%SET, $obj);
	
	$obj = {
		'SETTING'	=> \%SET
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定読み込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $key, $val);
	
	undef %{$this->{'SETTING'}};
	InitSettingData($this->{'SETTING'});
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/SETTING.TXT';
	
	if (-e $path) {
#		eval
		{
			open SETTING, "< $path";
			while (<SETTING>) {
				chomp $_;
				($key, $val) = split(/=/, $_);
				$this->{'SETTING'}->{$key} = $val;
			}
			close SETTING;
		};
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定書き込み
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $key, $val, @ch2setting, %orz);
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/SETTING.TXT';
	
	# ２ちゃんねるのSETTING.TXT順序
	@ch2setting = (
		'BBS_TITLE', 'BBS_TITLE_PICTURE', 'BBS_TITLE_COLOR', 'BBS_TITLE_LINK', 'BBS_BG_COLOR',
		'BBS_BG_PICTURE', 'BBS_NONAME_NAME', 'BBS_MAKETHREAD_COLOR', 'BBS_MENU_COLOR', 'BBS_THREAD_COLOR',
		'BBS_TEXT_COLOR', 'BBS_NAME_COLOR', 'BBS_LINK_COLOR', 'BBS_ALINK_COLOR', 'BBS_VLINK_COLOR',
		'BBS_THREAD_NUMBER', 'BBS_CONTENTS_NUMBER', 'BBS_LINE_NUMBER', 'BBS_MAX_MENU_THREAD', 'BBS_SUBJECT_COLOR',
		'BBS_PASSWORD_CHECK', 'BBS_UNICODE', 'BBS_DELETE_NAME', 'BBS_NAMECOOKIE_CHECK', 'BBS_MAILCOOKIE_CHECK',
		'BBS_SUBJECT_COUNT', 'BBS_NAME_COUNT', 'BBS_MAIL_COUNT', 'BBS_MESSAGE_COUNT', 'BBS_NEWSUBJECT',
		'BBS_THREAD_TATESUGI', 'BBS_AD2', 'SUBBBS_CGI_ON', 'NANASHI_CHECK', 'timecount', 'timeclose',
		'BBS_PROXY_CHECK', 'BBS_OVERSEA_THREAD', 'BBS_OVERSEA_PROXY', 'BBS_RAWIP_CHECK', 'BBS_SLIP',
		'BBS_DISP_IP', 'BBS_FORCE_ID', 'BBS_BE_ID', 'BBS_BE_TYPE2', 'BBS_NO_ID', 'BBS_JP_CHECK',
		'BBS_VIP931', 'BBS_4WORLD', 'BBS_YMD_WEEKS', 'BBS_NINJA'
	);
	
	%orz = %{$this->{'SETTING'}};
	
#	eval
	{
		open SETTING, "> $path";
		flock SETTING, 2;
		binmode SETTING;
		#truncate SETTING, 0;
		#seek SETTING, 0, 0;
		# 順番に出力
		foreach $key ( @ch2setting ) {
			print SETTING "$key=" . $this->Get($key, '') . "\n";
			delete $orz{$key};
		}
		foreach $key (sort keys %orz) {
			#$val = $orz{$key};
			print SETTING "$key=" . $this->Get($key, '') . "\n";
		}
=pod
		foreach $key (sort keys %{$this->{'SETTING'}}) {
			$val = $this->{'SETTING'}->{$key};
			print SETTING "$key=$val\n";
		}
=cut
		close SETTING;
		chmod $Sys->Get('PM-TXT'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定読み込み(指定ファイル)
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub LoadFrom
{
	my $this = shift;
	my ($path) = @_;
	my ($key, $val);
	
	undef %{$this->{'SETTING'}};
	
	if (-e $path) {
#		eval
		{
			open SETTING, "< $path";
			while (<SETTING>) {
				chomp $_;
				($key, $val) = split(/=/, $_);
				$this->{'SETTING'}->{$key} = $val;
			}
			close SETTING;
		};
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定書き込み(指定ファイル)
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub SaveAs
{
	my $this = shift;
	my ($path) = @_;
	my ($key, $val);
	
#	eval
	{
		open SETTING, "> $path";
		flock SETTING, 2;
		binmode SETTING;
		#truncate SETTING, 0;
		#seek SETTING, 0, 0;
		foreach $key (keys %{$this->{'SETTING'}}) {
			$val = $this->{'SETTING'}->{$key};
			print SETTING "$key=$val\n";
		}
		close SETTING;
		#chmod $Sys->Get('PM-TXT'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定キー取得
#	-------------------------------------------------------------------------------------
#	@param	$keySet	キーセット格納バッファ
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($keySet) = @_;
	
	foreach (keys %{$this->{'SETTING'}}) {
		push @$keySet, $_;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定値比較
#	-------------------------------------------------------------------------------------
#	@param	$key	設定キー
#	@param	$val	設定値
#	@return	同等なら真を返す
#
#------------------------------------------------------------------------------------------------------------
sub Equal
{
	my $this = shift;
	my ($key, $val) = @_;
	
	return(defined $this->{'SETTING'}->{$key} && $this->{'SETTING'}->{$key} eq $val);
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定値取得
#	-------------------------------------------------------------------------------------
#	@param	$key	設定キー
#			$default : デフォルト
#	@return	設定値
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'SETTING'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	掲示板設定値設定
#	-------------------------------------------------------------------------------------
#	@param	$key	設定キー
#	@param	$val	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $val) = @_;
	
	$this->{'SETTING'}->{$key} = $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	SETTING項目初期化 - InitSettingData
#	-------------------------------------------
#	引　数：$pSET : ハッシュの参照
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub InitSettingData
{
	my ($pSET) = @_;
	
	%$pSET = (
		# ２ちゃんねる互換設定項目
		'BBS_TITLE'				=> '掲示板＠ぜろちゃんねるプラス',
		'BBS_TITLE_PICTURE'		=> 'kanban.gif',
		'BBS_TITLE_COLOR'		=> '#000000',
		'BBS_TITLE_LINK'		=> 'http://zerochplus.sourceforge.jp/',
		'BBS_BG_COLOR'			=> '#FFFFFF',
		'BBS_BG_PICTURE'		=> 'ba.gif',
		'BBS_NONAME_NAME'		=> '名無しさん＠ぜろちゃんねるプラス',
		'BBS_MAKETHREAD_COLOR'	=> '#CCFFCC',
		'BBS_MENU_COLOR'		=> '#CCFFCC',
		'BBS_THREAD_COLOR'		=> '#EFEFEF',
		'BBS_TEXT_COLOR'		=> '#000000',
		'BBS_NAME_COLOR'		=> 'green',
		'BBS_LINK_COLOR'		=> '#0000FF',
		'BBS_ALINK_COLOR'		=> '#FF0000',
		'BBS_VLINK_COLOR'		=> '#AA0088',
		'BBS_THREAD_NUMBER'		=> 10,
		'BBS_CONTENTS_NUMBER'	=> 10,
		'BBS_LINE_NUMBER'		=> 12,
		'BBS_MAX_MENU_THREAD'	=> 30,
		'BBS_SUBJECT_COLOR'		=> '#FF0000',
		'BBS_PASSWORD_CHECK'	=> 'checked',
		'BBS_UNICODE'			=> 'pass',
		'BBS_DELETE_NAME'		=> 'あぼーん',
		'BBS_NAMECOOKIE_CHECK'	=> 'checked',
		'BBS_MAILCOOKIE_CHECK'	=> 'checked',
		'BBS_SUBJECT_COUNT'		=> 48,
		'BBS_NAME_COUNT'		=> 128,
		'BBS_MAIL_COUNT'		=> 64,
		'BBS_MESSAGE_COUNT'		=> 2048,
		'BBS_NEWSUBJECT'		=> 1,
		'BBS_THREAD_TATESUGI'	=> 5,
		'BBS_AD2'				=> '',
		'SUBBBS_CGI_ON'			=> 1,
		'NANASHI_CHECK'			=> '',
		'timecount'				=> 7,
		'timeclose'				=> 5,
		'BBS_PROXY_CHECK'		=> '',
		'BBS_OVERSEA_THREAD'	=> '',
		'BBS_OVERSEA_PROXY'		=> '',
		'BBS_RAWIP_CHECK'		=> '',
		'BBS_SLIP'				=> '',
		'BBS_DISP_IP'			=> 'checked',
		'BBS_FORCE_ID'			=> '',
		'BBS_BE_ID'				=> '',
		'BBS_BE_TYPE2'			=> '',
		'BBS_NO_ID'				=> '',
		'BBS_JP_CHECK'			=> '',
		'BBS_YMD_WEEKS'			=> '日/月/火/水/木/金/土',
		'BBS_NINJA'				=> '',
		
		# 以下0chオリジナル設定項目
		'BBS_DATMAX'			=> 512,
		'BBS_COOKIEPATH'		=> '/',
		'BBS_READONLY'			=> 'caps',
		'BBS_REFERER_CUSHION'	=> 'jump.x0.to/',
		'BBS_THREADCAPONLY'		=> '',
		'BBS_TRIPCOLUMN'		=> 10,
		'BBS_SUBTITLE'			=> 'またーり雑談',
		'BBS_COLUMN_NUMBER'		=> 256,
		'BBS_SAMBATIME'			=> '',
		'BBS_HOUSHITIME'		=> '',
	);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

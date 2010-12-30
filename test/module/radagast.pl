#============================================================================================================
#
#	cookie管理モジュール(RADAGAST)
#	radagast.pl
#	---------------------------------------------
#	2003.02.07 start
#	2004.03.20 interface一新
#
#============================================================================================================
package RADAGAST;

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
	my ($obj, %COOKIE);
	
	$obj = {
		'COOKIE'	=> \%COOKIE
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie値取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my (@pairs, $name, $value, $gCode);
	
	#require './module/jcode.pl';
	undef $this->{'COOKIE'};
	
	if ($ENV{'HTTP_COOKIE'}) {
		@pairs = split(/;/, $ENV{'HTTP_COOKIE'});
		foreach (@pairs) {
			($name, $value) = split(/=/, $_);
			$name =~ s/ //g;
			#$gCode = jcode::getcode(*value);
			#jcode::convert(*value, $gCode);
			$this->{'COOKIE'}->{$name} = $value;
		}
		return 1;
	}
	return 0;
}
#------------------------------------------------------------------------------------------------------------
#
#	cookie値設定
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@param	$value	設定値
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $value) = @_;
	
	$this->{'COOKIE'}->{$key} = $value;
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie値取得
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#			$default : デフォルト
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'COOKIE'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie値削除
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($key) = @_;
	
	delete $this->{'COOKIE'}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie値存在確認
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@return	キーが存在したらtrue
#
#------------------------------------------------------------------------------------------------------------
sub IsExist
{
	my $this = shift;
	my ($key) = @_;
	
	return exists($this->{'COOKIE'}->{$key});
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie出力
#	-------------------------------------------------------------------------------------
#	@param	$oOut	出力モジュール
#	@param	$path	cookieパス
#	@param	$limit	有効期限
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Out
{
	my $this = shift;
	my ($oOut, $path, $limit) = @_;
	my (@gmt, @week, @month, $date, $key, $value);
	
	require Jcode;
	
	# 日付情報の設定
	@gmt = gmtime(time + $limit * 60);
	@week = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
	@month = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	
	# 有効期限文字列生成
	$date = sprintf('%s, %02d-%s-%04d %02d:%02d:%02d GMT',
					$week[$gmt[6]], $gmt[3], $month[$gmt[4]], $gmt[5] + 1900,
					$gmt[2], $gmt[1], $gmt[0]);
	
	# 設定されているcookieを全て出力する
	foreach $key (keys %{$this->{'COOKIE'}}) {
		$value = $this->{'COOKIE'}->{$key};
		Jcode::convert(\$value, 'utf8', 'sjis');
		$value =~ s/([^\w])/'%'.unpack('H2', $1)/eg;
		$oOut->Print("Set-Cookie: $key=\"$value\"; expires=$date; path=$path\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	cookie取得用javascript出力
#	-------------------------------------------------------------------------------------
#	@param	$oOut	出力モジュール
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($oOut) = @_;
	
	$oOut->Print(<<JavaScript);
<script language="JavaScript" type="text/javascript">
<!--
function l(e) {
	var N = getCookie("NAME"), M = getCookie("MAIL");
	for (var i = 0, j = document.forms ; i < j.length ; i++){
		if (j[i].FROM && j[i].mail) {
			j[i].FROM.value = N;
			j[i].mail.value = M;
		}}
}
window.onload = l;
function getCookie(key) {
	var ptrn = '(?:^|;| )' + key + '="(.*?)"';
	if (document.cookie.match(ptrn))
		return decodeURIComponent(RegExp.\$1);
	return "";
}
//-->
</script>
JavaScript
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

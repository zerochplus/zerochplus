#============================================================================================================
#
#	フォーム情報管理モジュール(SAMWISE)
#	samwise.pl
#	---------------------------------------------
#	2002.12.13 start
#	2003.02.10 IsInput,IsInputAll追加
#	2010.08.14 文字コード変換処理廃止
#	           禁則処理移動
#
#============================================================================================================
package	SAMWISE;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my (%FORM, @SRC, $form, $obj);
	
	if ($ENV{'REQUEST_METHOD'} eq 'POST') {			# POSTメソッド
		read STDIN, $form, $ENV{'CONTENT_LENGTH'};
	}
	else {											# GETメソッド
		$form = $ENV{'QUERY_STRING'};
	}
	@SRC = split(/&/, $form);						# データ分離
	
	$obj = {
		'FORM'	=> \%FORM,
		'SRC'	=> \@SRC
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	フォーム情報デコード - DecodeForm
#	-------------------------------------------
#	引　数：$mode : 
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub DecodeForm
{
	my $this = shift;
	my ($mode) = @_;
	my ($var, $val, $code);
	
	#require './module/jcode.pl';										# jcode.pl要求
	undef %{$this->{'FORM'}};
	
	foreach (@{$this->{'SRC'}}) {										# 各データごとに処理
		($var, $val) = split(/=/, $_);									# name/valueで分離
		$val =~ tr/+/ /;
		$val =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack('C', hex($1))/eg;
		#$code = jcode::getcode(*val);									# コード取得
		#jcode::convert(*val, $code);									# 漢字コードを統一
		$val =~ s/\r\n|\r|\n/\n/g;										# 改行を統一
		$val =~ s/\0//g;												# ぬるぽ
		$this->{'FORM'}->{$var} = $val;									# データセット
		
		$this->{'FORM'}->{"Raw_$var"} = $val;							# データセット
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	特定フォーム情報デコード - GetAtArray
#	-------------------------------------------
#	引　数：$key : 取得キー
#			$f   : 変換フラグ
#	戻り値：キーデータの配列
#
#------------------------------------------------------------------------------------------------------------
sub GetAtArray
{
	my $this = shift;
	my ($key, $f) = @_;
	my ($var, $val, $code, @ret);
	
	#require './module/jcode.pl';											# jcode.pl要求
	undef @ret;
	
	foreach (@{$this->{'SRC'}}) {											# 各データごとに処理
		($var, $val) = split(/=/, $_);										# name/valueで分離
		if ($key eq $var) {													# 指定キー
			$val =~ tr/+/ /;
			$val =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack('C', hex($1))/eg;
			#$code = jcode::getcode(*val);									# コード取得
			#jcode::convert(*val, $code);									# 漢字コードを統一'
			$val =~ s/\r\n|\r|\n/\n/g;										# 改行を統一
			$val =~ s/\0//g;												# ぬるぽ
			if ($f) {
				$val =~ s/"/&quot;/g;										# 特殊文字対策 "
				$val =~ s/</&lt;/g;											# 特殊文字対策 <
				$val =~ s/>/&gt;/g;											# 特殊文字対策 >
				$val =~ s/\r\n|\r|\n/<br>/g;								# 改行
			}
			push @ret, $val;
		}
	}
	return @ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	フォーム情報取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#	戻り値：データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key) = @_;
	my ($val);
	
	$val = $this->{'FORM'}->{$key};
	$val = '' if (! defined $val);
	
	return $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	フォーム情報設定 - Set
#	-------------------------------------------
#	引　数：$key  : 取得キー
#			$data : 設定データ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{'FORM'}->{$key} = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	form値存在確認
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@param	$data	値
#	@return	値が等しいならtrueを返す
#
#------------------------------------------------------------------------------------------------------------
sub Equal
{
	my $this = shift;
	my ($key, $data) = @_;
	my ($val);
	
	$val = $this->{'FORM'}->{$key};
	$val = '' if (! defined $val);
	
	return ($val eq $data);
}

#------------------------------------------------------------------------------------------------------------
#
#	入力チェック - IsInput
#	-------------------------------------------
#	引　数：@keylist : 判定項目リスト
#	戻り値：入力OKなら1,未入力ありなら0
#
#------------------------------------------------------------------------------------------------------------
sub IsInput
{
	my $this = shift;
	my ($pKeyList) = @_;
	
	foreach (@$pKeyList) {
		if ($this->{'FORM'}->{$_} eq '') {
			return 0;
		}
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	全入力チェック - IsInput
#	-------------------------------------------
#	引　数：なし
#	戻り値：入力OKなら1,未入力ありなら0
#
#------------------------------------------------------------------------------------------------------------
sub IsInputAll
{
	my $this = shift;
	
	foreach (keys %{$this->{'FORM'}}) {
		if ($this->{'FORM'}->{$_} eq '') {
			return 0;
		}
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	form値存在確認
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@return	キーが存在したらtrue
#
#------------------------------------------------------------------------------------------------------------
sub IsExist
{
	my $this = shift;
	my ($key) = @_;
	
	return exists $this->{'FORM'}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	form値存在確認
#	-------------------------------------------------------------------------------------
#	@param	$key	キー
#	@param	$string	検索文字
#	@return	検索文字が存在したら1
#
#------------------------------------------------------------------------------------------------------------
sub Contain
{
	my $this = shift;
	my ($key, $string) = @_;
	
	if ($this->{'FORM'}->{$key} =~ /$string/) {
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	列挙form値取得
#	-------------------------------------------------------------------------------------
#	@param	$pArray	結果格納バッファ
#	@param	@list	取得データリスト
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub GetListData
{
	my $this = shift;
	my ($pArray, @list) = @_;
	
	foreach (@list) {
		push @$pArray, $this->{'FORM'}->{$_};
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	数字調査
#	-------------------------------------------------------------------------------------
#	@param	$pKeys	調査データキー
#	@return	数字なら1
#
#------------------------------------------------------------------------------------------------------------
sub IsNumber
{
	my $this = shift;
	my ($pKeys) = @_;
	
	foreach (@$pKeys) {
		if ($this->{'FORM'}->{$_} =~ /\D/) {
			return 0;
		}
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	半角英数字調査
#	-------------------------------------------------------------------------------------
#	@param	$pKeys	調査データキー
#	@return	半角英数字なら1
#
#------------------------------------------------------------------------------------------------------------
sub IsAlphabet
{
	my $this = shift;
	my ($pKeys) = @_;
	
	foreach (@$pKeys) {
		if ($this->{'FORM'}->{$_} =~ /[^0-9a-zA-Z_@]/) {
			return 0;
		}
	}
	return 1;
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

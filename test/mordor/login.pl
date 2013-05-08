#============================================================================================================
#
#	システム管理CGI - ログイン モジュール
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
	
	my $obj = {};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	require './mordor/sauron.pl';
	my $Base = SAURON->new;
	$Base->Create($Sys, $Form);
	
	my $indata = PreparePageLogin($Form->Get('FALSE'));
	
	$Base->Print('LOGIN', 0, $indata);
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
	
	require './module/galadriel.pl';
	my $host = GALADRIEL::GetRemoteHost();
	
	if ($CGI->{'USER'}) {
		require './mordor/sys.top.pl';
		my $Mod = MODULE->new;
		
		$Form->Set('MODE_SUB', 'NOTICE');
		
		$CGI->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'TRUE');
		
		$Mod->DoPrint($Sys, $Form, $CGI);
	}
	else {
		$Form->Set('FALSE', 1);
		
		$CGI->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'FALSE');
		
		$this->DoPrint($Sys, $Form, $CGI);
	}
}

sub PreparePageLogin
{
	my $this = shift;
	my ($isfailed) = @_;
	
	my $indata = {
		'title'		=> 'LOGIN',
		'intmpl'	=> 'login',
		'isfailed'	=> $isfailed,
	};
	
	return $indata;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

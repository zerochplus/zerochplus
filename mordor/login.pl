#============================================================================================================
#
#	システム管理CGI - ログイン モジュール
#	login.pl
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================
package	MODULE;

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
	my		$this = shift;
	my		($obj);
	
	$obj = {
	};
	
	bless($obj,$this);
	
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
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($BASE,$Page);
	
	require('./mordor/sauron.pl');
	$BASE = new SAURON;
	
	$Page = $BASE->Create($Sys,$Form);
	
	PrintLogin($Page,$Form);
	
	$BASE->PrintNoList("LOGIN");
}

#------------------------------------------------------------------------------------------------------------
#
#	機能メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	管理システム
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my		$this = shift;
	my		($Sys,$Form,$pSys) = @_;
	my		($host);
	
	$Security = $pSys->{'SECINFO'};
	require('./module/galadriel.pl');
	$host = GALADRIEL::GetRemoteHost();
	
	# ログイン情報を確認
	if	($Security->IsLogin($Form->Get('UserName'),$Form->Get('PassWord'))){
		require('./mordor/sys.top.pl');
		$Mod = new MODULE;
		$Form->Set('MODE_SUB','NOTICE');
		
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]",'Login','TRUE');
		
		$Mod->DoPrint($Sys,$Form,$pSys);
	}
	else{
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]",'Login','FALSE');
		$Form->Set('FALSE',1);
		$this->DoPrint($Sys,$Form,$pSys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	表示メソッド
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintLogin
{
	my		($Page,$Form) = @_;
	
	$Page->Print("<center><br><br><br><br>");
	
	if	($Form->Get('FALSE') == 1){
		$Page->Print("<font color=red><b>※ユーザ名もしくはパスワードが間違っています。</b></font>");
	}
	$Page->Print("<br><br><table>\n");
	$Page->Print("<tr><td>ユーザ名</td><td><input type=text name=UserName size=30></td></tr>");
	$Page->Print("<tr><td>パスワード</td><td><input type=password name=PassWord size=30></td></tr>");
	$Page->Print("<tr><td colspan=2 align=center><hr><input type=submit value=\"　ログイン　\">");
	$Page->Print("</td></tr></table><br><br><br><br><br><br><b>\n");
	$Page->Print("<font face=Arial size=3 color=red>0ch Administration Page</font><br>");
	$Page->Print("<font face=Arial>Powered by 0ch script and 0ch modules 2002-2004</font><br>");
	$Page->Print("</b></center>\n");
	
	$Page->HTMLInput('hidden','MODE','FUNC');
	$Page->HTMLInput('hidden','MODE_SUB','');
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

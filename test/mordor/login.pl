#============================================================================================================
#
#	�V�X�e���Ǘ�CGI - ���O�C�� ���W���[��
#	login.pl
#	---------------------------------------------------------------------------
#	2004.01.31 start
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj);
	
	$obj = {
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($BASE, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	
	$Page = $BASE->Create($Sys, $Form);
	
	PrintLogin($Page, $Form);
	
	$BASE->PrintNoList('LOGIN', 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$pSys	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $pSys) = @_;
	my ($host, $Security, $Mod);
	
	$Security = $pSys->{'SECINFO'};
	require './module/galadriel.pl';
	$host = GALADRIEL::GetRemoteHost();
	
	# ���O�C�������m�F
	my ($userID, $SID) = $Security->IsLogin($Form->Get('UserName'), undef, $Form->Get('SessionID'));
	if ($userID) {
		require './mordor/sys.top.pl';
		$Mod = MODULE->new;
		$Form->Set('MODE_SUB', 'NOTICE');
		
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'TRUE');
		
		$Mod->DoPrint($Sys, $Form, $pSys);
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName') . "[$host]", 'Login', 'FALSE');
		$Form->Set('FALSE', 1);
		$this->DoPrint($Sys, $Form, $pSys);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintLogin
{
	my ($Page, $Form) = @_;
	
$Page->Print(<<HTML);
  <center>
   <div align="center" class="LoginForm">
HTML
	
	if ($Form->Get('FALSE') == 1) {
		$Page->Print("    <div class=\"xExcuted\">���[�U���������̓p�X���[�h���Ԉ���Ă��܂��B</div>\n");
	}
	
$Page->Print(<<HTML);
    <table align="center" border="0" style="margin:30px 0;">
     <tr>
      <td>���[�U��</td><td><input type="text" name="UserName" style="width:200px"></td>
     </tr>
     <tr>
      <td>�p�X���[�h</td><td><input type="password" name="PassWord" style="width:200px"></td>
     </tr>
     <tr>
      <td colspan="2" align="center">
      <hr>
      <input type="submit" value="�@���O�C���@">
      </td>
     </tr>
    </table>
    
    <div class="Sorce">
     <b>
     <font face="Arial" size="3" color="red">0ch+ Administration Page</font><br>
     <font face="Arial">Powered by 0ch/0ch+ script and 0ch/0ch+ modules 2002-{=0ch+year=}</font>
     </b>
    </div>
    
   </div>
   
  </center>
  
  <!-- ������ȂƂ���ɒn���v��(ry -->
   <input type="hidden" name="MODE" value="FUNC">
   <input type="hidden" name="MODE_SUB" value="">
  <!-- ������ȂƂ���ɒn���v��(ry -->
  
HTML
	
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

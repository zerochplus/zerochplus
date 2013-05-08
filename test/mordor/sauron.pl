#============================================================================================================
#
#	�Ǘ�CGI�x�[�X���W���[��
#
#============================================================================================================
package	SAURON;

use strict;
use warnings;

require './module/thorin.pl';

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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,		# MELKOR�ێ�
		'FORM'		=> undef,		# SAMWISE�ێ�
		'INN'		=> undef,		# THORIN�ێ�
		'MENU'		=> undef,		# �@�\���X�g
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�I�u�W�F�N�g����
#	-------------------------------------------------------------------------------------
#	@param	$Sys		MELKOR
#	@param	$Form		SAMWISE
#	@return	THORIN���W���[��
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($Sys, $Form) = @_;
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'INN'}		= THORIN->new;
	$this->{'MENU'}		= [];
	
	return $this->{'INN'};
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[�̐ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$str	�\��������
#	@param	$url	�W�����vURL
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenu
{
	my $this = shift;
	my ($str, $url) = @_;
	
	push @{$this->{'MENU'}}, {
		'str'	=> $str,
		'url'	=> $url,
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	�y�[�W�o��
#	-------------------------------------------------------------------------------------
#	@param	$title	�y�[�W�^�C�g��
#	@param	$mode	
#	@param	$indata	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($title, $mode, $indata) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $CGI = $Sys->Get('ADMIN');
	
	my $Page = THORIN->new;
	$Page->Init('admin.tt');
	$Page->Set({
		'title'		=> $title,
		'datapath'	=> $Sys->Get('DATA'),
		'version'	=> $Sys->Get('VERSION'),
	});
	
	if ($mode) {
		$Page->Set({
			'mode'		=> $mode,
			'menu'		=> $this->{'MENU'},
			'username'	=> $Form->Get('UserName'),
			'sid'		=> $Form->Get('SessionID'),
			'isupdate'	=> $CGI->{'NEWRELEASE'}->Get('Update'),
		});
	}
	
	if (defined $indata) {
		$Page->Set($indata);
	} else {
		warn;
		$this->{'INN'}->Flush(0, 0, \my $inner);
		$Page->Set({'innerhtml' => $inner});
	}
	
	$Page->OutputContentType('text/html');
	$Page->Output;
	
	my ($user, $system, $cuser, $csystem) = times;
	print STDERR "user:$user system:$system cuser:$cuser csystem:$csystem\n";
	
	#foreach my $key (sort keys %INC) {
	#	print STDERR "$key\n" if ($key =~ m/Template/);
	#}
}

#------------------------------------------------------------------------------------------------------------
#
#	������ʂ̏o��
#	-------------------------------------------------------------------------------------
#	@param	$name	������
#	@param	$LogArr	�������O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageComplete
{
	my $this = shift;
	my ($name, $LogArr) = @_;
	
	my $indata = {
		'title'		=> 'Process Complete',
		'intmpl'	=> 'complete',
		'pname'		=> $name,
		'log'		=> $LogArr,
	};
	
	return $indata;
}

sub PrintComplete
{
	my $this = shift;
	my ($name, $LogArr) = @_;
	
	my $PageIn = $this->{'INN'};
	
	$PageIn->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="oExcuted">
     $name�𐳏�Ɋ������܂����B
    </div>
   
    <div class="LogExport">�������O</div>
    <hr>
    <blockquote class="LogExport">
HTML
	
	# ���O�̕\��
	foreach my $text (@$LogArr) {
		$PageIn->Print("     $text<br>\n");
	}
	
	$PageIn->Print(<<HTML);
    </blockquote>
    <hr>
    </td>
   </tr>
  </table>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$LogArr	���O�p
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageError
{
	my $this = shift;
	my ($LogArr) = @_;
	
	my %err2mes = (
		0		=> '�s���ȃG���[���������܂����B',
		1000	=> '�{�@�\�̏��������s���錠��������܂���B',
		1001	=> '���͕K�{���ڂ��󗓂ɂȂ��Ă��܂��B',
		1002	=> '�ݒ荀�ڂɋK��O�̕������g�p����Ă��܂��B',
		2000	=> '�f���f�B���N�g���̍쐬�Ɏ��s���܂����B'
				 . '�p�[�~�b�V�����A�܂��͊��ɓ����̌f�����쐬����Ă��Ȃ������m�F���Ă��������B',
		2001	=> 'SETTING.TXT�̐����Ɏ��s���܂����B',
		2002	=> '�f���\���v�f�̐����Ɏ��s���܂����B',
		2003	=> '�ߋ����O�������̐����Ɏ��s���܂����B',
		2004	=> '�f�����̍X�V�Ɏ��s���܂����B',
	);
	
	my $errnum = pop(@$LogArr);
	my $errmes = $err2mes{$errnum};
	$errmes = $err2mes{0} if (!defined $errmes);
	
	my $indata = {
		'title'		=> 'Process Failed',
		'intmpl'	=> 'error',
		'errnum'	=> $errnum,
		'errmes'	=> $errmes,
		'log'		=> $LogArr,
	};
	
	return $indata;
}

sub PrintError
{
	my $this = shift;
	my ($LogArr) = @_;
	
	my $PageIn = $this->{'INN'};
	
	# �G���[�R�[�h�̒��o
	my $ecode = pop @$LogArr;
	
	$PageIn->Print(<<HTML);
  <table border="0" cellspacing="0" cellpadding="0" width="100%" align="center">
   <tr>
    <td>
    
    <div class="xExcuted">
HTML
	
	if ($ecode == 1000) {
		$PageIn->Print("     ERROR:$ecode - �{�@�\\�̏��������s���錠��������܂���B\n");
	}
	elsif ($ecode == 1001) {
		$PageIn->Print("     ERROR:$ecode - ���͕K�{���ڂ��󗓂ɂȂ��Ă��܂��B\n");
	}
	elsif ($ecode == 1002) {
		$PageIn->Print("     ERROR:$ecode - �ݒ荀�ڂɋK��O�̕������g�p����Ă��܂��B\n");
	}
	elsif ($ecode == 2000) {
		$PageIn->Print("     ERROR:$ecode - �f���f�B���N�g���̍쐬�Ɏ��s���܂����B<br>\n");
		$PageIn->Print("     �p�[�~�b�V�����A�܂��͊��ɓ����̌f�����쐬����Ă��Ȃ������m�F���Ă��������B\n");
	}
	elsif ($ecode == 2001) {
		$PageIn->Print("     ERROR:$ecode - SETTING.TXT�̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2002) {
		$PageIn->Print("     ERROR:$ecode - �f���\\���v�f�̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2003) {
		$PageIn->Print("     ERROR:$ecode - �ߋ����O�������̐����Ɏ��s���܂����B\n");
	}
	elsif ($ecode == 2004) {
		$PageIn->Print("     ERROR:$ecode - �f�����̍X�V�Ɏ��s���܂����B\n");
	}
	else {
		$PageIn->Print("     ERROR:$ecode - �s���ȃG���[���������܂����B\n");
	}
	
	$PageIn->Print(<<HTML);
    </div>
    
HTML

	# �G���[���O������Ώo�͂���
	if (scalar(@$LogArr)) {
		$PageIn->Print('<hr>');
		$PageIn->Print("    <blockquote>");
		foreach my $text (@$LogArr) {
			$PageIn->Print("    $text<br>\n");
		}
		$PageIn->Print("    </blockquote>");
		$PageIn->Print('<hr>');
	}
	
	$PageIn->Print(<<HTML);
    </td>
   </tr>
  </table>
HTML
	
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

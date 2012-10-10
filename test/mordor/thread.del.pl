#============================================================================================================
#
#	�X���b�h�Ǘ� - �폜���X ���W���[��
#	thread.del.pl
#	---------------------------------------------------------------------------
#	2004.08.02 start
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
	my ($obj, @LOG);
	
	$obj = {
		'LOG' => \@LOG
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
	my ($subMode, $BASE, $BBS, $DAT, $Page);
	
	require './mordor/sauron.pl';
	$BASE = SAURON->new;
	$BBS = $pSys->{'AD_BBS'};
	$DAT = $pSys->{'AD_DAT'};
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	if (! defined $pSys->{'AD_BBS'}) {
		require './module/nazguls.pl';
		$BBS = NAZGUL->new;
		
		$BBS->Load($Sys);
		$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
		$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	}
	
	# dat�̓ǂݍ���
	if (! defined $pSys->{'AD_DAT'}) {
		require './module/gondor.pl';
		$DAT = ARAGORN->new;
		
		$Sys->Set('KEY', $Form->Get('TARGET_THREAD'));
		my $datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/del_' . $Sys->Get('KEY') . '.cgi';
		$DAT->Load($Sys, $datPath, 1);
	}
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	$Page		= $BASE->Create($Sys, $Form);
	$subMode	= $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($BASE, $pSys, $Form->Get('TARGET_BBS'));
	
	if ($subMode eq 'LIST') {														# ���X�ꗗ���
		PrintResList($Page, $Sys, $Form, $DAT);
	}
	elsif ($subMode eq 'COMPLETE') {												# �������
		PrintComplete($Page, $Sys, $Form, $this->{'LOG'});
	}
	elsif ($subMode eq 'FALSE') {													# ���s���
		PrintError($Page, $Sys, $Form, $this->{'LOG'});
	}
	
	# �f���E�X���b�h����ݒ�
	$Page->HTMLInput('hidden', 'TARGET_BBS', $Form->Get('TARGET_BBS'));
	$Page->HTMLInput('hidden', 'TARGET_THREAD', $Form->Get('TARGET_THREAD'));
	
	$BASE->Print($Sys->Get('_TITLE') . ' - ' . $BBS->Get('NAME', $Form->Get('TARGET_BBS'))
					. ' - �폜���X', 3);
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
	my ($subMode, $err, $BBS, $DAT);
	
	require './module/gondor.pl';
	require './module/nazguls.pl';
	$BBS = NAZGUL->new;
	$DAT = ARAGORN->new;
	
	# �f�����̓ǂݍ��݂ƃO���[�v�ݒ�
	$BBS->Load($Sys);
	$Sys->Set('BBS', $BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	$pSys->{'SECINFO'}->SetGroupInfo($BBS->Get('DIR', $Form->Get('TARGET_BBS')));
	
	# dat�̓ǂݍ���
	$Sys->Set('KEY', $Form->Get('TARGET_THREAD'));
	my $datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/del_' . $Sys->Get('KEY') . '.cgi';
	$DAT->Load($Sys, $datPath, 1);
	
	$subMode	= $Form->Get('MODE_SUB');
	$err		= 9999;
	
	if ($subMode eq 'REPARE') {													# �폜���X����
		$err = FunctionResRepare($Sys, $Form, $DAT, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"DELETE_RES($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$pSys->{'LOGGER'}->Put($Form->Get('UserName'),"DELETE_RES($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	$pSys->{'AD_BBS'} = $BBS;
	$pSys->{'AD_DAT'} = $DAT;
	$this->DoPrint($Sys, $Form, $pSys);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $pSys, $bbs) = @_;
	
	$Base->SetMenu('�폜���X�ꗗ', "'thread.del','DISP','LIST'");
	$Base->SetMenu('<hr>', '');
	$Base->SetMenu('�f���Ǘ��֖߂�', "'bbs.thread','DISP','LIST'");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResList
{
	my ($Page, $Sys, $Form, $Dat) = @_;
	my (@elem, $resNum, $dispNum, $dispSt, $dispEd, $common, $i);
	my ($pRes, $isAbone, $isEdit, $format);
	
	$Sys->Set('_TITLE', 'Delete Res List');
	
	# �\�������̐ݒ�
	$format = $Form->Get('DISP_FORMAT_DEL') eq '' ? '-10' : $Form->Get('DISP_FORMAT_DEL');
	($dispSt, $dispEd) = AnalyzeFormat($format, $Dat);
	
	$common = "DoSubmit('thread.del','DISP','LIST');";
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td colspan=2 align=right>�\\�������F<input type=text name=DISP_FORMAT_DEL");
	$Page->Print(" value=\"$format\"><input type=button value=\"�@�\\���@\" onclick=\"$common\">");
	$Page->Print("</td></tr>\n<tr><td colspan=2><hr></td></tr>\n");
	$Page->Print("<tr><th style=\"width:30\">�@</th>");
	$Page->Print("<td class=\"DetailTitle\" style=\"width:300\">Deleted Contents</td></tr>\n");
	
	# �����擾
	$isAbone = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 12, $Sys->Get('BBS'));
	
	# ���X�ꗗ���o��
	for ($i = $dispSt ; $i < $dispEd ; $i++) {
		$pRes	= $Dat->Get($i);
		@elem	= split(/<>/, $$pRes);
		
		# �������폜�������̂�����\��(Administrator�͑S�ĕ\��)
		if ($elem[1] eq $Form->Get('UserName') || $Sys->Get('ADMIN')->{'USER'} eq '0000000001') {
			$Page->Print("<tr><td class=\"Response\" valign=top>");
			
			# ���X�폜���ɂ��\���}��
			if ($isAbone) {
				$Page->Print("<input type=checkbox name=DEL_RESS value=$i></td>");
			}
			else {
				$Page->Print("</td>");
			}
			$common = ($elem[3] ? '�y���ځ[��z' : '�y�������ځ[��z');
			$Page->Print("<td class=\"Response\"><dt>$common<br>" . ($elem[2] + 1));
			$Page->Print("�F<font color=forestgreen><b>$elem[4]</b></font>[$elem[5]]");
			$Page->Print("�F$elem[6]</dt><dd>$elem[7]<br><br></dd></td></tr>\n");
		}
	}
	$Page->Print("<tr><td colspan=2><hr></td></tr>\n");
	
	# �V�X�e�������L���ɂ��\���}��
	if ($isAbone) {
		$common = "onclick=\"DoSubmit('thread.del','FUNC'";
		$Page->Print("<tr><td colspan=2 align=right>");
		$Page->Print("<input type=button value=\"�@�����@\" $common,'REPARE')\"> ");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table></dl><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X�폜�m�F�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	dat�ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintResReapre
{
	my ($Page, $Sys, $Form, $Dat, $mode) = @_;
	my (@resSet, @elem, $pRes, $num, $common, $isAbone);
	
	$Sys->Set('_TITLE', 'Res Delete Confirm');
	
	# �I�����X���擾
	@resSet = $Form->GetAtArray('DEL_RESS');
	
	# �����擾
	$isAbone = $Sys->Get('ADMIN')->{'SECINFO'}->IsAuthority($Sys->Get('ADMIN')->{'USER'}, 12, $Sys->Get('BBS'));
	
	$Page->Print("<center><dl><table border=0 cellspacing=2 width=100%>");
	$Page->Print("<tr><td>�ȉ��̍폜���X�����ɖ߂��܂��B</td></tr>\n");
	$Page->Print("<tr><td><hr></td></tr>\n");
	$Page->Print("<tr><td class=\"DetailTitle\">Contents</td></tr>\n");
	
	# ���X�ꗗ���o��
	foreach $num (@resSet) {
		$pRes	= $Dat->Get($num);
		@elem	= split(/<>/, $$pRes);
		
		$Page->Print("<tr><td class=\"Response\"><dt>" . ($num + 1));
		$Page->Print("�F<font color=forestgreen><b>$elem[0]</b></font>[$elem[1]]");
		$Page->Print("�F$elem[2]</dt><dd>$elem[3]<br><br></dd></td></tr>\n");
		$Page->HTMLInput('hidden', 'RESS', $num);
	}
	$Page->Print("<tr><td><hr></td></tr>\n");
	
	# �V�X�e�������L���ɂ��\���}��
	if ($isAbone) {
		$common = "onclick=\"DoSubmit('thread.res','FUNC','";
		$common .= ($mode ? 'ABONE' : 'DELETE') . "')\"";
		$Page->Print("<tr><td align=right>");
		$Page->Print("<input type=button value=\"�@���s�@\" $common> ");
		$Page->Print("</td></tr>\n");
	}
	$Page->Print("</table></dl><br>");
}

#------------------------------------------------------------------------------------------------------------
#
#	������ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintComplete
{
	my ($Page, $Sys, $Form, $pLog) = @_;
	my ($text);
	
	$Sys->Set('_TITLE', 'Process Complete');
	
	$Page->Print("<center><table border=0 cellspacing=0 width=100%>");
	$Page->Print("<tr><td><b>���X�ݒ�𐳏�Ɋ������܂����B</b><br><br>");
	$Page->Print("<small>�������O<hr><blockquote>");
	
	# ���O�̕\��
	foreach $text (@$pLog) {
		$Page->Print("$text<br>\n");
	}
	
	$Page->Print("</blockquote><hr></small></td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	�y�[�W�R���e�L�X�g
#	@param	$SYS	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintError
{
	my ($Page, $Sys, $Form, $pLog) = @_;
	my ($ecode);
	
	$Sys->Set('_TITLE', 'Process Error');
	
	# �G���[�R�[�h�̒��o
	$ecode = pop @$pLog;
	
	$Page->Print("<center><table border=0 cellspacing=0 width=100%>");
	$Page->Print("<tr><td><br><font color=red><b>");
	$Page->Print("ERROR:$ecode<hr><blockquote>\n");
	
	if ($ecode == 1000) {
		$Page->Print("���X��������s���錠��������܂���B");
	}
	elsif ($ecode == 1001) {
		$Page->Print("���͕K�{���ڂ��󗓂ɂȂ��Ă��܂��B");
	}
	else {
		$Page->Print("�s���ȃG���[<hr>");
		foreach (@$pLog) {
			$Page->Print("$_<br>");
		}
	}
	
	$Page->Print("</blockquote><hr></b></font>");
	$Page->Print("</td></tr></table>");
}

#------------------------------------------------------------------------------------------------------------
#
#	���X����
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Dat	Dat�ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionResRepare
{
	my ($Sys, $Form, $Dat, $pLog) = @_;
	my (@resSet, $pRes, $abone, $path, $tm, $user, $delCnt, $num);
	
	# �����`�F�b�N
	{
		my $SEC	= $Sys->Get('ADMIN')->{'SECINFO'};
		my $chkID	= $Sys->Get('ADMIN')->{'USER'};
		
		if (($SEC->IsAuthority($chkID, 12, $Sys->Get('BBS'))) == 0) {
			return 1000;
		}
	}
	
	# �e�l��ݒ�
	@resSet	= $Form->GetAtArray('RESS');
	$path	= $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log/del_' . $Sys->Get('KEY') . '.cgi';
	$tm		= time;
	$user	= $Form->Get('UserName');
	$delCnt	= 0;
	
=pod
	# �폜�Ɠ����ɍ폜���O�֍폜�������e��ۑ�����
	open(DELLOG, '>>', $path);
	flock(DELLOG, 2);
	foreach $num (@resSet){
		$pRes = $Dat->Get($num - $delCnt);
		print DELLOG "$tm<>$user<>$num<>$$pRes";
		if ($mode){
			$Dat->Set($num, "$abone<>$abone<>$abone<>$abone<>$abone\n");
		}
		else {
			$Dat->Delete($num - $delCnt);
			$delCnt ++;
		}
	}
	close(DELLOG);
	
	# �ۑ�
	#$Dat->Save($Sys);
=cut
	
	# ���O�̐ݒ�
	$delCnt = 0;
	$abone	= '';
	push @$pLog, '�ȉ��̃��X�𕜊����܂����B';
	foreach (@resSet) {
		if ($delCnt > 5) {
			push @$pLog, $abone;
			$abone = '';
			$delCnt = 0;
		}
		else {
			$abone .= ($_ + 1) . ', ';
			$delCnt++;
		}
	}
	push @$pLog, $abone;
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����̉��
#	-------------------------------------------------------------------------------------
#	@param	$format	����������
#	@param	$Dat	ARAGORN�I�u�W�F�N�g
#	@return	(�J�n�ԍ�, �I���ԍ�)
#
#------------------------------------------------------------------------------------------------------------
sub AnalyzeFormat
{
	my ($format, $Dat) = @_;
	my ($start, $end, $max);
	
	# �����G���[
	if ($format =~ /[^0-9\-l]/ || $format eq '') {
		return (0, 0);
	}
	$max = $Dat->Size();
	if ($max < 1) {
		return (0, 0);
	}
	
	# �ŐVn��
	if ($format =~ /l(\d+)/) {
		$end	= $max;
		$start	= ($max - $1 + 1) > 0 ? ($max - $1 + 1) : 1;
	}
	# n�`m
	elsif ($format =~ /(\d+)-(\d+)/) {
		$start	= $1 > $max ? $max : $1;
		$end	= $2 > $max ? $max : $2;
	}
	# n�ȍ~���ׂ�
	elsif ($format =~ /(\d+)-/) {
		$start	= $1 > $max ? $max : $1;
		$end	= $max;
	}
	# n�ȑO���ׂ�
	elsif ($format =~ /-(\d+)/) {
		$start	= 1;
		$end	= $1 > $max ? $max : $1;
	}
	# n�̂�
	elsif ($format =~ /(\d+)/) {
		$start	= $1 > $max ? $max : $1;
		$end	= $1 > $max ? $max : $1;
	}
	
	# �������K��
	if ($start > $end) {
		$max = $start;
		$start = $end;
		$end = $start;
	}
	
	return ($start - 1, $end);
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

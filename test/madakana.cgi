#!/usr/bin/perl
#============================================================================================================
#
#	�K���ꗗ�\���pCGI
#	madakana.cgi
#	---------------------------------------------------------------------------
#	2011.03.18 start
#	2011.03.31 remake
#
#============================================================================================================

use strict;
use warnings;
#use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
no warnings 'once';

BEGIN { use lib './perllib'; }

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(MADAKANA());

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub MADAKANA
{
	
	my ( %SYS, $Page, $err );
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# �������ɐ�����������e��\��
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		
		# �w�b�_�\��
		PrintMadaHead(\%SYS, $Page);
		
		# ���e�\��
		PrintMadaCont(\%SYS, $Page);
		
		# �t�b�^�\��
		PrintMadaFoot(\%SYS, $Page);
		
	}
	else {
		PrintMadaError(\%SYS, $Page, $err);
	}
	
	$Page->Flush(0, 0, '');
	
	return $err;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi�������E�O����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($pSYS, $Page) = @_;
	my (@elem, @regs, $path);
	my ($oSYS, $oCONV);
	
	require './module/melkor.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	$oSYS	= new MELKOR;
	$oCONV	= new GALADRIEL;
	
	%$pSYS = (
		'SYS'	=> $oSYS,
		'CONV'	=> $oCONV,
		'PAGE'	=> $Page,
		'CODE'	=> 'Shift_JIS',
	);
	
	$pSYS->{'FORM'} = SAMWISE->new($oSYS->Get('BBSGET')),
	
	# �V�X�e��������
	$oSYS->Init();
	
	
	# �����L�����
	$oSYS->{'MainCGI'} = $pSYS;
	
	# �z�X�g���ݒ�(DNS�t����)
	$ENV{'REMOTE_HOST'} = $oCONV->GetRemoteHost() unless ($ENV{'REMOTE_HOST'});
	$pSYS->{'FORM'}->Set('HOST', $ENV{'REMOTE_HOST'});
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi�w�b�_�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaHead
{
	my ($Sys, $Page) = @_;
	my ($Caption, $Banner, $code, $HOST, $ADDR);
	
	require './module/legolas.pl';
	require './module/denethor.pl';
	$Caption = new LEGOLAS;
	$Banner = new DENETHOR;
	
	$Caption->Load($Sys->{'SYS'}, 'META');
	$Banner->Load($Sys->{'SYS'});
	
	$code	= $Sys->{'CODE'};
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=$code">
 <meta http-equiv="Content-Style-Type" content="text/css">
 <meta http-equiv="imagetoolbar" content="no">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>�܂����ȁA�܂�����</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n<body>\n");
	
	# �o�i�[�o��
	$Banner->Print($Page, 100, 2, 0) if ($Sys->{'SYS'}->Get('BANNER'));
	
	$Page->Print(<<HTML);
<div style="color:navy;">
<h1 style="font-size:1em;font-weight:normal;margin:0;">�܂����ȁA�܂����ȁA�܂Ȃ���(�K���ꗗ�\\)</h1>
<p style="margin:0;">
���Ȃ��̃����z[<span style="color:red;font-weight:bold;">$HOST</span>]
</p>
<p>
by <font color="green">���낿���˂�v���X ��</font>
</p>
<p>
##############################################################################<br>
# ��������<br>
</p>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi���e�o��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaCont
{
	my ($Sys, $Page) = @_;
	my ($BBS, $vUser, $HOST, $ADDR, $BBSpath, @BBSkey, %BBSs, $path, $check, $line, $color );
	
	require './module/nazguls.pl';
	$BBS	= new NAZGUL;
	$BBS->Load($Sys->{'SYS'});
	
	require './module/faramir.pl';
	$vUser = FARAMIR->new;
	
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	$BBSpath	= $Sys->{'SYS'}->Get('BBSPATH');
	
	#$sys->Set('HITS', $line);
	# BBS�Z�b�g�̎擾
	$BBS->GetKeySet('ALL', '', \@BBSkey);
	
	# �n�b�V���ɋl�ߍ���
	foreach my $id (@BBSkey) {
		$BBSs{$BBS->Get('DIR', $id)} = $BBS->Get('NAME', $id);
	}
	
	foreach my $dir ( keys %BBSs ) {
		
		# �f�B���N�g����.0ch_hidden�Ƃ����t�@�C��������Γǂݔ�΂�
		next if ( -e "$BBSpath/$dir/.0ch_hidden" );
		
		$Sys->{'SYS'}->Set('BBS', $dir);
		$vUser->Load($Sys->{'SYS'});
		$check = $vUser->Check($HOST, $ADDR);
		
		$color = "red";
		
		$Page->Print('<p>'."\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		$Page->Print("# <a href=\"$BBSpath/$dir/\">$BBSs{$dir}</a> [ $dir ]<br>\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		
		$path = "$BBSpath/$dir/info/access.cgi";
		
		if ( -e $path && open(SEC, '<', $path) ) {
			flock(FILE, 1);
			
			$line = <SEC>;
			chomp $line;
			my ( $type, $method ) = split(/<>/, $line, 2);
			
			if ( $type eq 'enable' ) {
				$Page->Print('<font color="red">�����̔͈ȉ��̃��[�U�[�̂ݏ������݂��s�����Ƃ��ł��܂��B</font><br>'."\n");
				$color = "blue";
			}
			
			while ( <SEC> ) {
				next if( $_ =~ /(?:disable|enable)<>(?:disable|host)\n/ );
				chomp;
				if ( $Sys->{'SYS'}->Get('HITS') eq $_ ) {
					$_ = '<font color="'.$color.'"><b>'.$_.'</b></font>';
				}
				$_ .= "\n";
				s/\n/<br>/g;
				s/(http:\/\/.*)<br>/<a href="$1" target="_blank">$1<\/a><br>/g;
				$Page->Print($_."\n");
			}
			close(SEC);
		}
		else {
			$Page->Print('<span style="color:#AAA">Cannot open access.cgi.</span><br>'."\n");
		}
		
		$Page->Print('</p>'."\n");
		
	}
	

	
}

sub PrintMadaFoot
{
	my ($Sys, $Page) = @_;
	my ($ver, $cgipath);
	
	$ver		= $Sys->{'SYS'}->Get('VERSION');
	$cgipath	= $Sys->{'SYS'}->Get('CGIPATH');
	
	$Page->Print(<<HTML);
<p>
# �����܂�<br>
##############################################################################<br>
</p>
</div>

<hr>

<div>
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">���낿���˂�</a> <a href="http://zerochplus.sourceforge.jp/">�v���X</a>
MADAKANA.CGI - $ver
</div>

</body>
</html>
HTML

}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi�G���[�\��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaError
{
	my ($Sys, $Page, $err) = @_;
	my ($code);
	
	$code = 'Shift_JIS';
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>�d�q�q�n�q�I�I</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}



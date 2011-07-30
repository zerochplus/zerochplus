#============================================================================================================
#
#	�G���[���Ǘ����W���[��(ORALD)
#	orald.pl
#	---------------------------------------
#	2003.02.05 start
#------------------------------------------------------------------------------------------------------------
#
#	Load																			; �G���[���ǂݍ���
#	Get																				; �G���[���擾
#	Print																			; �G���[�y�[�W�o��(read)
#
#============================================================================================================
package	ORALD;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	���W���[���R���X�g���N�^ - new
#	-------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj);
	
	$obj = {
		'SUBJECT' => undef,
		'MESSAGE' => undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���ǂݍ��� - Load
#	-------------------------------------------
#	���@���F$M : MELKOR
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($M) = @_;
	my (@readBuff, $path, $err, $subj, $msg, @elem);
	
	undef %{$this->{'ERR'}};
	$path = '.' . $M->Get('INFO') . '/errmsg.cgi';
	
	if (-e $path) {				# �t�@�C�������݂����
		open ERR, "< $path";	# �t�@�C���I�[�v��
		@readBuff = <ERR>;
		close ERR;
		
		foreach (@readBuff) {
			# '#' �̓R�����g�s�Ȃ̂œǂ܂Ȃ�
			unless	(/^#.*/) {
				chomp $_;
				@elem = split(/<>/, $_);
				$this->{'SUBJECT'}->{$elem[0]} = $elem[1];
				$this->{'MESSAGE'}->{$elem[0]} = $elem[2];
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���擾 - Get
#	-------------------------------------------
#	���@���F$err : �G���[�ԍ�
#	�߂�l�F($subj,$msg)
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($err, $kind) = @_;
	my ($val);
	
	$val = $this->{$kind}->{$err};
	
	return $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�y�[�W�o�� - PrintBBS
#	-------------------------------------------
#	���@���F$T,$M,$S : THORIN,MELKOR
#			$err     : �G���[�ԍ�
#			$f       : ���[�h(1:�g�їp,0:PC�p)
#	�߂�l�F�Ȃ�
#
#	2010.08.13 windyakin ��
#	 -> ID���������ɂ��ύX
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($Sys, $Page, $err, $mode) = @_;
	my ($Form, $SYS, $version, $bbsPath, $message, $koyuu);
	
	$Form		= $Sys->{'FORM'};
	$SYS		= $Sys->{'SYS'};
	$version	= $SYS->Get('VERSION');
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	$message	= $this->{'MESSAGE'}->{$err};
	$message	=~ s/\x5cn/\n/g;
	$mode		= '0' if (! defined $mode);
	$mode		= 'O' if ($Form->Equal('mb', 'on'));
	
	# �G���[���b�Z�[�W�̒u��
	while ($message =~ /{!(.*?)!}/) {
		my $rep = $SYS->Get($1, '');
		$message =~ s/{!$1!}/$rep/;
	}
	
	# �����[�g�z�X�g�̎擾
	$koyuu = $SYS->Get('KOYUU');
	
	# �G���[���O��ۑ�
	{
		require './module/peregrin.pl';
		my $P = PEREGRIN->new;
		$P->Load($SYS, 'ERR', '');
		$P->Set('', $err, $version, $koyuu, $mode);
		$P->Save($SYS);
	}
	
	if ($mode eq 'O') {
		my $subject = $this->{'SUBJECT'}->{$err};
		$Page->Print("Content-type: text/html\n\n<html><head><title>");
		$Page->Print("�d�q�q�n�q�I</title></head><!--nobanner-->\n");
		$Page->Print("<body><font color=red>ERROR:$subject</font><hr>");
		$Page->Print("$message<hr><a href=\"$bbsPath/i/\">������</a>");
		$Page->Print("����߂��Ă�������</body></html>");
	}
	else {
		my $COOKIE = $Sys->{'COOKIE'};
		my $oSET = $Sys->{'SET'};
		my ($name, $mail, $msg);
		
		$name = $Form->Get('NAME');
		$mail = $Form->Get('MAIL');
		$msg = $Form->Get('MESSAGE');
		
		# cookie���̏o��
		$COOKIE->Set('NAME', $name) if ($oSET->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$COOKIE->Set('MAIL', $mail) if ($oSET->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$COOKIE->Out($Page, $oSET->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print(<<HTML) if ($err < 505 || $err > 508);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
 
 <title>�d�q�q�n�q�I</title>
 
</head>
<!--nobanner-->
<body>
<!-- 2ch_X:error -->
<div style="margin-bottom:2em;">
<font size="+1" color="#FF0000"><b>�d�q�q�n�q�F$message</b></font>
</div>

<blockquote>
�z�X�g<b>$koyuu</b><br>
<br>
���O�F <b>$name</b><br>
E-mail�F $mail<br>
���e�F<br>
$msg
<br>
<br>
</blockquote>
<hr>
<div class="reload">������Ń����[�h���Ă��������B<a href="$bbsPath/">&nbsp;GO!</a></div>
<div align="right">$version</div>
</body>
</html>
HTML
		
		if ($err >= 505 && $err <= 508) {
			my $sambaerr = {
				'505' => '593',
				'506' => '599',
				'507' => '594',
				'508' => '594',
			}->{$err};
			
			$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

	<meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">

	<title>�d�q�q�n�q�I</title>

</head>
<!--nobanner-->
<body>
<!-- 2ch_X:error -->

<div>
�d�q�q�n�q - $sambaerr $message
<br>
</div>

<hr>

<div>(Samba24-2.13�݊�)</div>

<div align="right">$version</div>

</body>
</html>
HTML
		}
		
	}
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

#============================================================================================================
#
#	�G���[���Ǘ����W���[��
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
	
	my $obj = {
		'SUBJECT'	=> undef,
		'MESSAGE'	=> undef,
		'ERR'		=> undef,
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���ǂݍ��� - Load
#	-------------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'ERR'} = undef;
	
	my $path = '.' . $Sys->Get('INFO') . '/errmsg.cgi';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			next if ($_ eq '' || $_ =~ /^#/);
			
			my @elem = split(/<>/, $_, -1);
			if (scalar(@elem) < 3) {
				warn "invalid line in $path";
				next;
			}
			
			my $id = $elem[0];
			$this->{'SUBJECT'}->{$id} = $elem[1];
			$this->{'MESSAGE'}->{$id} = $elem[2];
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���擾 - Get
#	-------------------------------------------
#	���@���F$err  : �G���[�ԍ�
#			$kind : ���
#	�߂�l�F�G���[���
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($err, $kind) = @_;
	
	my $val = $this->{$kind}->{$err};
	
	return $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[�y�[�W�o�� - PrintBBS
#	-------------------------------------------
#	���@���F$CGI  : 
#			$Page : THORIN
#			$err  : �G���[�ԍ�
#			$mode : �G�[�W�F���g
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($CGI, $Page, $err, $mode) = @_;
	
	my $Form = $CGI->{'FORM'};
	my $Sys = $CGI->{'SYS'};
	my $version = $Sys->Get('VERSION');
	my $bbsPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	my $message = $this->{'MESSAGE'}->{$err};
	
	# �G���[���b�Z�[�W�̒u��
	$message =~ s/\\n/\n/g;
	$message =~ s/{!(.*?)!}/$Sys->Get($1, '')/ge;
	
	# �����[�g�z�X�g�̎擾
	my $koyuu = $Sys->Get('KOYUU');
	$mode = '0' if (! defined $mode);
	$mode = 'O' if ($Form->Equal('mb', 'on'));
	
	# �G���[���O��ۑ�
	require './module/peregrin.pl';
	my $Log = PEREGRIN->new;
	$Log->Load($Sys, 'ERR', '');
	$Log->Set('', $err, $version, $koyuu, $mode);
	$Log->Save($Sys);
	
	if ($mode eq 'O') {
		my $subject = $this->{'SUBJECT'}->{$err};
		$Page->Print("Content-type: text/html\n\n<html><head><title>");
		$Page->Print("�d�q�q�n�q�I</title></head><!--nobanner-->\n");
		$Page->Print("<body><font color=red>ERROR:$subject</font><hr>");
		$Page->Print("$message<hr><a href=\"$bbsPath/i/\">������</a>");
		$Page->Print("����߂��Ă�������</body></html>");
	}
	else {
		my $Cookie = $CGI->{'COOKIE'};
		my $Set = $CGI->{'SET'};
		
		my $name = $Form->Get('NAME');
		my $mail = $Form->Get('MAIL');
		my $msg = $Form->Get('MESSAGE');
		
		# cookie���̏o��
		$Cookie->Set('NAME', $name) if ($Set->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$Cookie->Set('MAIL', $mail) if ($Set->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$Cookie->Out($Page, $Set->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
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

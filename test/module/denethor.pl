#============================================================================================================
#
#	�o�i�[�Ǘ����W���[��
#
#============================================================================================================
package	DENETHOR;

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
	my $class = shift;
	
	my $obj = {
		'TEXTPC'	=> undef,	# PC�p�e�L�X�g
		'TEXTSB'	=> undef,	# �T�u�o�i�[�e�L�X�g
		'TEXTMB'	=> undef,	# �g�їp�e�L�X�g
		'COLPC'		=> undef,	# PC�p�w�i�F
		'COLMB'		=> undef,	# �g�їp�w�i�F
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�i�[���ǂݍ��� - Load
#	-------------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F����:0,���s:-1
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'TEXTPC'} = '<tr><td>�Ȃ�قǍ��m������ˁ[��</td></tr>';
	$this->{'TEXTSB'} = '';
	$this->{'TEXTMB'} = '<tr><td>�Ȃ�قǍ��m������ˁ[��</td></tr>';
	$this->{'COLPC'} = '#ccffcc';
	$this->{'COLMB'} = '#ccffcc';
	
	my $path = '.' . $Sys->Get('INFO');
	
	# PC�p�ǂݍ���
	if (open(my $fh, '<', "$path/bannerpc.cgi")) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		$_ = shift @lines;
		$_ =~ s/[\r\n]+\z//;
		$this->{'COLPC'} = $_;
		$this->{'TEXTPC'} = join '', @lines;
	}
	
	# �T�u�o�i�[�ǂݍ���
	if (open(my $fh, '<', "$path/bannersub.cgi")) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		$this->{'TEXTSB'} = join '', @lines;
	}
	
	# �g�їp�ǂݍ���
	if (open(my $fh, '<', "$path/bannermb.cgi")) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		$_ = shift @lines;
		$_ =~ s/[\r\n]+\z//;
		$this->{'COLMB'} = $_;
		$this->{'TEXTMB'} = join '', @lines;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�i�[��񏑂����� - Save
#	-------------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my @file = ();
	$file[0] = '.' . $Sys->Get('INFO') . '/bannerpc.cgi';
	$file[1] = '.' . $Sys->Get('INFO') . '/bannermb.cgi';
	$file[2] = '.' . $Sys->Get('INFO') . '/bannersub.cgi';
	
	# PC�p��������
	chmod($Sys->Get('PM-ADM'), $file[0]);
	if (open(my $fh, (-f $file[0] ? '+<' : '>'), $file[0])) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		print $fh $this->{'COLPC'} . "\n";
		print $fh $this->{'TEXTPC'};
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $file[0]);
	
	# �T�u�o�i�[��������
	chmod($Sys->Get('PM-ADM'), $file[2]);
	if (open(my $fh, (-f $file[2] ? '+<' : '>'), $file[2])) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		print $fh $this->{'TEXTSB'};
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $file[2]);
	
	# �g�їp��������
	chmod($Sys->Get('PM-ADM'), $file[1]);
	if (open(my $fh, (-f $file[1] ? '+<' : '>'), $file[1])) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		print $fh $this->{'COLMB'} . "\n";
		print $fh $this->{'TEXTMB'};
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $file[1]);
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�i�[���ݒ� - Set
#	-------------------------------------------
#	���@���F$key : �ݒ�L�[
#			$val : �ݒ�l
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $val) = @_;
	
	$this->{$key} = $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�i�[���擾 - Get
#	-------------------------------------------
#	���@���F$key : �擾�L�[
#			$default : �f�t�H���g
#	�߂�l�F�擾�l
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	
	my $val = $this->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�i�[�o�� - Print
#	-------------------------------------------
#	���@���F$width : �o�i�[��(%)
#			$f     : ��؂�\���t���O
#			$mode  : ���[�h(PC/�g��)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Prepare
{
	my $this = shift;
	my ($width, $f, $mode) = @_;
	
	my $data = {
		'tmpl'		=> ($mode ? 'mobile' : 'pc'),
		'width'		=> $width,
		'beforehr'	=> $f & 1,
		'afterhr'	=> $f & 2,
		'textpc'	=> $this->{'TEXTPC'},
		'textmb'	=> $this->{'TEXTMB'},
		'colorpc'	=> $this->{'COLPC'},
		'colormb'	=> $this->{'COLMB'},
	};
	
	return $data;
}

sub Print
{
	my $this = shift;
	my ($Page, $width, $f, $mode) = @_;
	
	# ���؂�
	$Page->Print('<hr>') if ($f & 1);
	
	# �g�їp�o�i�[�\��
	if ($mode) {
		$Page->Print('<table border width="100%" ');
		$Page->Print("bgcolor=$this->{'COLMB'}>");
		$Page->Print("$this->{'TEXTMB'}</table>\n");
	}
	# PC�p�o�i�[�\��
	else {
		$Page->Print("<table border=\"1\" cellspacing=\"7\" cellpadding=\"3\" width=\"$width%\"");
		$Page->Print(" bgcolor=\"$this->{'COLPC'}\" align=\"center\">\n");
		$Page->Print("$this->{'TEXTPC'}\n</table>\n");
	}
	
	# ����؂�
	$Page->Print("<hr>\n\n") if ($f & 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	�T�u�o�i�[�o�� - PrintSub
#	-------------------------------------------
#	�߂�l�F�o�i�[�o�͂�����1,���̑���0
#
#------------------------------------------------------------------------------------------------------------
sub PrepareSub
{
	my $this = shift;
	
	my $data = {
		'tmpl'		=> 'sub',
		'textsub'	=> $this->{'TEXTSB'},
	};
	
	return $data;
}

sub PrintSub
{
	my $this = shift;
	my ($Page) = @_;
	
	# �T�u�o�i�[�����݂�����\������
	if ($this->{'TEXTSB'} ne '') {
		$Page->Print("<div style=\"margin-bottom:1.2em;\">\n");
		$Page->Print("$this->{'TEXTSB'}\n");
		$Page->Print("</div>\n");
		return 1;
	}
	return 0;
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

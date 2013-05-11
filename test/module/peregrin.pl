#============================================================================================================
#
#	�Ǘ����O�f�[�^�Ǘ����W���[��
#
#============================================================================================================
package	PEREGRIN;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	���W���[���R���X�g���N�^ - new
#	-------------------------------------------
#	���@���F
#	�߂�l�F���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	
	my $obj = {
		'LOG'	=> undef,
		'PATH'	=> undef,
		'FILE'	=> undef,
		'MAX'	=> undef,
		'MAXA'	=> undef,
		'MAXH'	=> undef,
		'MAXS'	=> undef,
		'KIND'	=> undef,
		'NUM'	=> undef,
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�ǂݍ��� - Load
#	------------------------------------------------
#	���@���F$Sys : MELKOR
#			$log : ���O���
#			$key : �X���b�h�L�[(�������݂̏ꍇ�̂�)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys, $log, $key) = @_;
	
	$this->{'LOG'} = [];
	$this->{'PATH'}	= '';
	$this->{'FILE'}	= '';
	$this->{'KIND'}	= 0;
	$this->{'MAX'}	= $Sys->Get('ERRMAX');
	$this->{'MAXA'}	= $Sys->Get('ADMMAX');
	$this->{'MAXH'}	= $Sys->Get('HISMAX');
	$this->{'MAXS'}	= $Sys->Get('SUBMAX');
	$this->{'NUM'}	= 0;
	
	my $file = '';
	my $kind = 0;
	if ($log eq 'ERR') { $file = 'errs.cgi';	$kind = 1; }	# �G���[���O
	if ($log eq 'THR') { $file = 'IP.cgi';		$kind = 2; }	# �X���b�h�쐬���O
	if ($log eq 'WRT') { $file = "$key.cgi";	$kind = 3; }	# �������݃��O
	if ($log eq 'HST') { $file = "HOST.cgi";	$kind = 5; }	# �z�X�g���O
	if ($log eq 'SMB') { $file = "samba.cgi";	$kind = 6; }	# Samba���O
	if ($log eq 'SBH') { $file = "houshi.cgi";	$kind = 7; }	# Samba�K�����O
	
	$this->{'KIND'} = $kind;
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/log';
	
	if ($kind) {
		if (open(my $fh, '<', "$path/$file")) {
			flock($fh, 2);
			my @lines = <$fh>;
			close($fh);
			push @{$this->{'LOG'}}, @lines;
			$this->{'NUM'} = scalar(@lines);
		}
		$this->{'PATH'} = $path;
		$this->{'FILE'} = $file;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���O�������� - SaveError
#	-------------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = "$this->{'PATH'}/$this->{'FILE'}";
	
	if ($this->{'KIND'}) {
		if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
			flock($fh, 2);
			seek($fh, 0, 0);
			print $fh @{$this->{'LOG'}};
			truncate($fh, tell($fh));
			close $fh;
		}
		chmod($Sys->Get('PM-LOG'), $path);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�ǉ� - Set
#	-------------------------------------------
#	���@���F$I     : ISILDUR
#			$data1 : �ėp�f�[�^1
#			$data2 : �ėp�f�[�^2
#			$koyuu : �[���ŗL���ʎq
#			$data  : DAT�`���̃��O
#			$mode  : ID������
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($I, $data1, $data2, $koyuu, $data, $mode) = @_;
	
	$mode = '0' if (! defined $mode);
	
	my $host = $ENV{'REMOTE_HOST'};
	if ($mode ne '0') {
		if ($mode eq 'P') {
			$host = "$host($koyuu)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$host($koyuu)";
		}
	}
	
	# �ǂݍ��ݍς�
	my $kind = $this->{'KIND'};
	if ($kind) {
		my $tm = time;
		my $work = '';
		
		if ($kind == 3) {
			my @logdat = split(/<>/, $data, -1);
			
			$work = join('<>',
				$logdat[0],
				$logdat[1],
				$logdat[2],
				substr($logdat[3], 0, 30),
				$logdat[4],
				$host,
				$ENV{'REMOTE_ADDR'},
				$data1,
				$ENV{'HTTP_USER_AGENT'}
			);
			
		}
		else {
			$work = join('<>',
				$tm,
				$data1,
				$data2,
				$host
			);
		}
		
		my $log = $this->{'LOG'};
		# �����֒ǉ�
		push @$log, "$work\n";
		my $nm = ++$this->{'NUM'};
		
		my $bf = 0;
		if ($kind == 1) { $bf = $nm - $this->{'MAX'}; }			# �G���[���O
		if ($kind == 2) { $bf = $nm - $this->{'MAXS'}; }		# �X���b�h���O
	#	if ($kind == 3) { $bf = $nm - $I->Get('timecount'); }	# �������݃��O
		if ($kind == 6) { $bf = $nm - $this->{'MAX'}; }			# samba
		if ($kind == 7) { $bf = $nm - $this->{'MAX'}; }			# houshi
		
		# �擪���O�̍폜
		splice @$log, 0, $bf;
		$this->{'NUM'} = scalar(@$log);
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�擾 - Get
#	-------------------------------------------
#	���@���F$ln : ���O�ԍ�
#	�߂�l�F@data
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($ln) = @_;
	
	if ($ln >= 0 && $ln < $this->{'NUM'}) {
		my $work = $this->{'LOG'}->[$ln];
		$work =~ s/[\r\n]+\z//;
		my @data = split(/<>/, $work, -1);
		
		return @data;
	}
	else {
		return undef;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���O���擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���X��
#
#------------------------------------------------------------------------------------------------------------
sub Size
{
	my $this = shift;
	
	return $this->{'NUM'};
}

#------------------------------------------------------------------------------------------------------------
#
#	���O���� - Search
#	-------------------------------------------
#	���@���F$data  : �T�[�`�L�[
#			$f     : �T�[�`���[�h
#			$mode  : �G�[�W�F���g
#			$host  : �����[�g�z�X�g
#			$count : ������
#	�߂�l�F�e��f�[�^
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my $this = shift;
	my ($data, $f, $mode, $host, $count) = @_;
	
	my $kind = $this->{'KIND'};
	
	# data1�Ō���
	if ($f == 1) {
		my $max = scalar(@{$this->{'LOG'}}) - 1;
		for my $i (reverse(0 .. $max)) {
			my $log = $this->{'LOG'}->[$i];
			$log =~ s/[\r\n]+\z//;
			
			my ($key, $val) = (split /<>/, $log, -1)[$kind == 3 ? (5, 7) : (1, 3)];
			$key = $1 if ($key =~ /\((.*)\)/);
			if ($data eq $key) {
				return $val;
			}
		}
	}
	else {
		if ($mode ne '0') {
			if ($mode eq 'P') {
				$host = "$host($data)$ENV{'REMOTE_ADDR'}";
			}
			else {
				$host = "$host($data)";
			}
		}
		
		# host�o����
		if ($f == 2) {
			my $num = 0;
			my $max = scalar(@{$this->{'LOG'}}) - 1;
			$count = $max + 1 if (!defined $count);
			my $min = 1 + $max - $count;
			$min = 0 if ($min < 0);
			
			for my $i (reverse($min .. $max)) {
				my $log = $this->{'LOG'}->[$i];
				$log =~ s/[\r\n]+\z//;
				
				my $key = (split /<>/, $log, -1)[$kind == 3 ? 5 : $kind == 5 ? 1 : 3];
				$key = $1 if ($key =~ /\((.*)\)/);
				if ($data eq $key) {
					$num++;
				}
			}
			return $num;
		}
		# THR
		elsif ($f == 3) {
			my $num = 0;
			my $max = scalar(@{$this->{'LOG'}}) - 1;
			$count = $max + 1 if (! defined $count);
			my $min = 1 + $max - $count;
			$min = 0 if ($min < 0);
			
			for my $i (reverse($min .. $max)) {
				my $log = $this->{'LOG'}->[$i];
				$log =~ s/[\r\n]+\z//;
				
				my ($key, $val) = (split /<>/, $log, -1)[1, 3];
				$val = $1 if ($val =~ /\((.*)\)/);
				if ($data eq $val) {
					$num++;
				}
			}
			return $num;
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���Ԕ��� - IsTime
#	-------------------------------------------
#	���@���F$tmn  : ���莞��(�b)
#			$host : �����[�g�z�X�g
#	�߂�l�F���ԓ�:�c��b��,���ԊO:0
#	���@�l�F�ŏI���O����$tmn�b�o�߂������ǂ����𔻒�
#
#------------------------------------------------------------------------------------------------------------
sub IsTime
{
	my $this = shift;
	my ($tmn, $host) = @_;
	
	my $kind = $this->{'KIND'};
	
	return 0 if ($kind == 3);
	
	my $nw = time;
	my $n = scalar(@{$this->{'LOG'}});
	
	for my $i (reverse(0 .. $n - 1)) {
		my $log = $this->{'LOG'}->[$i];
		$log =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $log, -1);
		if ($host eq $val) {
			# �c��b����Ԃ�
			my $rem = $tmn - ($nw - $tm);
			$rem = 0 if ($rem < 0);
			return $rem;
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	Samba���� - IsSamba
#	-------------------------------------------
#	���@���F$sb		: Samba����(�b)
#			$host	: �����[�g�z�X�g
#	�߂�l�F$n		: Samba��
#			$tm		: �K�v�҂�����
#
#------------------------------------------------------------------------------------------------------------
sub IsSamba
{
	my $this = shift;
	my ($sb, $host) = @_;
	
	my $kind = $this->{'KIND'};
	
	return (0, 0) if ($kind != 6);
	
	my $nw = time;
	my $n = scalar(@{$this->{'LOG'}});
	my @iplist = ();
	my $ptm = $nw;
	
	for my $i (reverse(0 .. $n - 1)) {
		my $log = $this->{'LOG'}->[$i];
		$log =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $log, -1);
		
		next if ($host ne $val);
		last if ($sb <= $ptm - $tm);
		
		push @iplist, $tm;
		$ptm = $tm;
	}
	
	$n = scalar(@iplist);
	if ($n) {
		return ($n, ($nw - $iplist[0]));
	}
	
	return (0, 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	��d���������� - IsHoushi
#	-------------------------------------------
#	���@���F$houshi		: ��d��������(��)
#			$host		: �����[�g�z�X�g
#	�߂�l�F$ishoushi	: ��d������
#			$tm			: �K�v�҂�����(��)
#
#------------------------------------------------------------------------------------------------------------
sub IsHoushi
{
	my $this = shift;
	my ($houshi, $host) = @_;
	
	my $kind = $this->{'KIND'};
	
	return (0, 0) if ($kind != 7);
	
	my $nw = time;
	my $n = scalar(@{$this->{'LOG'}});
	
	for my $i (reverse(0 .. $n - 1)) {
		my $log = $this->{'LOG'}->[$i];
		$log =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $log, -1);
		
		next if ($host ne $val);
		
		my $intv = $nw - $tm;
		last if ($houshi * 60 <= $intv);
		
		return (1, $houshi - ($intv - ($intv % 60 || 60)) / 60);
	}
	return (0, 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h���Ă������� - IsTatesugi
#	-------------------------------------------
#	���@���F$hour		: �X���b�h�쐬���K������(����)
#	�߂�l�F$count		: �X���b�h��
#
#------------------------------------------------------------------------------------------------------------
sub IsTatesugi
{
	my $this = shift;
	my ($hour) = @_;
	
	my $kind = $this->{'KIND'};
	
	return 0 if ($kind != 2);
	
	my $nw = time;
	my $n = scalar(@{$this->{'LOG'}});
	my $count = 0;
	
	for my $i (reverse(0 .. $n - 1)) {
		my $log = $this->{'LOG'}->[$i];
		$log =~ s/[\r\n]+\z//;
		
		my $tm = (split(/<>/, $log, -1))[0];
		last if ($hour * 3600 <= $nw - $tm);
		
		$count++;
	}
	return $count;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O1�s�폜 - Delete
#	-------------------------------------------
#	���@���F$num
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($num) = @_;
	
	$this->{'NUM'} -= scalar splice @{$this->{'LOG'}}, $num, 1;
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

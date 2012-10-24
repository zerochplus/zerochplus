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
	   if ($log eq 'ERR') { $file = 'errs.cgi';		$kind = 1; }	# �G���[���O
	elsif ($log eq 'THR') { $file = 'IP.cgi';		$kind = 2; }	# �X���b�h�쐬���O
	elsif ($log eq 'WRT') { $file = "$key.cgi";		$kind = 3; }	# �������݃��O
	elsif ($log eq 'HST') { $file = "HOST.cgi";		$kind = 5; }	# �z�X�g���O
	elsif ($log eq 'SMB') { $file = "samba.cgi";	$kind = 6; }	# Samba���O
	elsif ($log eq 'SBH') { $file = "houshi.cgi";	$kind = 7; }	# Samba�K�����O
	
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
		chmod 0666, $path;
		if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
			flock($fh, 2);
			seek($fh, 0, 0);
			print $fh $_ foreach (@{$this->{'LOG'}});
			truncate($fh, tell($fh));
			close $fh;
		}
		chmod $Sys->Get('PM-LOG'), $path;
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
		elsif ($kind == 2) { $bf = $nm - $this->{'MAXS'}; }			# �X���b�h���O
	#	elsif ($kind == 3) { $bf = $nm - $I->Get('timecount'); }	# �������݃��O
		elsif ($kind == 6) { $bf = $nm - $this->{'MAX'}; }			# samba
		elsif ($kind == 7) { $bf = $nm - $this->{'MAX'}; }			# houshi
		
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
		my $num = @{$this->{'LOG'}};
		for (my $i = $num - 1; $i >= 0; $i--) {
			$_ = $this->{'LOG'}->[$i];
			$_ =~ s/[\r\n]+\z//;
			my ($key, $val) = (split /<>/, $_, -1)[$kind == 3 ? (5, 7) : (1, 3)];
			$key =~ s/^.*?(\(.*\)).*?$/$1/;
			return $val if ($data eq $key);
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
			my $max = scalar(@{$this->{'LOG'}});
			$count = $max if (! defined $count);
			for (my $i = $max - 1; $i >= $max - $count && $i >= 0; $i--) {
				$_ = $this->{'LOG'}->[$i];
				$_ =~ s/[\r\n]+\z//;
				my $key = (split /<>/, $_, -1)[$kind == 3 ? 5 : $kind == 5 ? 1 : 3];
				$key =~ s/^.*?\((.*)\).*?$/$1/;
				$num++ if ($data eq $key);
			}
			return $num;
		}
		# THR
		elsif ($f == 3) {
			my $num = 0;
			my $max = scalar(@{$this->{'LOG'}});
			$count = $max if (! defined $count);
			for (my $i = $max - 1; $i >= $max - $count && $i >= 0; $i--) {
				$_ = $this->{'LOG'}->[$i];
				$_ =~ s/[\r\n]+\z//;
				my ($key, $val) = (split /<>/, $_, -1)[1, 3];
				$key =~ s/^.*?(\(.*\)).*?$/$1/;
				$num++ if ($data eq $val);
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
	
	for (my $i = $n - 1; $i >= 0; $i--) {
		$_ = $this->{'LOG'}->[$i];
		$_ =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $_, -1);
		next if ($host ne $val);
		return (($_ = $tmn - ($nw - $tm)) > 0 ? $_ : 0);	# �c��b����Ԃ�
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
	
	for (my $i = $n - 1, my $j = $nw; $i >= 0; $i--) {
		$_ = $this->{'LOG'}->[$i];
		$_ =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $_, -1);
		next if ($host ne $val);
		if ($sb > $j - $tm) {
			push @iplist, $tm;
			$j = $tm;
		}
		else {
			last;
		}
	}
	
	$n = scalar(@iplist);
	return ($n, ($nw - $iplist[0])) if ($n);
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
	
	for (my $i = $n - 1; $i >= 0; $i--) {
		$_ = $this->{'LOG'}->[$i];
		$_ =~ s/[\r\n]+\z//;
		my ($tm, undef, undef, $val) = split(/<>/, $_, -1);
		next if ($host ne $val);
		if ($houshi * 60 > ($_ = $nw - $tm)) {
			return (1, $houshi - ($_ - ($_ % 60 || 60)) / 60);
		}
		else {
			last;
		}
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
	
	for (my $i = $n - 1; $i >= 0; $i--) {
		$_ = $this->{'LOG'}->[$i];
		$_ =~ s/[\r\n]+\z//;
		my $tm = (split(/<>/, $_, -1))[0];
		if ($hour * 3600 > $nw - $tm) {
			$count++;
		}
		else {
			last;
		}
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

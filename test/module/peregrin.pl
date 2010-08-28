#============================================================================================================
#
#	�Ǘ����O�f�[�^�Ǘ����W���[��(PEREGRIN)
#	peregrin.pl
#	----------------------------------------
#	2003.01.07 start
#	2003.01.22 ���ʃC���^�t�F�C�X�ֈڍs
#	2003.03.06 ���O�������̃G���[��FIX
#	2003.06.25 Add���\�b�h�ǉ�
#
#	���낿���˂�v���X
#	2010.08.13 �ꕔ���O�o�͌`����ύX
#	2010.08.14 �ꕔ���O�o�͌`����ύX
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
	my (@LOG, $PATH, $FILE, $MAX, $MAXA, $MAXH, $KIND, $obj);
	
	$obj = {
		'LOG'	=> \@LOG,
		'PATH'	=> $PATH,
		'FILE'	=> $FILE,
		'MAX'	=> $MAX,
		'MAXA'	=> $MAXA,
		'MAXH'	=> $MAXH,
		'KIND'	=> $KIND,
		'NUM'	=> 0
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f�X�g���N�^ - DESTROY
#	-------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DESTROY
{
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�ǂݍ��� - Load
#	------------------------------------------------
#	���@���F$M   : MELKOR
#			$log : ���O���
#			$key : �X���b�h�L�[(�������݂̏ꍇ�̂�)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($M, $log, $key) = @_;
	my ($path, $file, $kind);
	
	undef @{$this->{'LOG'}};
	$this->{'PATH'}	= '';
	$this->{'FILE'}	= '';
	$this->{'KIND'}	= 0;
	$this->{'MAX'}	= $M->Get('ERRMAX');
	$this->{'MAXA'}	= $M->Get('ADMMAX');
	$this->{'MAXH'}	= $M->Get('HISMAX');
	$this->{'NUM'}	= 0;
	
	$path = $M->Get('BBSPATH') . '/' . $M->Get('BBS') . '/log';		# �f���p�X
	
	if ($log eq 'ERR')		{ $file = 'errs.cgi';	$kind = 1; }	# �G���[���O
	elsif ($log eq 'THR')	{ $file = 'IP.cgi';		$kind = 2; }	# �X���b�h�쐬���O
	elsif ($log eq 'WRT')	{ $file = "$key.cgi";	$kind = 3; }	# �������݃��O
	elsif ($log eq 'HST')	{ $file = "HOSTs.cgi";	$kind = 5; }	# �z�X�g���O
	elsif ($log eq 'SMB')	{ $file = "samba.cgi";	$kind = 6; }	# Samba���O
	elsif ($log eq 'SBH')	{ $file = "houshi.cgi";	$kind = 7; }	# Samba�K�����O
	else {															# �ُ�
		$file = '';
		$kind = 0;
	}
	
	if ($kind) {													# ����ɐݒ�
		if (-e "$path/$file") {
			open LOG, "< $path/$file";
			while (<LOG>) {
				push @{$this->{'LOG'}}, $_;
				$this->{'NUM'}++;
			}
			close LOG;
		}
		$this->{'PATH'} = $path;
		$this->{'FILE'} = $file;
	}
	$this->{'KIND'} = $kind;
}

#------------------------------------------------------------------------------------------------------------
#
#	�G���[���O�������� - SaveError
#	-------------------------------------------
#	���@���F$M : MELKOR
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($M) = @_;
	my ($path, $file);
	
	$path	= $this->{'PATH'};
	$file	= $this->{'FILE'};
	
	if ($this->{'KIND'}) {
#		eval
		{ chmod 0666, "$path/$file"; };				# �p�[�~�b�V�����ݒ�
		if (open LOG, "> $path/$file") {
			flock LOG, 2;
			print LOG @{$this->{'LOG'}};
			close LOG;
		}
#		eval
		{ chmod $M->Get('PM-LOG'), "$path/$file"; };	# �p�[�~�b�V�����ݒ�
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�ǉ� - Set
#	-------------------------------------------
#	���@���F$I     : ISILDUR
#			$data1 : �ėp�f�[�^1
#			$data2 : �ėp�f�[�^2
#			$host  : �����[�g�z�X�g
#			$data  : DAT�`���̃��O
#			$mode  : ID������
#	�߂�l�F�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> �ʏ폑�����݃��O�o�͌`�����Q�����˂�`���֕ύX
#
#	2010.08.14 windyakin ��
#	 -> �g��,p2��HOST�����̃��O�o�͂�ύX
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($I, $data1, $data2, $host, $data, $mode) = @_;
	my ($work, $nm, $tm, $bf, $kind, $tsw, @logdat);
	
	$bf		= 0;
	$nm		= $this->{'NUM'};														# ���O���擾
	$kind	= $this->{'KIND'};
	$tsw	= $ENV{'REMOTE_HOST'};
	$mode	= '0' if (! defined $mode);
	
	if ($mode ne '0') {
		if ($mode eq 'P') {
			$host = "$tsw($host)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$tsw($host)";
		}
	}
	
	if ($kind) {																	# �ǂݍ��ݍς�
		if ($kind == 1 && $nm >= $this->{'MAX'}) { $bf = 1; }						# �G���[���O
		elsif ($kind == 2 && $nm >= $I->Get('BBS_THREAD_TATESUGI')) { $bf = 1; }	# �X���b�h���O
		elsif ($kind == 3 && $nm >= $I->Get('timecount')) { $bf = 1; }				# �������݃��O
		
		$tm = time;
		
		if ($kind eq 3) {
			
			@logdat = split(/<>/, $data, 5);
			
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
			) . "\n";
			
		}
		else {
			$work = join('<>',
				$tm,
				$data1,
				$data2,
				$host
			) . "\n";
		}
		
		push @{$this->{'LOG'}}, $work;												# �����֒ǉ�
		$this->{'NUM'}++;
		
		if ($bf) {																	# ���O�ő�l���z����
			shift @{$this->{'LOG'}};												# �擪���O�̍폜
			$this->{'NUM'}--;
		}
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
	my (@data, $work);
	
	$work = $this->{'LOG'}->[$ln];
	chomp $work;
	@data = split(/<>/, $work);
	
	return @data;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O���� - Search
#	-------------------------------------------
#	���@���F$data : �T�[�`�L�[
#			$f    : �T�[�`���[�h
#	�߂�l�F�������1,�Ȃ����0
#
#	2010.08.13 windyakin ��
#	 -> ���O�ۑ��`���ύX�ɂ��V�X�e���̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my $this = shift;
	my ($data, $f) = @_;
	my ($key, $dmy, $num, $i, $dat, $kind);
	
	$kind = $this->{'KIND'};
	
	if ($f == 1) {												# data1�Ō���
		$num = @{$this->{'LOG'}};
		for ($i = $num - 1 ; $i >= 0 ; $i--) {
			$dmy = $this->{'LOG'}->[$i];
			chomp $dmy;
			($key, $dat) = (split(/<>/, $dmy))[($kind == 3 ? (5, 7) : (1, 3))];
			if ($data eq $key) {
				return $dat;
			}
		}
	}
	elsif ($f == 2) {											# host�o����
		$num = 0;
		$dat = @{$this->{'LOG'}};
		for ($i = $dat - 1;$i >= 0;$i--) {
			$dmy = $this->{'LOG'}->[$i];
			chomp $dmy;
			$key = (split(/<>/, $dmy))[($kind == 3 ? 5 : 3)];
			if ($data eq $key) {
				$num++;
			}
		}
		return $num;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���Ԕ��� - IsTime
#	-------------------------------------------
#	���@���F$tmn : ���莞��(�b)
#	�߂�l�F���ԓ�:�c��b��,���ԊO:0
#	���@�l�F�ŏI���O����$tmn�b�o�߂������ǂ����𔻒�
#
#------------------------------------------------------------------------------------------------------------
sub IsTime
{
	my $this = shift;
	my ($tmn, $host) = @_;
	my ($i, $n, $work, $tm, $nw, $hst, $kind);
	
	$nw = time;
	$n = @{$this->{'LOG'}};
	$kind = $this->{'KIND'};
	
	return 0 if ($kind == 3);
	
	for ($i = $n - 1 ; $i >= 0 ; $i--) {
		($tm, undef, undef, $hst) = split(/<>/, $this->{'LOG'}->[$i]);
		chomp $hst;
		next if ($host ne $hst);
		return (($_ = $tmn - ($nw - $tm)) > 0 ? $_ : 0);	# �c��b����Ԃ�
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	Samba���� - IsSamba
#	-------------------------------------------
#	���@���F$sb			: Samba����(�b)
#			$host		: 
#	�߂�l�F$n			: Samba��
#			$tm			: �K�v�҂�����
#
#------------------------------------------------------------------------------------------------------------
sub IsSamba
{
	my $this = shift;
	my ($sb, $host) = @_;
	my (@iplist, $i, $j, $n, $tm, $nw, $hst, $kind);
	
	$nw = time;
	$n = @{$this->{'LOG'}};
	$kind = $this->{'KIND'};
	
	return (0, 0) if ($kind != 6);
	
	for ($i = $n - 1, $j = $nw ; $i >= 0 ; $i--) {
		($tm, undef, undef, $hst) = split(/<>/, $this->{'LOG'}->[$i]);
		chomp $hst;
		next if ($host ne $hst);
		if ($sb > $j - $tm) {
			push @iplist, $tm;
			$j = $tm;
		}
		else {
			last;
		}
	}
	$n = @iplist;
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
#			$host		: 
#	�߂�l�F$ishoushi	: ��d������
#			$tm			: �K�v�҂�����(��)
#
#------------------------------------------------------------------------------------------------------------
sub IsHoushi
{
	my $this = shift;
	my ($houshi, $host) = @_;
	my (@iplist, $i, $n, $tm, $nw, $hst, $kind);
	
	$nw = time;
	$n = @{$this->{'LOG'}};
	$kind = $this->{'KIND'};
	
	return (0, 0) if ($kind != 7);
	
	for ($i = $n - 1 ; $i >= 0 ; $i--) {
		($tm, undef, undef, $hst) = split(/<>/, $this->{'LOG'}->[$i]);
		chomp $hst;
		next if ($host ne $hst);
		if ($houshi * 60 > ($_ = $nw - $tm)) {
			return (1, $houshi - ($_ - ($_ % 60 || 60)) / 60);
		}
		else {
			return (0, 0);
		}
	}
	return (0, 0);
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;
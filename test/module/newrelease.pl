#============================================================================================================
#
#	�A�b�v�f�[�g�ʒm
#	newrelease.pl
#
#	by ���낿���˂�v���X
#	http://zerochplus.sourceforge.jp/
#
#	---------------------------------------------------------------------------
#
#	2012.08.09 start
#
#============================================================================================================

package ZP_NEWRELEASE;

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
	my ( $obj, %NEWRELEASE );
	
	$obj = {
		'NEWRELEASE'	=> \%NEWRELEASE
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	������ - Init
#	-------------------------------------------------------------------------------------
#	���@���F$sys : MELKOR
#	�߂�l�F0
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ( $sys ) = @_;
	undef $this->{'NEWRELEASE'};
	
	$this->{'NEWRELEASE'} = {
		'CheckURL'	=> 'http://zerochplus.sourceforge.jp/Release.txt',
		'Interval'	=> 60 * 60 * 24, # 24����
		'RawVer'	=> $sys->Get('VERSION'),
		'CachePATH'	=>  '.' . $sys->Get('INFO') . '/Release.cgi',
		'CachePM'	=> $sys->Get('PM-ADM'),
		'Update'	=> 0,
	};
	
}


#------------------------------------------------------------------------------------------------------------
#
#	�X�V�`�F�b�N - Check
#	-------------------------------------------------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F0
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my $this = shift;
	my $hash = $this->{'NEWRELEASE'};
	my ( $url, $interval, $rawver, @ver, $date, $path );
	
	
	$url = $hash->{'CheckURL'};
	$interval = $hash->{'Interval'};
	
	$rawver = $hash->{'RawVer'};
	# 0ch+ BBS n.m.r YYYYMMDD �`���ł��邱�Ƃ�������Ɗ��҂��Ă���
	# �܂��� 0ch+ BBS dev-rREV YYYYMMDD
	if ( $rawver =~ /(\d+(?:\.\d+)+)/ ) {
		@ver = split /\./, $1;
	} elsif ( $rawver =~ /dev-r(\d+)/ ) {
		@ver = ( 'dev', $1 );
	} else {
		@ver = ( 'dev', 0 );
	}
	$date = '00000000';
	if ( $rawver =~ /(\d{8})/ ) {
		$date = $1;
	}
	
	$path = $hash->{'CachePATH'};
	
	
	# �L���b�V���̗L���������߂��Ă���f�[�^���Ƃ��Ă���
	if ( ( stat $path )[9] < time - $interval ) {
		# �����ڑ��h�~�݂�����
		utime ( undef, undef, $path );
		
		require('./module/httpservice.pl');
		
		my $proxy = HTTPSERVICE->new;
		# URL���w��
		$proxy->setURI($url);
		# UserAgent��ݒ�
		$proxy->setAgent($rawver);
		# �^�C���A�E�g��ݒ�
		$proxy->setTimeout(3);
		
		# �Ƃ��Ă����
		$proxy->request();
		
		# �Ƃꂽ
		if ( $proxy->getStatus() eq 200 ) {
			open ( FILE, "> $path" );
			print FILE $proxy->getContent();
			close FILE;
			chmod $hash->{'CachePM'}, $path;
		}
	}
	
	
	# ��r��
	my ( @release, $l, @newver, $newdate, $i, $newrelease, $vv, $nv );
	
	open ( FILE, "< $path" );
	while ( $l = <FILE> ) {
		# $l =~ s/\x0d?\x0a?$//;
		# samwise�Ɠ����̃T�j�^�C�W���O���s���܂�
		$l =~ s/[\x0d\x0a\0]//g;
		$l =~ s/"/&quot;/g;
		$l =~ s/</&lt;/g;
		$l =~ s/>/&gt;/g;

		push @release, $l;
	}
	close FILE;
	# ���e(BOM)����
	$l = shift @release;
	$l =~ s/^\xef\xbb\xbf//;
	unshift @release, $l;
	
	# n.m.r�`���ł��邱�Ƃ����҂��Ă���
	@newver = split /\./, $release[0];
	# YYYY.MM.DD�`���ł��邱�Ƃ����҂��Ă���
	$newdate = join '', (split /\./, $release[2], 3);
	
	$i = 0;
	$newrelease = 0;
	# �o�[�W������r
	# �Ƃ肠������ver��dev�Ȃ疳��(���̓��t�Ŋm�F)
	if ( $ver[0] ne 'dev' ) {
		foreach $nv ( @newver ) {
			$vv = shift @ver;
			if ( $vv < $nv ) {
				$newrelease = 1;
			} elsif ( $vv > $nv ) {
				# �Ȃ����C���X�g�[���ς݂̕��������炵��
				last;
			}
		}
	}
	# �悭�킩��Ȃ������炠�炽�߂ē��t�Ŋm�F����
	unless ( $newrelease ) {
		if ( $date < $newdate ) {
			$newrelease = 1;
		}
	}
	
	
	$this->{'NEWRELEASE'}->{'Update'}	= $newrelease;
	$this->{'NEWRELEASE'}->{'Ver'}		= shift @release;
	$this->{'NEWRELEASE'}->{'URL'}		= 'http://sourceforge.jp/projects/zerochplus/releases/' . shift @release;
	$this->{'NEWRELEASE'}->{'Date'}		= shift @release;
	
	shift @release; # 4�s��(��s)������
	# �c��̓����[�X�m�[�g�Ƃ����������̂��c��
	$this->{'NEWRELEASE'}->{'Detail'}	= \@release;
	
	return 0;

}

#------------------------------------------------------------------------------------------------------------
#
#	�ݒ�l�擾 - Get
#	-------------------------------------------------------------------------------------
#	MELKOR�Ƃ��Ƃ��Ȃ��悤�Ȋ�����
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'NEWRELEASE'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	�ݒ�l�ݒ� - Set
#	-------------------------------------------------------------------------------------
#	MELKOR(ry
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{'NEWRELEASE'}->{$key} = $data;
}

1;

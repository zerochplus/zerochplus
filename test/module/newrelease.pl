#============================================================================================================
#
#	�A�b�v�f�[�g�ʒm
#
#============================================================================================================

package ZP_NEWRELEASE;

use strict;
use warnings;

use Encode;

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
		'NEWRELEASE'	=> undef,
	};
	
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	������ - Init
#	-------------------------------------------------------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F0
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'NEWRELEASE'} = {
		'CheckURL'	=> 'http://zerochplus.sourceforge.jp/Release.txt',
		'Interval'	=> 60 * 60 * 24, # 24����
		'RawVer'	=> $Sys->Get('VERSION'),
		'CachePATH'	=>  '.' . $Sys->Get('INFO') . '/Release.cgi',
		'CachePM'	=> $Sys->Get('PM-ADM'),
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
	
	my $url = $hash->{'CheckURL'};
	my $interval = $hash->{'Interval'};
	
	my $rawver = $hash->{'RawVer'};
	my @ver;
	# 0ch+ BBS n.m.r YYYYMMDD �`���ł��邱�Ƃ�������Ɗ��҂��Ă���
	# �܂��� 0ch+ BBS dev-rREV YYYYMMDD
	if ( $rawver =~ /(\d+(?:\.\d+)+)/ ) {
		@ver = split /\./, $1;
	} elsif ( $rawver =~ /dev-r(\d+)/ ) {
		@ver = ( 'dev', $1 );
	} else {
		@ver = ( 'dev', 0 );
	}
	my $date = '00000000';
	if ( $rawver =~ /(\d{8})/ ) {
		$date = $1;
	}
	
	my $path = $hash->{'CachePATH'};
	
	
	# �L���b�V���̗L���������߂��Ă���f�[�^���Ƃ��Ă���
	if ( !-f $path || ( stat $path )[9] < time - $interval ) {
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
			if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
				flock($fh, 2);
				seek($fh, 0, 0);
				binmode($fh);
				print $fh $proxy->getContent();
				truncate($fh, tell($fh));
				close($fh);
			}
			chmod $hash->{'CachePM'}, $path;
		}
	}
	
	
	# ��r��
	my @release = ();
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		while ( <$fh> ) {
			# $l =~ s/\x0d?\x0a?$//;
			# samwise�Ɠ����̃T�j�^�C�W���O���s���܂�
			$_ =~ s/[\x0d\x0a\0]//g;
			$_ =~ s/"/&quot;/g;
			$_ =~ s/</&lt;/g;
			$_ =~ s/>/&gt;/g;
			
			Encode::from_to( $_, 'utf8', 'sjis' );
			push @release, $_;
		}
		close($fh);
	}
	# ���e(BOM)����
	$release[0] =~ s/^\xef\xbb\xbf//;
	
	# n.m.r�`���ł��邱�Ƃ����҂��Ă���
	my @newver = split /\./, $release[0];
	# YYYY.MM.DD�`���ł��邱�Ƃ����҂��Ă���
	my $newdate = join '', (split /\./, $release[2], 3);
	
	my $i = 0;
	my $newrelease = 0;
	# �o�[�W������r
	# �Ƃ肠������ver��dev�Ȃ疳��(���̓��t�Ŋm�F)
	if ( $ver[0] ne 'dev' ) {
		foreach my $nv ( @newver ) {
			my $vv = shift @ver;
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
#	@param	$key	�擾�L�[
#			$default : �f�t�H���g
#	@return	�ݒ�l
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	
	my $val = $this->{'NEWRELEASE'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	�ݒ�l�ݒ� - Set
#	-------------------------------------------------------------------------------------
#	@param	$key	�ݒ�L�[
#	@param	$data	�ݒ�l
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{'NEWRELEASE'}->{$key} = $data;
}

1;

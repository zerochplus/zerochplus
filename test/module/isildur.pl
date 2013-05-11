#============================================================================================================
#
#	SETTING�f�[�^�Ǘ����W���[��
#
#============================================================================================================
package	ISILDUR;

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
	
	my $obj = {
		'SYS'		=> undef,
		'SETTING'	=> undef,
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�ǂݍ���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�G���[�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'SYS'} = $Sys;
	
	my $set = $this->{'SETTING'} = {};
	InitSettingData($set);
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/SETTING.TXT';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			if ($_ =~ /^(.+?)=(.*)$/) {
				$set->{$1} = $2;
			}
		}
		
		return 1;
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ菑������
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/SETTING.TXT';
	
	# �Q�����˂��SETTING.TXT����
	my @ch2setting = qw(
		BBS_TITLE				BBS_TITLE_PICTURE		BBS_TITLE_COLOR			BBS_TITLE_LINK
		BBS_BG_COLOR			BBS_BG_PICTURE			BBS_NONAME_NAME			BBS_MAKETHREAD_COLOR
		BBS_MENU_COLOR			BBS_THREAD_COLOR		BBS_TEXT_COLOR			BBS_NAME_COLOR
		BBS_LINK_COLOR			BBS_ALINK_COLOR			BBS_VLINK_COLOR			BBS_THREAD_NUMBER
		BBS_CONTENTS_NUMBER		BBS_LINE_NUMBER			BBS_MAX_MENU_THREAD		BBS_SUBJECT_COLOR
		BBS_PASSWORD_CHECK		BBS_UNICODE				BBS_DELETE_NAME			BBS_NAMECOOKIE_CHECK
		BBS_MAILCOOKIE_CHECK	BBS_SUBJECT_COUNT		BBS_NAME_COUNT			BBS_MAIL_COUNT
		BBS_MESSAGE_COUNT		BBS_NEWSUBJECT			BBS_THREAD_TATESUGI		BBS_AD2
		SUBBBS_CGI_ON			NANASHI_CHECK			timecount				timeclose
		BBS_PROXY_CHECK			BBS_OVERSEA_THREAD		BBS_OVERSEA_PROXY		BBS_RAWIP_CHECK
		BBS_SLIP				BBS_DISP_IP				BBS_FORCE_ID			BBS_BE_ID
		BBS_BE_TYPE2			BBS_NO_ID				BBS_JP_CHECK			BBS_VIP931
		BBS_4WORLD				BBS_YMD_WEEKS			BBS_NINJA				
	);
	
	my %orz = %{$this->{'SETTING'}};
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		binmode($fh);
		seek($fh, 0, 0);
		
		# ���Ԃɏo��
		foreach my $key (@ch2setting) {
			my $val = $this->Get($key, '');
			print $fh "$key=$val\n";
			delete $orz{$key};
		}
		foreach my $key (sort keys %orz) {
			my $val = $this->Get($key, '');
			print $fh "$key=$val\n";
			delete $orz{$key};
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	else {
		warn "can't save setting: $path";
	}
	chmod($Sys->Get('PM-TXT'), $path);
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�ǂݍ���(�w��t�@�C��)
#	-------------------------------------------------------------------------------------
#	@param	$path	�w��t�@�C���̃p�X
#	@return	�G���[�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub LoadFrom
{
	my $this = shift;
	my ($path) = @_;
	
	my $set = $this->{'SETTING'} = {};
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			if ($_ =~ /^(.+?)=(.*)$/) {
				$set->{$1} = $2;
			}
		}
		
		return 1;
	}
	else {
		warn "can't load setting: $path";
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ菑������(�w��t�@�C��)
#	-------------------------------------------------------------------------------------
#	@param	$path	�w��t�@�C���̃p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SaveAs
{
	my $this = shift;
	my ($path) = @_;
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach my $key (keys %{$this->{'SETTING'}}) {
			my $val = $this->{'SETTING'}->{$key};
			print $fh "$key=$val\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	else {
		warn "can't save setting: $path";
	}
	chmod($this->{'SYS'}->Get('PM-TXT'), $path);
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�L�[�擾
#	-------------------------------------------------------------------------------------
#	@param	$keySet	�L�[�Z�b�g�i�[�o�b�t�@
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($keySet) = @_;
	
	push @$keySet, keys %{$this->{'SETTING'}};
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�l��r
#	-------------------------------------------------------------------------------------
#	@param	$key	�ݒ�L�[
#	@param	$val	�ݒ�l
#	@return	�����Ȃ�^��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub Equal
{
	my $this = shift;
	my ($key, $val) = @_;
	
	return(defined $this->{'SETTING'}->{$key} && $this->{'SETTING'}->{$key} eq $val);
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�l�擾
#	-------------------------------------------------------------------------------------
#	@param	$key	�ݒ�L�[
#			$default : �f�t�H���g
#	@return	�ݒ�l
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	
	my $val = $this->{'SETTING'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	�f���ݒ�l�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$key	�ݒ�L�[
#	@param	$val	�ݒ�l
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $val) = @_;
	
	$this->{'SETTING'}->{$key} = $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	SETTING���ڏ����� - InitSettingData
#	-------------------------------------------
#	���@���F$pSET : �n�b�V���̎Q��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub InitSettingData
{
	my ($pSET) = @_;
	
	my %set = (
		# �Q�����˂�݊��ݒ荀��
		'BBS_TITLE'				=> '�f�������낿���˂�v���X',
		'BBS_TITLE_PICTURE'		=> 'kanban.gif',
		'BBS_TITLE_COLOR'		=> '#000000',
		'BBS_TITLE_LINK'		=> 'http://zerochplus.sourceforge.jp/',
		'BBS_BG_COLOR'			=> '#FFFFFF',
		'BBS_BG_PICTURE'		=> 'ba.gif',
		'BBS_NONAME_NAME'		=> '���������񁗂��낿���˂�v���X',
		'BBS_MAKETHREAD_COLOR'	=> '#CCFFCC',
		'BBS_MENU_COLOR'		=> '#CCFFCC',
		'BBS_THREAD_COLOR'		=> '#EFEFEF',
		'BBS_TEXT_COLOR'		=> '#000000',
		'BBS_NAME_COLOR'		=> 'green',
		'BBS_LINK_COLOR'		=> '#0000FF',
		'BBS_ALINK_COLOR'		=> '#FF0000',
		'BBS_VLINK_COLOR'		=> '#AA0088',
		'BBS_THREAD_NUMBER'		=> 10,
		'BBS_CONTENTS_NUMBER'	=> 10,
		'BBS_LINE_NUMBER'		=> 12,
		'BBS_MAX_MENU_THREAD'	=> 30,
		'BBS_SUBJECT_COLOR'		=> '#FF0000',
		'BBS_PASSWORD_CHECK'	=> 'checked',
		'BBS_UNICODE'			=> 'pass',
		'BBS_DELETE_NAME'		=> '���ځ[��',
		'BBS_NAMECOOKIE_CHECK'	=> 'checked',
		'BBS_MAILCOOKIE_CHECK'	=> 'checked',
		'BBS_SUBJECT_COUNT'		=> 48,
		'BBS_NAME_COUNT'		=> 128,
		'BBS_MAIL_COUNT'		=> 64,
		'BBS_MESSAGE_COUNT'		=> 2048,
		'BBS_NEWSUBJECT'		=> 1,
		'BBS_THREAD_TATESUGI'	=> 5,
		'BBS_AD2'				=> '',
		'SUBBBS_CGI_ON'			=> 1,
		'NANASHI_CHECK'			=> '',
		'timecount'				=> 7,
		'timeclose'				=> 5,
		'BBS_PROXY_CHECK'		=> '',
		'BBS_OVERSEA_THREAD'	=> '',
		'BBS_OVERSEA_PROXY'		=> '',
		'BBS_RAWIP_CHECK'		=> '',
		'BBS_SLIP'				=> '',
		'BBS_DISP_IP'			=> '',
		'BBS_FORCE_ID'			=> 'checked',
		'BBS_BE_ID'				=> '',
		'BBS_BE_TYPE2'			=> '',
		'BBS_NO_ID'				=> '',
		'BBS_JP_CHECK'			=> '',
		'BBS_YMD_WEEKS'			=> '��/��/��/��/��/��/�y',
		'BBS_NINJA'				=> '',
		
		# �ȉ�0ch�I���W�i���ݒ荀��
		'BBS_DATMAX'			=> 512,
		'BBS_COOKIEPATH'		=> '/',
		'BBS_READONLY'			=> 'caps',
		'BBS_REFERER_CUSHION'	=> 'jump.x0.to/',
		'BBS_THREADCAPONLY'		=> '',
		'BBS_TRIPCOLUMN'		=> 10,
		'BBS_SUBTITLE'			=> '�܂��[��G�k',
		'BBS_COLUMN_NUMBER'		=> 256,
		'BBS_SAMBATIME'			=> '',
		'BBS_HOUSHITIME'		=> '',
		'BBS_CAP_COLOR'			=> '',
		'BBS_TATESUGI_HOUR'		=> '0',
		'BBS_TATESUGI_COUNT'	=> '5',
		'BBS_INDEX_LINE_NUMBER'		=> 12,
	);
	
	while (my ($key, $val) = each(%set)) {
		$pSET->{$key} = $val;
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

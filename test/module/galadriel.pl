#============================================================================================================
#
#	�ėp�f�[�^�ϊ��E�擾���W���[��
#
#============================================================================================================
package	GALADRIEL;

use strict;
use warnings;
no warnings qw(once);

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
	
	my $obj = {};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	URL�����擾 - GetArgument
#	-------------------------------------------
#	���@���F$pENV : %ENV�̃��t�@�����X
#	�߂�l�F�����z��
#
#------------------------------------------------------------------------------------------------------------
sub GetArgument
{
	my $this = shift;
	my ($pENV) = @_;
	
	my @retArg = ();
	
	# PATH_INFO����
	if (defined $pENV->{'PATH_INFO'} && $pENV->{'PATH_INFO'} ne '') {
		my @Awork = split(/\//, $pENV->{'PATH_INFO'}, -1);
		@retArg = (@Awork[1, 2], ConvertOption($Awork[3]));
	}
	# QUERY_STRING
	else {
		my @Awork = split(/[&;]/, $pENV->{'QUERY_STRING'}, -1);
		@retArg = (undef, undef, 0, 1, 1000, 1, 0);
		foreach (@Awork) {
			my ($var, $val) = split(/=/, $_, 2);
			$retArg[0] = $val if ($var eq 'bbs');	# BBS
			$retArg[1] = $val if ($var eq 'key');	# �X���b�h�L�[
			$retArg[3] = $val if ($var eq 'st');	# �J�n���X��
			$retArg[4] = $val if ($var eq 'to');	# �I�����X��
			# 1��\��
			if ($var eq 'nofirst' && $val eq 'true') {
				$retArg[5] = 1;
			}
			# �ŐVn���\��
			if ($var eq 'last' && $val != -1) {
				$retArg[2] = 1;
				$retArg[3] = $val;
				$retArg[4] = $val;
			}
		}
		# �P�ƕ\���t���O
		if ($retArg[3] == $retArg[4] && $retArg[2] != 1) {
			$retArg[6] = 1;
		}
	}
	
	return @retArg;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����X�����K�� - RegularDispNum
#	-------------------------------------------
#	���@���F$Sys   : MELKOR
#			$Dat   : ARAGORN�I�u�W�F�N�g
#			$last  : last�t���O
#			$start : �J�n�s
#			$end   : �I���s
#	�߂�l�F(�J�n�s�A�I���s)
#
#------------------------------------------------------------------------------------------------------------
sub RegularDispNum
{
	my $this = shift;
	my ($Sys, $Dat, $last, $start, $end) = @_;
	
	# �傫������ swap
	if ($start > $end && $end != -1) {
		($start, $end) = ($end, $start);
	}
	
	my $resmax = $Dat->Size();
	my ($st, $ed);
	
	# �ŐVn���\��
	if ($last == 1) {
		$st = $resmax - $start + 1;
		$st = 1 if ($st < 1);
		$ed = $resmax;
	}
	# �w��\��
	elsif ($start || $end) {
		if ($end == -1) {
			$st = $start < 1 ? 1 : $start;
			$ed = $resmax;
		}
		else {
			$st = $start < 1 ? 1 : $start;
			$ed = $end < $resmax ? $end : $resmax;
		}
	}
	# �S���\��
	else {
		$st = 1;
		$ed = $resmax;
	}
	
	# ���Ԃɂ�鐧���L��
	if ($Sys->Get('LIMTIME')) {
		# �\�����X����100������
		if ($ed - $st >= 100) {
			$ed = $st + 100 - 1;
		}
	}
	return ($st, $ed);
}

#------------------------------------------------------------------------------------------------------------
#
#	URL�ϊ� - ConvertURL
#	--------------------------------------------
#	���@���F$Sys : MELKOR���W���[��
#			$Set : SETTING
#			$mode : �G�[�W�F���g
#			$text : �ϊ��e�L�X�g(���t�@�����X)
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertURL
{
	my $this = shift;
	my ($Sys, $Set, $mode, $text) = @_;
	
	# ���Ԃɂ�鐧���L��
	return $text if ($Sys->Get('LIMTIME'));
	
	my $server = $Sys->Get('SERVER');
	my $cushion = $Set->Get('BBS_REFERER_CUSHION');
	my $reg1 = q{(https?|ftp)://(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)};	# URL�����P
	my $reg2 = q{<(https?|ftp)::(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)>};	# URL�����Q
	
	# �g�т���
	if ($mode eq 'O') {
		$$text =~ s/$reg1/<$1::$2>/g;
		while ($$text =~ /$reg2/) {
			my $work = (split(/\//, $2))[0];
			$work =~ s/(www\.|\.com|\.net|\.jp|\.co|\.ne)//g;
			$$text =~ s|$reg2|<a href="$1://$2">$work</a>|;
		}
		$$text =~ s/ <br> /<br>/g;
		$$text =~ s/\s*<br>/<br>/g;
		$$text =~ s/(?:<br>){2}/<br>/g;
		$$text =~ s/(?:<br>){3,}/<br><br>/g;
	}
	# PC����
	else {
		# �N�b�V��������
		if ($cushion) {
			$server =~ /$reg1/;
			$server = $2;
			$$text =~ s/$reg1/<$1::$2>/g;
			while ($$text =~ /$reg2/) {
				# ���I�����N -> �N�b�V�����Ȃ�
				if ($2 =~ m{^\Q$server\E(?:/|$)}) {
					$$text =~ s|$reg2|<a href="$1://$2" target="_blank">$1://$2</a>|;
				}
				# ���I�ȊO
				else {
					if($1 eq 'http') {
						$$text =~ s|$reg2|<a href="$1://$cushion$2" target="_blank">$1://$2</a>|;
					}
					elsif ($cushion =~ m{^(?:jump\.x0\.to|nun\.nu)/$}) {
						$$text =~ s|$reg2|<a href="http://$cushion$1://$2" target="_blank">$1://$2</a>|;
					}
				}
			}
		}
		# �N�b�V��������
		else {
			$$text =~ s|$reg1|<a href="$1://$2" target="_blank">$1://$2</a>|g;
		}
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	���p�ϊ� - ConvertQuotation
#	--------------------------------------------
#	���@���F$Sys : MELKOR�I�u�W�F�N�g
#			$text : �ϊ��e�L�X�g
#			$mode : �G�[�W�F���g
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertQuotation
{
	my $this = shift;
	my ($Sys, $text, $mode) = @_;
	
	# ���Ԃɂ�鐧���L��
	return $text if ($Sys->Get('LIMTIME'));
	
	my $pathCGI = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	
	if ($Sys->Get('PATHKIND')) {
		# URL�x�[�X�𐶐�
		my $buf = '<a href="';
		$buf .= $pathCGI . ($mode ? '/r.cgi' : '/read.cgi');
		$buf .= '?bbs=' . $Sys->Get('BBS') . '&key=' . $Sys->Get('KEY');
		$buf .= '&nofirst=true';
		
		$$text =~ s{&gt;&gt;([1-9][0-9]*)-([1-9][0-9]*)}
					{$buf&st=$1&to=$2" target="_blank">>>$1-$2</a>}g;
		$$text =~ s{&gt;&gt;([1-9][0-9]*)-(?!0)}
					{$buf&st=$1&to=-1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;-([1-9][0-9]*)}
					{$buf&st=1&to=$1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;([1-9][0-9]*)}
					{$buf&st=$1&to=$1" target="_blank">>>$1</a>}g;
	}
	else{
		# URL�x�[�X�𐶐�
		my $buf = '<a href="';
		$buf .= $pathCGI . ($mode eq 'O' ? '/r.cgi/' : '/read.cgi/');
		$buf .= $Sys->Get('BBS') . '/' . $Sys->Get('KEY');
		
		$$text =~ s{&gt;&gt;([1-9][0-9]*)-([1-9][0-9]*)}
					{$buf/$1-$2n" target="_blank">>>$1-$2</a>}g;
		$$text =~ s{&gt;&gt;([1-9][0-9]*)-(?!0)}
					{$buf/$1-" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;-([1-9][0-9]*)}
					{$buf/-$1" target="_blank">>>-$1</a>}g;
		$$text =~ s{&gt;&gt;([1-9][0-9]*)}
					{$buf/$1" target="_blank">>>$1</a>}g;
	}
	$$text	=~ s{>>(?=[1-9])}{&gt;&gt;}g;
	
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	������p�ϊ� - ConvertSpecialQuotation
#	--------------------------------------------
#	���@���F$Sys : MELKOR�I�u�W�F�N�g
#			$text : �ϊ��e�L�X�g
#			$mode : �G�[�W�F���g
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertSpecialQuotation
{
	my $this = shift;
	my ($Sys, $text, $mode) = @_;
	
	if ($mode ne 'O') {
		my @lines = split(/<br>/, $text, -1);
		map {
			$_ = "<font color=gray>$_</font>" if (/^��/);
			$_ = "<font color=green>$_</font>" if (/^#/);
		} @lines;
		return join('<br>', @lines);
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	�e�L�X�g�폜 - DeleteText
#	--------------------------------------------
#	���@���F$text : �Ώۃe�L�X�g(���t�@�����X)
#			$len  : �ő啶����
#	�߂�l�F���`��e�L�X�g
#
#------------------------------------------------------------------------------------------------------------
sub DeleteText
{
	my $this = shift;
	my ($text, $len) = @_;
	
	my @lines = split(/ ?<br> ?/, $$text, -1);
	my $ret = '';
	my $tlen = 0;
	
	foreach (@lines) {
		$tlen += length $_;
		last if ($tlen > $len);
		$ret .= "$_<br>";
		$tlen += 4;
	}
	
	return substr($ret, 0, -4);
}

#------------------------------------------------------------------------------------------------------------
#
#	���s���擾 - GetTextLine
#	--------------------------------------------
#	���@���F$text : �Ώۃe�L�X�g(���t�@�����X)
#	�߂�l�F���s��
#
#------------------------------------------------------------------------------------------------------------
sub GetTextLine
{
	my $this = shift;
	my ($text) = @_;
	
	$_ = $$text;
	my $l = s/(\r\n|[\r\n])/a/g || s/(<br>)/a/gi;
	
	return ($l + 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	�s����擾 - GetTextInfo
#	------------------------------------------------
#	���@���F$text : �����e�L�X�g(���t�@�����X)
#	�߂�l�F($tline,$tcolumn) : �e�L�X�g�̍s����
#			�e�L�X�g�̍ő包��
#	���@�l�F�e�L�X�g�̍s��؂��<br>�ɂȂ��Ă��邱��
#
#------------------------------------------------------------------------------------------------------------
sub GetTextInfo
{
	my $this = shift;
	my ($text) = @_;
	
	my @lines = split(/ ?<br> ?/, $$text, -1);
	
	my $mx = 0;
	foreach (@lines) {
		if ($mx < length($_)) {
			$mx = length($_);
		}
	}
	
	return (scalar(@lines), $mx);
}

#------------------------------------------------------------------------------------------------------------
#
#	�G�[�W�F���g���[�h�擾 - GetAgentMode
#	--------------------------------------------
#	���@���F$UA   : ���[�U�[�G�[�W�F���g
#	�߂�l�F�G�[�W�F���g���[�h
#
#------------------------------------------------------------------------------------------------------------
sub GetAgentMode
{
	my $this = shift;
	my ($client) = @_;
	
	my $agent = '0';
	
	if ($client & $ZP::C_MOBILEBROWSER) {
		$agent = 'O';
	}
	elsif ($client & $ZP::C_FULLBROWSER) {
		$agent = 'Q';
	}
	elsif ($client & $ZP::C_P2) {
		$agent = 'P';
	}
	elsif ($client & $ZP::C_IPHONE_F) {
		$agent = 'i';
	}
	elsif ($client & $ZP::C_IPHONEWIFI) {
		$agent = 'I';
	}
	else {
		$agent = '0';
	}
	
	return $agent;
}

#------------------------------------------------------------------------------------------------------------
#
#	�N���C�A���g(�@��)�擾 - GetClient
#	--------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�N���C�A���g(�@��)
#
#------------------------------------------------------------------------------------------------------------
sub GetClient
{
	my $this = shift;
	
	my $ua = $ENV{'HTTP_USER_AGENT'} || '';
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	my $client = 0;
	
	require './module/cidr_list.pl';
	
	my $cidr = $ZP_CIDR::cidr;
	
	if (CIDRHIT($cidr->{'docomo'}, $addr)) {
		$client = $ZP::C_DOCOMO_M;
	}
	elsif (CIDRHIT($cidr->{'docomo_pc'}, $addr)) {
		$client = $ZP::C_DOCOMO_F;
	}
	elsif (CIDRHIT($cidr->{'vodafone'}, $addr)) {
		$client = $ZP::C_SOFTBANK_M;
	}
	elsif (CIDRHIT($cidr->{'vodafone_pc'}, $addr)) {
		$client = $ZP::C_SOFTBANK_F;
	}
	elsif (CIDRHIT($cidr->{'ezweb'}, $addr)) {
		$client = $ZP::C_AU_M;
	}
	elsif (CIDRHIT($cidr->{'ezweb_pc'}, $addr)) {
		$client = $ZP::C_AU_F;
	}
	elsif (CIDRHIT($cidr->{'emobile'}, $addr)) {
		if ($ua =~ m|^emobile/1\.0\.0|) {
			$client = $ZP::C_EMOBILE_M;
		}
		else {
			$client = $ZP::C_EMOBILE_F;
		}
	}
	elsif (CIDRHIT($cidr->{'willcom'}, $addr)) {
		if ($ua =~ m|^Mozilla/3\.0|) {
			$client = $ZP::C_WILLCOM_M;
		}
		elsif ($ua =~ m|^Mozilla/4\.0| && $ua =~ m/IEMobile|PPC/) {
			$client = $ZP::C_WILLCOM_M;
		}
		else {
			$client = $ZP::C_WILLCOM_F;
		}
	}
	elsif (CIDRHIT($cidr->{'ibis'}, $addr)) {
		$client = $ZP::C_IBIS;
	}
	elsif (CIDRHIT($cidr->{'jig'}, $addr)) {
		$client = $ZP::C_JIG;
	}
	elsif (CIDRHIT($cidr->{'iphone'}, $addr)) {
		$client = $ZP::C_IPHONE_F;
	}
	elsif (CIDRHIT($cidr->{'p2'}, $addr)) {
		$client = $ZP::C_P2;
	}
	elsif ($host =~ m|\.opera-mini\.net$|) {
		$client = $ZP::C_OPERAMINI;
	}
	elsif ($ua =~ / iPhone| iPad/) {
		$client = $ZP::C_IPHONEWIFI;
	}
	else {
		$client = $ZP::C_PC;
	}
	
	return $client;
}

#------------------------------------------------------------------------------------------------------------
#
#	IP�`�F�b�N(CIDR�Ή�) by (-Ac)
#	-------------------------------------------------------------------------------------
#	@param	$orz	CIDR���X�g(�z��)
#	@param	$ho		�`�F�b�N����
#	@return	�q�b�g�����ꍇ1 ����ȊO��0
#
#------------------------------------------------------------------------------------------------------------

sub CIDRHIT
{
	
	my ($orz, $ho) = @_;
	
	foreach (@$orz) {
		# ���S��v = /32 ���Ă��Ƃ�^^;
		$_ .= '/32' if ($_ !~ m|/|);
		
		# �ȉ�CIDR�`��
		my ($target, $length) = split('/', $_);
		
		my $ipaddr = unpack("B$length", pack('C*', split(/\./, $ho)));
		$target = unpack("B$length", pack('C*', split(/\./, $target)));
		
		if ($target eq $ipaddr) {
			return 1;
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g�ы@����擾
#	-------------------------------------------------------------------------------------
#	@param	$client	
#	@return	�̎��ʔԍ�
#
#------------------------------------------------------------------------------------------------------------
sub GetProductInfo
{
	my $this = shift;
	my ($client) = @_;
	
	my $product;
	
	# docomo
	if ( $client & $ZP::C_DOCOMO ) {
		# $ENV{'HTTP_X_DCMGUID'} - �[�������ԍ�, �̎��ʏ��, ���[�UID, i���[�hID
		$product = $ENV{'HTTP_X_DCMGUID'};
		$product =~ s/^X-DCMGUID: ([a-zA-Z0-9]+)$/$1/i;
	}
	# SoftBank
	elsif ( $client & $ZP::C_SOFTBANK ) {
		# USERAGENT�Ɋ܂܂��15���̐��� - �[���V���A���ԍ�
		$product = $ENV{'HTTP_USER_AGENT'};
		$product =~ s/.+\/SN([A-Za-z0-9]+)\ .+/$1/;
	}
	# au
	elsif ( $client & $ZP::C_AU ) {
		# $ENV{'HTTP_X_UP_SUBNO'} - �T�u�X�N���C�oID, EZ�ԍ�
		$product = $ENV{'HTTP_X_UP_SUBNO'};
		$product =~ s/([A-Za-z0-9_]+).ezweb.ne.jp/$1/i;
	}
	# e-mobile(�����[��)
	elsif ( $client & $ZP::C_EMOBILE ) {
		# $ENV{'X-EM-UID'} - 
		$product = $ENV{'X-EM-UID'};
		$product =~ s/x-em-uid: (.+)/$1/i;
	}
	# ����p2
	elsif ( $client & $ZP::C_P2 ) {
		# $ENV{'HTTP_X_P2_CLIENT_IP'} - (�����҂�IP)
		# $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} - (�����҂̌ő̎��ʔԍ�)
		$ENV{'REMOTE_P2'} = $ENV{'REMOTE_ADDR'};
		$ENV{'REMOTE_ADDR'} = $ENV{'HTTP_X_P2_CLIENT_IP'};
		$ENV{'REMOTE_HOST'} = $this->GetRemoteHost($ENV{'REMOTE_ADDR'});
		if( $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'} ne "" ) {
			$product = $ENV{'HTTP_X_P2_MOBILE_SERIAL_BBM'};
		}
		else {
			$product = $ENV{'HTTP_USER_AGENT'};
			$product =~ s/.+p2-user-hash: (.+)\)/$1/i;
		}
	}
	else {
		$product = $ENV{'REMOTE_HOST'};
	}
	
	return $product;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����[�g�z�X�g(IP)�擾�֐� - GetRemoteHost
#	---------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�FIP�A�����z�X
#
#------------------------------------------------------------------------------------------------------------
sub GetRemoteHost
{
	my $this = shift;
	
	my $host = $ENV{'REMOTE_ADDR'};
	$host = gethostbyaddr(pack('c4', split(/\./, $host)), 2) || $host;
	
	return $host;
}

#------------------------------------------------------------------------------------------------------------
#
#	ID�쐬�֐� - MakeID
#	--------------------------------------
#	���@���F$server : �T�[�o�[��
#			$client : �[��
#			$koyuu  : �[���ŗL���ʎq
#			$bbs    : ��
#			$column : ID����
#	�߂�l�FID
#
#------------------------------------------------------------------------------------------------------------
sub MakeID
{
	my $this = shift;
	my ($server, $client, $koyuu, $bbs, $column) = @_;
	
	# ��̐���
	my $uid;
	if ($client & ($ZP::C_P2 | $ZP::C_MOBILE)) {
		# �[���ԍ� �������� p2-user-hash �̏��3�������擾
		#$uid = main::GetProductInfo($this, $ENV{'HTTP_USER_AGENT'}, $ENV{'REMOTE_HOST'});
		if (length($koyuu) > 8) {
			$uid = substr($koyuu, 0, 2) . substr($koyuu, -6, 3);
		}
		else {
			$uid = substr($koyuu, 0, 5);
		}
	}
	else {
		# IP�𕪉�
		my @nums = split(/\./, $ENV{'REMOTE_ADDR'});
		# ���3��1���ڎ擾
		$uid = substr($nums[3], -2) . substr($nums[2], -2) . substr($nums[1], -1);
	}
	
	my @times = localtime time;
	
	# �T�[�o�[���������������
	$uid .= substr(crypt($server, $times[4]), 2, 1) . substr(crypt($bbs, $times[4]), 2, 2);
	
	# ����ݒ�
	$column *= -1;
	
	# ID�̐���
	my $ret = substr(crypt(crypt($uid, $times[5]), $times[3] + 31), $column);
	$ret =~ s/\./+/g;
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���b�v�쐬�֐� - ConvertTrip
#	--------------------------------------
#	���@���F$key     : �g���b�v�L�[(���t�@�����X)
#			$column  : ����
#			$shatrip : 12���g���b�vON/OFF
#	�߂�l�F�ϊ��㕶����
#
#------------------------------------------------------------------------------------------------------------
sub ConvertTrip
{
	my $this = shift;
	my ($key, $column, $shatrip) = @_;
	
	# crypt�̂Ƃ��̌��擾
	$column *= -1;
	
	my $trip = '';
	$$key = '' if (!defined $$key);
	
	if (length($$key) >= 12) {
		# �擪1�����̎擾
		my $mark = substr($$key, 0, 1);
		
		if ($mark eq '#' || $mark eq '$') {
			# ���L�[
			if ($$key =~ m|^#([0-9a-zA-Z]{16})([./0-9A-Za-z]{0,2})$|) {
				my $key2 = pack('H*', $1);
				my $salt = substr($2 . '..', 0, 2);
				
				# 0x80���Č�
				$key2 =~ s/\x80[\x00-\xff]*$//;
				
				$trip = substr(crypt($key2, $salt), $column);
			}
			# �����̊g���p
			else {
				$trip = '???';
			}
		}
		# SHA1(�V�d�l)�g���b�v
		elsif ($shatrip) {
			require Digest::SHA::PurePerl;
			Digest::SHA::PurePerl->import( qw(sha1_base64) );
			$trip = substr(sha1_base64($$key), 0, 12);
			$trip =~ tr/+/./;
		}
	}
	
	# �]���̃g���b�v��������
	if ($trip eq '') {
		my $salt = substr($$key, 1, 2);
		$salt = '' if (!defined $salt);
		$salt .= 'H.';
		$salt =~ s/[^\.-z]/\./go;
		$salt =~ tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/;
		
		# 0x80���Č�
		$$key =~ s/\x80[\x00-\xff]*$//;
		
		$trip = substr(crypt($$key, $salt), $column);
	}
	
	return $trip;
}

#------------------------------------------------------------------------------------------------------------
#
#	�I�v�V�����ϊ� - ConvertOption
#	--------------------------------------
#	���@���F$opt : �I�v�V����
#	�߂�l�F���ʔz��
#
#------------------------------------------------------------------------------------------------------------
sub ConvertOption
{
	my ($opt) = @_;
	
	$opt = '' if (!defined $opt);
	
	# �����l
	my @ret = (
		-1,	# ���X�g�t���O
		-1,	# �J�n�s
		-1,	# �I���s
		-1,	# >>1��\���t���O
		-1	# �P�ƕ\���t���O
	);
	
	# �ŐVn��(1����)
	if ($opt =~ /l(\d+)n/) {
		$ret[0] = 1;
		$ret[1] = $1 + 1;
		$ret[2] = $1 + 1;
		$ret[3] = 1;
	}
	# �ŐVn��(1����)
	elsif ($opt =~ /l(\d+)/) {
		$ret[0] = 1;
		$ret[1] = $1;
		$ret[2] = $1;
		$ret[3] = 0;
	}
	# n-m(1����)
	elsif ($opt =~ /(\d+)-(\d+)n/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = $2;
		$ret[3] = 1;
	}
	# n-m(1����)
	elsif ($opt =~ /(\d+)-(\d+)/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = $2;
		$ret[3] = 0;
	}
	# n�ȍ~(1����)
	elsif ($opt =~ /(\d+)-n/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = -1;
		$ret[3] = 1;
	}
	# n�ȍ~(1����)
	elsif ($opt =~ /(\d+)-/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = -1;
		$ret[3] = 0;
	}
	# n�܂�(1����)
	elsif ($opt =~ /-(\d+)/) {
		$ret[0] = 0;
		$ret[1] = 1;
		$ret[2] = $1;
		$ret[3] = 0;
	}
	# n�\��(1����)
	elsif ($opt =~ /(\d+)n/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = $1;
		$ret[3] = 1;
		$ret[4] = 1;
	}
	# n�\��(1����)
	elsif ($opt =~ /(\d+)/) {
		$ret[0] = 0;
		$ret[1] = $1;
		$ret[2] = $1;
		$ret[3] = 1;
		$ret[4] = 1;
	}
	
	return @ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�X���� - CreatePath
#	-------------------------------------------
#	���@���F$Sys  : MELKOR
#			$mode : 0:read 1:r
#			$bbs  : BBS�L�[
#			$key  : �X���b�h�L�[
#			$opt  : �I�v�V����
#	�߂�l�F�������ꂽ�p�X
#
#------------------------------------------------------------------------------------------------------------
sub CreatePath
{
	my $this = shift;
	my ($Sys, $mode, $bbs, $key, $opt) = @_;
	
	my $path = $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . ($mode eq 0 ? '/read.cgi' : '/r.cgi');
	
	# QUERY_STRING�p�X����
	if ($Sys->Get('PATHKIND')) {
		my @opts = ConvertOption($opt);
		
		# �x�[�X�쐬
		$path .= "?bbs=$bbs&key=$key";
		
		# �ŐVn���\��
		if ($opts[0]) {
			$path .= "&last=$opts[1]";
		}
		# �w��\��
		else {
			$path .= "&st=$opts[1]";
			$path .= "&to=$opts[2]";
		}
		
		# >>1�\���̕t��
		$path .= '&nofirst=' . ($opts[3] == 1 ? 'true' : 'false');
	}
	# PATH_INFO�p�X����
	else {
		$path .= "/$bbs/$key/$opt";
	}
	
	return $path;
}

#------------------------------------------------------------------------------------------------------------
#
#	���t�擾 - GetDate
#	--------------------------------------
#	���@���F$Set  : SETTING.TXT
#			$msect : msec on/off
#	�߂�l�F���t������
#
#------------------------------------------------------------------------------------------------------------
sub GetDate
{
	my $this = shift;
	my ($Set, $msect) = @_;
	
	$ENV{'TZ'} = 'JST-9';
	my @info = localtime time;
	$info[5] += 1900;
	$info[4] += 1;
	
	# �j���̎擾
	my $week = ('��', '��', '��', '��', '��', '��', '�y')[$info[6]];
	if (defined $Set && ! $Set->Equal('BBS_YMD_WEEKS', '')) {
		$week = (split(/\//, $Set->Get('BBS_YMD_WEEKS')))[$info[6]];
	}
	
	my $str = '';
	$str .= sprintf('%04d/%02d/%02d', $info[5], $info[4], $info[3]);
	$str .= "($week)" if ($week ne '');
	$str .= sprintf(' %02d:%02d:%02d', $info[2], $info[1], $info[0]);
	
	# msec�̎擾
	if ($msect) {
		eval {
			require Time::HiRes;
			my $times = Time::HiRes::time();
			$str .= sprintf(".%02d", ($times * 100) % 100);
		};
	}
	
	return $str;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�V���A���l������t��������擾����
#	-------------------------------------------------------------------------------------
#	@param	$serial	�V���A���l
#	@param	$mode	0:���ԕ\���L�� 1:���t�̂�
#	@return	���t������
#
#------------------------------------------------------------------------------------------------------------
sub GetDateFromSerial
{
	my $this = shift;
	my ($serial, $mode) = @_;
	
	$ENV{'TZ'} = 'JST-9';
	my @info = localtime $serial;
	$info[5] += 1900;
	$info[4] += 1;
	
	my $str = sprintf('%04d/%02d/%02d', $info[5], $info[4], $info[3]);
	$str .= sprintf(' %02d:%02d', $info[2], $info[1]) if (!$mode);
	
	return $str;
}

#------------------------------------------------------------------------------------------------------------
#
#	ID���������񐶐�
#	-------------------------------------------------------------------------------------
#	@param	$Set	ISILDUR
#	@param	$Form	SAMWISE
#	@param	$Sec	
#	@param	$id		ID
#	@param	$koyuu	�[���ŗL���ʎq
#	@param	$agent	�G�[�W�F���g
#	@return	ID����������
#	@see	�D�揇�ʁFHOST > NOID > FORCE > PASS
#
#------------------------------------------------------------------------------------------------------------
sub GetIDPart
{
	my $this = shift;
	my ($Set, $Form, $Sec, $id, $capID, $koyuu, $agent) = @_;
	
	my $mode = '';
	
	# PC�E�g�ю��ʔԍ��t��
	if ($Set->Equal('BBS_SLIP', 'checked')) {
		$mode = $agent;
		$id .= $mode;
	}
	
	# �z�X�g�\��
	if ($Set->Equal('BBS_DISP_IP', 'checked')) {
		
		# ID��\�������L��
		if ($Sec->IsAuthority($capID, $ZP::CAP_DISP_NOID, $Form->Get('bbs'))) {
			return " ID:???$mode";
		}
		
		if ( $mode eq 'O' ) {
			return " HOST:$koyuu $ENV{'REMOTE_HOST'}".( $mode ne '' ? " $mode" : '' );
		}
		elsif ( $mode eq 'P' ) {
			return " HOST:$koyuu $ENV{'REMOTE_HOST'} ($ENV{'REMOTE_ADDR'})".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " HOST:$koyuu".( $mode ne '' ? " $mode" : '' );
		}
	}
	# IP�\�� Ver.Siberia
	if ($Set->Equal('BBS_DISP_IP', 'siberia')){
		
		# ID��\�������L��
		if ($Sec->IsAuthority($capID, $ZP::CAP_DISP_NOID, $Form->Get('bbs'))) {
			return " ���M��:???$mode";
		}
		
		if ( $mode eq 'P' ) {
			return " ���M��:$ENV{'REMOTE_P2'}".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " ���M��:$ENV{'REMOTE_ADDR'}".( $mode ne '' ? " $mode" : '' );
		}
	}
	# IP�\�� Ver.Sakhalin
	if ($Set->Equal('BBS_DISP_IP', 'sakhalin')) {
		
		# ID��\�������L��
		if ($Sec->IsAuthority($capID, $ZP::CAP_DISP_NOID, $Form->Get('bbs'))) {
			return " ���M��:???".( $mode ne '' ? " $mode" : '' );
		}
		
		if ( $mode eq 'P' ) {
			return " ���M��:$ENV{'HTTP_X_P2_CLIENT_IP'} ($koyuu)".( $mode ne '' ? " $mode" : '' );
		}
		elsif ( $mode eq 'O' ) {
			return " ���M��:$ENV{'REMOTE_ADDR'} ($koyuu)".( $mode ne '' ? " $mode" : '' );
		}
		else {
			return " ���M��:$ENV{'REMOTE_ADDR'}".( $mode ne '' ? " $mode" : '' );
		}
	}
	
	# ID�\�������Ȃ炻�̂܂܃��^�[��
	if ($Set->Equal('BBS_NO_ID', 'checked')) {
		return ( $mode ne '' ? " $mode" : '' );
	}
	# ID��\�������L��
	if ($Sec->IsAuthority($capID, $ZP::CAP_DISP_NOID, $Form->Get('bbs'))) {
		return " ID:???$mode";
	}
	# ����ID�̏ꍇ
	if ($Set->Equal('BBS_FORCE_ID', 'checked')) {
		return " ID:$id";
	}
	# �C��ID�̏ꍇ
	if (! $Form->IsInput(['mail'])) {
		return " ID:$id";
	}
	
	return " ID:???$mode";
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꕶ���ϊ� - ConvertCharacter0
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^(�Q��)
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter0
{
	my $this = shift;
	my ($data) = @_;
	
	$$data = '' if (!defined $$data);
	
	$$data =~ s/^($ZP::RE_SJIS*?)��/$1#/g;
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꕶ���ϊ� - ConvertCharacter1
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^(�Q��)
#			$mode : 
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter1
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (!defined $$data);
	
	# all
	$$data =~ s/</&lt;/g;
	$$data =~ s/>/&gt;/g;
	
	# mail
	if ($mode == 1) {
		$$data =~ s/"/&quot;/g;#"
	}
	
	# text
	if ($mode == 2) {
		$$data =~ s/\n/<br>/g;
	}
	# not text
	else {
		$$data =~ s/\n//g;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�֑������ϊ� - ConvertCharacter2
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^(�Q��)
#			$mode : 
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter2
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (!defined $$data);
	
	# name mail
	if ($mode == 0 || $mode == 1) {
		$$data =~ s/��/��/g;
		$$data =~ s/��/��/g;
		$$data =~ s/�폜/�h�폜�h/g;
	}
	
	# name
	if ($mode == 0) {
		$$data =~ s/�Ǘ�/�h�Ǘ��h/g;
		$$data =~ s/�ǒ�/�h�ǒ��h/g;
		$$data =~ s/���A/�h���A�h/g;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꕶ���ϊ� - ConvertFusianasan
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^(�Q��)
#			$host : 
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ConvertFusianasan
{
	my $this = shift;
	my ($data, $host) = @_;
	
	$$data = '' if (!defined $$data);
	
	$$data =~ s/�R���/fusianasan/g;
	$$data =~ s|^($ZP::RE_SJIS*?)fusianasan|$1</b>$host<b>|g;
	$$data =~ s|^($ZP::RE_SJIS*?)fusianasan|$1 </b>$host<b>|g;
}

#------------------------------------------------------------------------------------------------------------
#
#	�A���A���J�[���o - IsAnker
#	--------------------------------------
#	���@���F$text : �����Ώۃe�L�X�g
#			$num  : �ő�A���J�[��
#	�߂�l�F0:���e�� 1:���߂�
#
#------------------------------------------------------------------------------------------------------------
sub IsAnker
{
	my $this = shift;
	my ($text, $num) = @_;
	
	$_ = $$text;
	my $cnt = s/&gt;&gt;([1-9])//g;
	
	return ($cnt > $num ? 1 : 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	���t�@�����f - IsReferer
#	--------------------------------------
#	���@���F$Sys : MELKOR
#	�߂�l�F���Ȃ�0,NG�Ȃ�1
#
#------------------------------------------------------------------------------------------------------------
sub IsReferer
{
	my $this = shift;
	my ($Sys, $pENV) = @_;
	
	my $svr = $Sys->Get('SERVER');
	if ($pENV->{'HTTP_REFERER'} =~ /\Q$svr\E/) {		# ���I����Ȃ�OK
		return 0;
	}
	if ($pENV->{'HTTP_USER_AGENT'} =~ /Monazilla/) {	# �Q�����c�[����OK
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���N�V�`�F�b�N - IsProxy
#	--------------------------------------
#	���@���F$Sys   : MELKOR
#			$Form  : 
#			$from  : ���O��
#			$mode  : �G�[�W�F���g
#	�߂�l�F�v���N�V�Ȃ�Ώۃ|�[�g�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub IsProxy
{
	my $this = shift;
	my ($Sys, $Form, $from, $mode) = @_;
	
	# �g��, iPhone(3G���) �̓v���L�V�K�����������
	return 0 if ($mode eq 'O' || $mode eq 'i');
	
	my @dnsbls = ();
	push(@dnsbls, 'niku.2ch.net') if($Sys->Get('BBQ'));
	push(@dnsbls, 'bbx.2ch.net') if($Sys->Get('BBX'));
	push(@dnsbls, 'dnsbl.spam-champuru.livedoor.com') if($Sys->Get('SPAMCH'));
	
	# DNSBL�₢���킹
	my $addr = join('.', reverse( split(/\./, $ENV{'REMOTE_ADDR'})));
	foreach my $dnsbl (@dnsbls) {
		if (CheckDNSBL("$addr.$dnsbl") eq '127.0.0.2') {
			$Form->Set('FROM', "</b> [�\\{}\@{}\@{}-] <b>$from");
			return ($mode eq 'P' ? 0 : 1);
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	DNSBL������(timeout�t��) - CheckDNSBL
#	--------------------------------------
#	���@���F$host : ����������HOST
#	�߂�l�F�v���L�V�ł����127.0.0.2
#
#------------------------------------------------------------------------------------------------------------
sub CheckDNSBL
{
	my ($host) = @_;
	
	my $ret = eval {
		require Net::DNS;
		my $res = Net::DNS::Resolver->new;
		$res->tcp_timeout(1);
		$res->udp_timeout(1);
		$res->retry(1);
		
		if ((my $query = $res->query($host))) {
			my @ans = $query->answer;
			
			foreach (@ans) {
				return $_->address;
			}
		}
		if ($res->errorstring eq 'query timed out') {
			return '127.0.0.0';
		}
	};
	
	return $ret if (defined $ret);
	
	if ($@) {
		require Net::DNS::Lite;
		my $res = Net::DNS::Lite->new(
			server => [ qw(8.8.4.4 8.8.8.8) ], # google public dns
			timeout => [2, 3],
		);
		
		my @ans = $res->resolve($host, 'a');
		return $_->[4] foreach (@ans);
	}
	
	return '127.0.0.1';
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�X�����E���K�� - MakePath
#	--------------------------------------
#	���@���F$path1 : �p�X1
#			$path2 : �p�X2
#	�߂�l�F���K���p�X
#
#------------------------------------------------------------------------------------------------------------
sub MakePath {
	my $this = (ref($_[0]) eq 'GALADRIEL' ? shift : undef);
	my ($path1, $path2) = @_;
	
	$path1 = '.' if (! defined $path1 || $path1 eq '');
	$path2 = '.' if (! defined $path2 || $path2 eq '');
	
	my @dir1 = ($path1 =~ m[^/|[^/]+]g);
	my @dir2 = ($path2 =~ m[^/|[^/]+]g);
	
	my $absflg = 0;
	if ($dir2[0] eq '/') {
		$absflg = 1;
		@dir1 = @dir2;
	}
	else {
		push @dir1, @dir2;
	}
	
	my @dir3 = ();
	
	my $depth = 0;
	for my $i (0 .. $#dir1) {
		if ($i == 0 && $dir1[$i] eq '/') {
			$absflg = 1;
		}
		elsif ($dir1[$i] eq '.' || $dir1[$i] eq '') {
		}
		elsif ($dir1[$i] eq '..') {
			if ($depth >= 1) {
				pop @dir3;
			}
			else {
				if ($absflg) {
					last;
				}
				if ($#dir3 == -1 || $dir3[$#dir3] eq '..') {
					push @dir3, '..';
				}
				else {
					pop @dir3;
				}
			}
			$depth--;
		}
		else {
			push @dir3, $dir1[$i];
			$depth++;
		}
	}
	
	my $path3;
	if ($#dir3 == -1) {
		$path3 = ($absflg ? '/' : '.');
	}
	else {
		$path3 = ($absflg ? '/' : '') . join('/', @dir3);
	}
	
	return $path3;
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

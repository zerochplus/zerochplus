#============================================================================================================
#
#	�ėp�f�[�^�ϊ��E�擾���W���[��(GALADRIEL)
#	galadriel.pl
#	------------------------------------------------
#	2002.12.03 start
#	2003.02.07 cookie�֌W��ʃ��W���[����
#	           DeleteText�ǉ�
#
#	���낿���˂�v���X
#	2010.08.12 �V�d�l�g���b�v�Ή�
#	2010.08.14 ID�d�l�ύX �g���b�v�d�l�ύX
#	           �֑�����2ch���S�݊�
#	2010.08.15 �v���O�C���Ή��ێ��ɂ����������̕���
#	2010.08.21 �V�d�l�g���b�v�Ή��C��
#
#============================================================================================================
package	GALADRIEL;

use strict;
#�R�����g�A�E�g���O���ꍇ�͕ϐ��̏������`�F�b�N�����邱�ƁB
#use warnings;

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
	my $obj = {};
	
	bless $obj, $this;
	
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
	my (@retArg, @Awork);
	my ($var, $val);
	
	if ($pENV->{'PATH_INFO'}) {														# PATH_INFO����
		@Awork		= split(/\//, $pENV->{'PATH_INFO'});
		$retArg[0]	= $Awork[1];													# bbs��(�p�X)
		$retArg[1]	= $Awork[2];													# �X���b�h�L�[
		@Awork		= ConvertOption($Awork[3]);										# �I�v�V�����ϊ�
		$retArg[2]	= $Awork[0];
		$retArg[3]	= $Awork[1];
		$retArg[4]	= $Awork[2];
		$retArg[5]	= $Awork[3];
		$retArg[6]	= $Awork[4];
	}
	else {																			# QUERY_STRING
		@Awork = split(/&/, $pENV->{'QUERY_STRING'});
		@retArg = ('', '', 0, 1, 1000, 1, 0);
		foreach (@Awork) {
			($var, $val) = split(/=/, $_);
			if		($var eq 'bbs') {						$retArg[0] = $val; }	# BBS
			elsif	($var eq 'key') {						$retArg[1] = $val; }	# �X���b�h�L�[
			elsif	($var eq 'st') {						$retArg[3] = $val; }	# �J�n���X��
			elsif	($var eq 'to') {						$retArg[4] = $val; }	# �I�����X��
			elsif	($var eq 'nofirst' && $val eq 'true') {	$retArg[5] = 1; }		# 1��\��
			elsif	($var eq 'last' && $val != -1) {								# �ŐVn���\��
				$retArg[2] = 1;
				$retArg[3] = $val;
				$retArg[4] = $val;
			}
		}
		if ($retArg[3] == $retArg[4] && $retArg[2] != 1) {							# �P�ƕ\���t���O
			$retArg[6] = 1;
		}
	}
	
	return @retArg;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����X�����K�� - RegularDispNum
#	-------------------------------------------
#	���@���F$A     : ARAGORN�I�u�W�F�N�g
#			$last  : last�t���O
#			$start : �J�n�s
#			$end   : �I���s
#	�߂�l�F(�J�n�s�A�I���s)
#
#------------------------------------------------------------------------------------------------------------
sub RegularDispNum
{
	my $this = shift;
	my ($M, $A, $last, $start, $end) = @_;
	my (@dlist, $rn, $st, $ed);
	
	if ($start > $end && $end != -1) {					# �傫������
		$rn = $start;
		$start = $end;
		$end = $rn;
	}
	$rn = $A->Size();
	
	if ($last == 1) {									# �ŐVn���\��
		$start -= 2;
		$st = (($rn - $start > 0) ? $rn - $start : 1);
		$ed = $rn;
	}
	elsif ($start || $end) {							# �w��\��
		if ($end == -1) {
			$st = $start > 0 ? $start : 1;
			$ed = $rn;
		}
		else {
			$st = $start > 0 ? $start : 1;
			$ed = $end < $rn ? $end : $rn;
		}
	}
	else {												# �S���\��
		$st = 1;
		$ed = $rn;
	}
	
	if ($M->Get('LIMTIME')) {							# ���Ԃɂ�鐧���L��
		if ($ed - $st > 100) {							# �\�����X����100������
			$ed = $st + 100;
		}
	}
	return ($st, $ed);
}

#------------------------------------------------------------------------------------------------------------
#
#	URL�ϊ� - ConvertURL
#	--------------------------------------------
#	���@���F$M,$I : ���W���[��
#			$mode : �G�[�W�F���g
#			$text : �ϊ��e�L�X�g
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertURL
{
	my $this = shift;
	my ($M, $I, $mode, $text) = @_;
	my (@work, @dlist, $reg1, $reg2, $cushion, $server);
	
	if 	($M->Get('LIMTIME')) {															# ���Ԃɂ�鐧���L��
		return $text;
	}
	
	$server		= $M->Get('SERVER');
	$cushion	= $I->Get('BBS_REFERER_CUSHION');										# URL�N�b�V����
	$reg1		= q{(https?|ftp)://(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)};			# URL�����P
	$reg2		= q{<(https?|ftp)::(([-\w.!~*'();/?:\@=+\$,%#]|&(?![lg]t;))+)>};		# URL�����Q
	
	if ($mode) {																		# �g�т���
		$$text =~ s{$reg1}{<$1::$2>}g;													# URL1���ϊ�
		while ($$text =~ /$reg2/) {
			@work = split(/\//, $2);
			$work[0] =~ s/(www\.|\.com|\.net|\.jp|\.co|\.ne)//g;
			$$text =~ s{$reg2}{<a href="$1://$2">$work[0]</a>};
		}
		$$text	=~ s/ <br> /<br>/g;														# ���s
		$$text	=~ s/\s*<br>/<br>/g;													# �󔒉��s
		$$text	=~ s/(?:<br>){2}/<br>/g;												# ����s
		$$text	=~ s/(?:<br>){3,}/<br><br>/g;											# ����s
	}
	else {																				# PC����
		if ($cushion) {																	# �N�b�V��������
			$server =~ m|$reg1|;
			$server = $2;
			$$text =~ s|$reg1|<$1::$2>|g;												# URL1���ϊ�
			while ($$text =~ m|$reg2|) {												# 2���ϊ�
				if ($2 =~ m{^\Q$server\E(?:/|$)}) {										# ���I�����N
					$$text =~ s|$reg2|<a href="$1://$2" target="_blank">$1://$2</a>|;	# �N�b�V�����Ȃ�
				}
				else {																	# ���I�ȊO
					if( $1 eq "http" ) {
						$$text =~ s|$reg2|<a href="$1://$cushion$2" target="_blank">$1://$2</a>|;
					}
					elsif ( $cushion =~ /(?:jump.x0.to|nun.nu)/ ) {
						$$text =~ s|$reg2|<a href="http://$cushion$1://$2" target="_blank">$1://$2</a>|;
					}
				}
			}
		}
		else {																			# �N�b�V��������
			$$text =~ s|$reg1|<a href="$1://$2" target="_blank">$1://$2</a>|g;			# �ʏ�URL�ϊ�
		}
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	���p�ϊ� - ConvertQuotation
#	--------------------------------------------
#	���@���F$M    : MELKOR�I�u�W�F�N�g
#			$text : �ϊ��e�L�X�g
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertQuotation
{
	my $this = shift;
	my ($Sys, $text, $mode) = @_;
	my ($buf, $pathCGI);
	
	if ($Sys->Get('LIMTIME')) {															# ���Ԃɂ�鐧���L��
		return $text;
	}
	$pathCGI = $Sys->Get('SERVER') . $Sys->Get('CGIPATH');
	
	if ($Sys->Get('PATHKIND')) {
		# URL�x�[�X�𐶐�
		$buf .= '<a href="';
		$buf .= $pathCGI . ($mode ? '/r.cgi' : '/read.cgi');
		$buf .= '?bbs=' . $Sys->Get('BBS') . '&key=' . $Sys->Get('KEY');
		$buf .= '&nofirst=true';
		
		$$text =~ s{&gt;&gt;(\d+)-(\d+)}												# ���p n-m
					{$buf&st=$1&to=$2" target="_blank">>>$1-$2</a>}g;
		$$text =~ s{&gt;&gt;(\d+)-}														# ���p n-
					{$buf&st=$1&to=-1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;-(\d+)}														# ���p -n
					{$buf&st=1&to=$1" target="_blank">>>$1-</a>}g;
		$$text =~ s{&gt;&gt;(\d+)}														# ���p n
					{$buf&st=$1&to=$1" target="_blank">>>$1</a>}g;
	}
	else{
		# URL�x�[�X�𐶐�
		$buf = '<a href="';
		$buf .= $pathCGI . ($mode ? '/r.cgi/' : '/read.cgi/');
		$buf .= $Sys->Get('BBS') . '/' . $Sys->Get('KEY');
		
		$$text =~ s{&gt;&gt;(\d+)-(\d+)}{$buf/$1-$2n" target="_blank">>>$1-$2</a>}g;	# ���p n-m
		$$text =~ s{&gt;&gt;(\d+)-}{$buf/$1-" target="_blank">>>$1-</a>}g;				# ���p n-
		$$text =~ s{&gt;&gt;-(\d+)}{$buf/-$1" target="_blank">>>-$1</a>}g;				# ���p -n
		$$text =~ s{&gt;&gt;(\d+)}{$buf/$1" target="_blank">>>$1</a>}g;					# ���p n
	}
	$$text	=~ s{>>(\d+)}{&gt;&gt;$1}g;													# &gt;�ϊ�
	
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	������p�ϊ� - ConvertSpecialQuotation
#	--------------------------------------------
#	���@���F$M    : MELKOR�I�u�W�F�N�g
#			$text : �ϊ��e�L�X�g
#	�߂�l�F�ϊ���̃��b�Z�[�W
#
#------------------------------------------------------------------------------------------------------------
sub ConvertSpecialQuotation
{
	my $this = shift;
	my ($M, $text, $mode) = @_;
	my (@lines, @edited, $len);
	
	if ($mode == 0) {
		@lines = split(/<br>/, $text);
		$text = '';
		foreach (@lines) {
			if (/^��/) {
				$_ = "<font color=gray>$_</font>";
			}
			elsif (/^#/) {
				$_ = "<font color=green>$_</font>";
			}
			$text .= "$_<br>";
		}
		$len = $text - 4;
		return substr($text, 0, $len);
	}
	return $text;
}

#------------------------------------------------------------------------------------------------------------
#
#	�e�L�X�g�폜 - DeleteText
#	--------------------------------------------
#	���@���F$text : �Ώۃe�L�X�g
#			$len  : �ő啶����
#	�߂�l�F���`��e�L�X�g
#
#------------------------------------------------------------------------------------------------------------
sub DeleteText
{
	my $this = shift;
	my ($text, $len) = @_;
	my @texts = split(/<br>/, $$text);
	my ($ret, $tlen, $rlen);
	
	$ret = '';
	$tlen = 0;
	foreach (@texts) {
		$rlen = length $_;
		$tlen += $rlen;
		last if ($tlen > $len);
		$ret = "$ret$_<br>";
		$tlen += 4;
	}
	$tlen = length($ret) - 4;
	$ret = substr($ret, 0, $tlen);
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	���s���擾 - GetTextLine
#	--------------------------------------------
#	���@���F$text : �Ώۃe�L�X�g
#	�߂�l�F���s��
#
#------------------------------------------------------------------------------------------------------------
sub GetTextLine
{
	my $this = shift;
	my ($text) = @_;
	my ($buf, $l);
	
	$_ = $$text;
	$l = s/(\r\n)/a/g;
	
	if ($l == 0) { $_ = $$text; $l = s/(\r)/a/g; }
	if ($l == 0) { $_ = $$text; $l = s/(\n)/a/g; }
	if ($l == 0) { $_ = $$text; $l = s/(<br>|<BR>)/a/g; }
	
	return ($l + 1);
}

#------------------------------------------------------------------------------------------------------------
#
#	�s����擾 - GetTextInfo
#	------------------------------------------------
#	���@���F$text : �����e�L�X�g
#	�߂�l�F($tline,$tcolumn) : �e�L�X�g�̍s����
#			�e�L�X�g�̍ő包��
#	���@�l�F�e�L�X�g�̍s��؂��<br>�ɂȂ��Ă��邱��
#
#------------------------------------------------------------------------------------------------------------
sub GetTextInfo
{
	my $this = shift;
	my ($text) = @_;
	my (@lines, $ln, $mx);
	
	@lines = split(/ ?<br> ?/, $$text);
	$ln = $$text =~ s/<br>/<br>/g;
	$mx = 0;
	
	foreach (@lines) {
		if ($mx < length($_)) {
			$mx = length $_;
		}
	}
	return ($ln, $mx);
}

#------------------------------------------------------------------------------------------------------------
#
#	�G�[�W�F���g���[�h�擾 - GetAgentMode
#	--------------------------------------------
#	���@���F$UA   : ���[�U�[�G�[�W�F���g
#	�߂�l�F�G�[�W�F���g���[�h
#
#	2010.08.13 windyakin ��
#	 -> ID�����������K���̂��ߕύX
#
#	2010.08.30 windyakin ��
#	 -> �t���u���E�U, AirH"�̑Ή�
#
#	2011.02.13 �F�X
#	 -> ��
#
#------------------------------------------------------------------------------------------------------------
sub GetAgentMode
{
	my $this = shift;
	my ($client) = @_;
	my ($agent);
	
	$agent = '0';
	
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
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�N���C�A���g(�@��)�擾 - GetClient
#	--------------------------------------------
#	���@���F
#	�߂�l�F
#
#	2011.02.13 �F�X
#
#------------------------------------------------------------------------------------------------------------
sub GetClient
{
	my $this = shift;
	my ($ua, $host, $addr, $client, $cidr);
	
	$ua = $ENV{'HTTP_USER_AGENT'};
	$host = $ENV{'REMOTE_HOST'};
	$addr = $ENV{'REMOTE_ADDR'};
	$client = 0;
	
	require './module/cidr_list.pl';
	
	$cidr = $ZP_CIDR::cidr;
	
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
#	@param	$orz  : CIDR���X�g(�z��)
#			$ho   : �`�F�b�N����
#	@return	�q�b�g�����ꍇ1 ����ȊO��0
#
#------------------------------------------------------------------------------------------------------------

sub CIDRHIT {
	
	my ( $orz, $ho ) = @_;
	
	foreach ( @{$orz} ) {
		
		# CIDR�`���łȂ���Ε��ʂɊ��S��v�`�F�b�N
		# return ( $_ eq $ho ? 1 : 0 ) if ( $_ !~ m|/| );
		# ���S��v = /32 ���Ă��Ƃ�^^;
		$_ .= '/32' if ( $_ !~ m|/| );
		
		# �ȉ�CIDR�`��
		{
			my ( $target, $length ) = split( '/', $_ );
			
			my $ipaddr = unpack("B$length", pack('C*', split(/\./, $ho)));
			$target = unpack("B$length", pack('C*', split(/\./, $target)));
			
			return 1 if ( $target eq $ipaddr );
		}
		
	}
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�g�ы@����擾
#	-------------------------------------------------------------------------------------
#	@return	�̎��ʔԍ�
#
#	2010.08.14 windyakin ��
#	 -> ��v3�L�����A+����p2������悤�ɕύX
#
#------------------------------------------------------------------------------------------------------------
sub GetProductInfo
{
	my $this = shift;
	my ($client) = @_;
	my $product = undef;
	
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
	my ($HOST);
	
	$HOST = $ENV{'REMOTE_ADDR'};
	
	if ($HOST =~ /\d$/) {
		$HOST = gethostbyaddr(pack('c4', split(/\./, $HOST)), 2) || $HOST;
	}
	
	return $HOST;
}

#------------------------------------------------------------------------------------------------------------
#
#	ID�쐬�֐� - MakeID
#	--------------------------------------
#	���@���F$server : �L�[�T�[�o
#			$column : ID����
#	�߂�l�FID
#
#------------------------------------------------------------------------------------------------------------
sub MakeID
{
	my $this = shift;
	my ($server, $client, $koyuu, $bbs, $column) = @_;
	my @times = localtime time;
	my (@nums, $ret, $str, $uid);
	
	# ��̐���
	if ( $client & ($ZP::C_P2 | $ZP::C_MOBILE) ) {
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
		@nums = split(/\./, $ENV{'REMOTE_ADDR'});
		# ���3��1���ڎ擾
		$uid = substr($nums[3], -2) . substr($nums[2], -2) . substr($nums[1], -1);
	}
	
	# �T�[�o�[���������������
	$str = $uid . substr(crypt($server, $times[4]), 2, 1) . substr(crypt($bbs, $times[4]), 2, 2);
	# ����ݒ�
	$column = -1 * $column;
	
	# ID�̐���
	$ret = substr(crypt(crypt($str, $times[5]), $times[3] + 31), $column);
	$ret =~ s/\./+/g;
	
	return $ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���b�v�쐬�֐� - ConvertTrip
#	--------------------------------------
#	���@���F$key    : �g���b�v�L�[
#			$column : ����
#			$orz    : �V�d�lON/OFF
#	�߂�l�F�ϊ��㕶����
#
#	2010.08.12 windyakin ��
#	 -> ���L�[�ϊ�, �V�d�l�g���b�v(12��) �ɑΉ�
#		�ڍׂ͕��Y����triptest���Q�l�̂���
#
#	2010.08.14 windyakin ��
#	 -> �V�d�l�g���b�v�̑I�𐫂ɑΉ�
#
#	2010.08.21 �F�X
#	 -> �V�d�l�g���b�v�Ή��C��
#
#------------------------------------------------------------------------------------------------------------
sub ConvertTrip
{
	my $this = shift;
	my ($key, $column, $shatrip) = @_;
	my ($trip, $mark, $salt, $key2);
	
	$$key = '' if (! defined $$key);
	
	# crypt�̂Ƃ��̌��擾
	$column = -1 * $column;
	
	$trip = '';
	
	if (length $$key >= 12) {
		# �擪2�����̎擾
		$mark = substr($$key, 0, 1);
		
		if ($mark eq '#' || $mark eq '$') {
			if ($$key =~ m|^#([0-9a-zA-Z]{16})([./0-9A-Za-z]{0,2})$|) {
				$key2 = pack('H*', $1);
				$salt = substr($2 . '..', 0, 2);
				
				# 0x80���Č�
				$key2 =~ s/\x80[\x00-\xff]*$//;
				
				$trip = substr(crypt($key2, $salt), $column);
			}
			else {
				# �����̊g���p
				$trip = '???';
			}
		}
		elsif ($shatrip eq 1) {
			# SHA1(�V�d�l)�g���b�v
			eval {
				require Digest::SHA::PurePerl;
				Digest::SHA::PurePerl->import( qw(sha1_base64) );
				$trip = substr(sha1_base64($$key), 0, 12);
			};
			if ( $@ ) {
				# Digest::SHA::PurePerl�ł��Ȃ��ꍇ��???(e)��\��������
				$trip = "???(e)";
			}
			$trip =~ tr/+/./;
		}
	}
	
	if ($trip eq '') {
		# �]���̃g���b�v��������
		$salt = substr($$key, 1, 2);
		$salt = '' if (! defined $salt);
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
	my (@ret);
	
	$opt = '' if (! defined $opt);
	
	@ret = (-1, -1, -1, -1, -1);		# �����l
	
	if ($opt =~ /l(\d+)n/) {			# �ŐVn��(1����)
		$ret[0] = 1;					# ���X�g�t���O
		$ret[1] = $1 + 1;				# �J�n�s
		$ret[2] = $1 + 1;				# �I���s
		$ret[3] = 1;					# >>1��\���t���O
	}
	elsif ($opt =~ /l(\d+)/) {			# �ŐVn��(1����)
		$ret[0] = 1;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = $1;					# �I���s
		$ret[3] = 0;					# >>1��\���t���O
	}
	elsif ($opt =~ /(\d+)-(\d+)n/) {	# n-m(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = $2;					# �I���s
		$ret[3] = 1;					# >>1��\���t���O
	}
	elsif ($opt =~ /(\d+)-(\d+)/) {		# n-m(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = $2;					# �I���s
		$ret[3] = 0;					# >>1��\���t���O
	}
	elsif ($opt =~ /(\d+)-n/) {			# n�ȍ~(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = -1;					# �I���s
		$ret[3] = 1;					# >>1��\���t���O
	}
	elsif ($opt =~ /(\d+)-/) {			# n�ȍ~(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = -1;					# �I���s
		$ret[3] = 0;					# >>1��\���t���O
	}
	elsif ($opt =~ /-(\d+)/) {			# n�܂�(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = 1;					# �J�n�s
		$ret[2] = $1;					# �I���s
		$ret[3] = 0;					# >>1��\���t���O
	}
	elsif ($opt =~ /(\d+)n/) {			# n�\��(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = $1;					# �I���s
		$ret[3] = 1;					# >>1��\���t���O
		$ret[4] = 1;					# �P�ƕ\���t���O
	}
	elsif ($opt =~ /(\d+)/) {			# n�\��(1����)
		$ret[0] = 0;					# ���X�g�t���O
		$ret[1] = $1;					# �J�n�s
		$ret[2] = $1;					# �I���s
		$ret[3] = 1;					# >>1��\���t���O
		$ret[4] = 1;					# �P�ƕ\���t���O
	}
	
	return @ret;
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�X���� - CreatePath
#	-------------------------------------------
#	���@���F$bbs  : BBS�L�[
#			$key  : �X���b�h�L�[
#			$opt  : �I�v�V����
#	�߂�l�F�������ꂽ�p�X
#
#------------------------------------------------------------------------------------------------------------
sub CreatePath
{
	my $this = shift;
	my ($M, $mode, $bbs, $key, $opt) = @_;
	my ($path, @opts);
	
	$path = $M->Get('SERVER') . $M->Get('CGIPATH') . ($mode == 0 ? '/read.cgi' : '/r.cgi');
	
	if ($M->Get('PATHKIND')) {							# QUERY_STRING�p�X����
		@opts = ConvertOption($opt);
		
		$path .= "?bbs=$bbs&key=$key";					# �x�[�X�쐬
		if ($opts[0]) {									# �ŐVn���\��
			$path .= "&last=$opts[1]&nofirst=";
		}
		else {											# �w��\��
			$path .= "&st=$opts[1]";
			$path .= "&to=$opts[2]&nofirst=";
		}
		$path .= ($opts[3] == 1 ? 'true' : 'false');	# >>1�\���̕t��
	}
	else {												# PATH_INFO�p�X����
		$path .= "/$bbs/$key/$opt";
	}
	
	return $path;
}

#------------------------------------------------------------------------------------------------------------
#
#	���t�擾 - GetDate
#	--------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F���t������
#
#------------------------------------------------------------------------------------------------------------
sub GetDate
{
	my $this = shift;
	my ($oSet, $msect) = @_;
	my (@info, @weeks, $week);
	
	$ENV{'TZ'} = "JST-9";
	@info = localtime time;
	$info[5] += 1900;
	$info[4] += 1;
	
	# �j���̎擾
	$week = ('��', '��', '��', '��', '��', '��', '�y')[$info[6]];
	if (defined $oSet) {
		if (! $oSet->Equal('BBS_YMD_WEEKS', '')) {
			@weeks = split(/\//, $oSet->Get('BBS_YMD_WEEKS'));
			$week = $weeks[$info[6]];
		}
	}
	
	foreach (0 .. 4) {
		$info[$_] = "0$info[$_]" if ($info[$_] < 10);
	}
	
	# msec�̎擾
	if ($msect) {
		use Time::HiRes;
		my $times = Time::HiRes::time;
		$info[0] .= sprintf(".%02d", substr((split(/\./, $times))[1], 0, 2 ));
	}
	
	return "$info[5]/$info[4]/$info[3]" . ($week eq '' ? '' : "($week)") . " $info[2]:$info[1]:$info[0]";
	
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
	my (@info, $week);
	
	$ENV{'TZ'} = "JST-9";
	@info = localtime $serial;
	$info[5] += 1900;
	$info[4] += 1;
	
	foreach (1 .. 4) {
		$info[$_] = "0$info[$_]" if ($info[$_] < 10);
	}
	
	return "$info[5]/$info[4]/$info[3]"						if ($mode == 1);
	return "$info[5]/$info[4]/$info[3] $info[2]:$info[1]"	if ($mode == 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	ID���������񐶐�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Set	ISILDUR
#	@param	$Form	SAMWISE
#	@param	$Sec	
#	@param	$id		ID
#	@return	ID����������
#	@see	�D�揇�ʁFHOST > NOID > FORCE > PASS
#
#------------------------------------------------------------------------------------------------------------
sub GetIDPart
{
	my $this = shift;
	my ($Set, $Form, $Sec, $id, $capID, $koyuu, $agent) = @_;
	my ($mode, @mail);
	
	$mode = '';
	
	# PC�E�g�ю��ʔԍ��t��
	if ($Set->Equal('BBS_SLIP', 'checked')) {
		$mode = $agent;
		$id .= $mode;
	}
	
	# �z�X�g�\��
	if ($Set->Equal('BBS_DISP_IP', 'checked')) {
		
		# ID��\�������L��
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
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
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
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
		if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
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
	if ($Sec->IsAuthority($capID, 14, $Form->Get('bbs'))) {
		return " ID:???$mode";
	}
	# ����ID�̏ꍇ
	if ($Set->Equal('BBS_FORCE_ID', 'checked')) {
		return " ID:$id";
	}
	# �C��ID�̏ꍇ
	@mail = ('mail');
	if (! $Form->IsInput(\@mail)) {
		return " ID:$id";
	}
	
	return " ID:???$mode";
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꕶ���ϊ� - ConvertCharacter0
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^�̎Q��
#			$mode : 
#	�߂�l�F�Ȃ�
#
#	2011.07.17 �F�X
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter0
{
	my $this = shift;
	my ($data) = @_;
	
	$$data = '' if (! defined $$data);
	
	$$data =~ s/^($ZP::RE_SJIS*?)��/$1#/g;
}

#------------------------------------------------------------------------------------------------------------
#
#	���ꕶ���ϊ� - ConvertCharacter1
#	--------------------------------------
#	���@���F$data : �ϊ����f�[�^�̎Q��
#			$mode : 
#	�߂�l�F�Ȃ�
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter1
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (! defined $$data);
	
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
#	���@���F$data : �ϊ����f�[�^�̎Q��
#			$mode : 
#	�߂�l�F�Ȃ�
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub ConvertCharacter2
{
	my $this = shift;
	my ($data, $mode) = @_;
	
	$$data = '' if (! defined $$data);
	
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
#	���@���F$data : �ϊ����f�[�^�̎Q��
#			$mode : 
#	�߂�l�F�Ȃ�
#
#	2011.07.17 �F�X
#
#------------------------------------------------------------------------------------------------------------
sub ConvertFusianasan
{
	my $this = shift;
	my ($data, $host) = @_;
	
	$$data = '' if (! defined $$data);
	
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
	my ($cnt);
	
	$cnt = 0;
	
	$_ = $$text;
	$cnt = s/&gt;&gt;(\d+)//g;
	
	return ($cnt > $num ? 1 : 0);
}

#------------------------------------------------------------------------------------------------------------
#
#	���t�@�����f - IsReferer
#	--------------------------------------
#	���@���F$M : ���W���[��
#	�߂�l�F���Ȃ�0,NG�Ȃ�1
#
#------------------------------------------------------------------------------------------------------------
sub IsReferer
{
	my $this = shift;
	my ($M, $pENV) = @_;
	my ($svr);
	
	$svr = $M->Get('SERVER');
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
#	���@���F�Ȃ�
#	�߂�l�F�v���N�V�Ȃ�Ώۃ|�[�g�ԍ�
#
#	2010.08.12 windyakin ��
#	 -> BBQ, BBX, �X�p�������Ղ�[ ��DNSBL�₢���킹���ɕύX
#	2010.08.23 windyakin ��
#	 -> p2.2ch.net ���v���L�V�o�R�ŏ������݂����ꍇ���}�[�N��\��
#
#------------------------------------------------------------------------------------------------------------
sub IsProxy
{
	my $this = shift;
	my ($sys, $oForm, $from, $mode) = @_;
	my ($addr, @dnsbls);
	
	@dnsbls = ();
	
	push(@dnsbls, 'niku.2ch.net') if($sys->Get('BBQ'));
	push(@dnsbls, 'bbx.2ch.net') if($sys->Get('BBX'));
	push(@dnsbls, 'dnsbl.spam-champuru.livedoor.com') if($sys->Get('SPAMCH'));
	
	# �g��, iPhone(3G���) �̓v���L�V�K�����������
	if ( $mode eq "O" || $mode eq "i" ) {
		return 0;
	}
	
	# DNSBL�₢���킹
	$addr = join('.', reverse( split(/\./, $ENV{'REMOTE_ADDR'})));
	foreach my $dnsbl (@dnsbls) {
		if ( CheckDNSBL("$addr.$dnsbl") eq '127.0.0.2' ) {
			$oForm->Set('FROM', "</b> [�\\{}\@{}\@{}-] <b>$from");
			return ( $mode eq "P" ? 0 : 1 );
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
	
	my ( $host ) = @_;
	my ( $res, $query, @ans );
	
	require Net::DNS;
	
	$res = Net::DNS::Resolver->new;
	$res->tcp_timeout(1);
	$res->udp_timeout(1);
	$res->retry(1);
	
	if ( ($query = $res->query($host)) ) {
		
		@ans = $query->answer;
		
		foreach ( @ans ) {
			return $_->address;
		}
	}
	if ( $res->errorstring eq 'query timed out' ) {
		return "127.0.0.0";
	}
	
	return "127.0.0.1";
	
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�X�����E���K�� - MakePath
#	--------------------------------------
#	���@���F
#	�߂�l�F
#
#	2011.02.13 �F�X
#
#------------------------------------------------------------------------------------------------------------
sub MakePath {
	my $this = undef;
	$this = shift if (ref($_[0]) eq 'GALADRIEL');
	my ($path1, $path2) = @_;
	my (@dir1, @dir2, @dir3, $path3, $absflg, $depth);
	
	$path1 = '.' if (! defined $path1 || $path1 eq '');
	$path2 = '.' if (! defined $path2 || $path2 eq '');
	
	@dir1 = ($path1 =~ m[^/|[^/]+]g);
	@dir2 = ($path2 =~ m[^/|[^/]+]g);
	
	if ($dir2[0] eq '/') {
		$absflg = 1;
		@dir1 = @dir2;
	}
	else {
		$absflg = 0;
		push @dir1, @dir2;
	}
	
	@dir3 = ();
	
	$depth = 0;
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

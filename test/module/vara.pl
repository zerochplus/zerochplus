#============================================================================================================
#
#	�f���������ݎx�����W���[��
#
#============================================================================================================
package	VARA;

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
	my $class = shift;
	
	my $obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	������
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR(�K�{)
#	@param	$Form	SAMWISE(�K�{)
#	@param	$Set	ISILDUR
#	@param	$Thread	BILBO
#	@param	$Conv	GALADRIEL
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ($Sys, $Form, $Set, $Thread, $Conv) = @_;
	
	$this->{'SYS'} = $Sys;
	$this->{'FORM'} = $Form;
	$this->{'SET'} = $Set;
	$this->{'THREADS'} = $Thread;
	$this->{'CONV'} = $Conv;
	
	# ���W���[�����p�ӂ���ĂȂ��ꍇ�͂����Ő�������
	if (!defined $Set) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	if (!defined $Thread) {
		require './module/baggins.pl';
		$this->{'THREADS'} = BILBO->new;
		$this->{'THREADS'}->Load($Sys);
	}
	if (!defined $Conv) {
		require './module/galadriel.pl';
		$this->{'CONV'} = GALADRIEL->new;
	}
	
	# �L���b�v�Ǘ����W���[�����[�h
	require './module/ungoliants.pl';
	$this->{'SECURITY'} = SECURITY->new;
	$this->{'SECURITY'}->Init($Sys);
	$this->{'SECURITY'}->SetGroupInfo($Sys->Get('BBS'));
	
	# �g���@�\���Ǘ����W���[�����[�h
	require './module/athelas.pl';
	$this->{'PLUGIN'} = ATHELAS->new;
	$this->{'PLUGIN'}->Load($Sys);
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ݏ��� - WriteData
#	-------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	
	# �������ݑO����
	$this->ReadyBeforeCheck();
	
	my $err = $ZP::E_SUCCESS;
	
	# ���͓��e�`�F�b�N(���O�A���[��)
	return $err if (($err = $this->NormalizationNameMail()) != $ZP::E_SUCCESS);
	
	# ���͓��e�`�F�b�N(�{��)
	return $err if (($err = $this->NormalizationContents()) != $ZP::E_SUCCESS);
	
	# �K���`�F�b�N
	return $err if (($err = $this->IsRegulation()) != $ZP::E_SUCCESS);
	
	
	# �f�[�^�̏�������
	require './module/gondor.pl';
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $Form = $this->{'FORM'};
	my $Conv = $this->{'CONV'};
	my $Thread = $this->{'THREADS'};
	
	# �������ݒ��O����
	$err = $this->ReadyBeforeWrite(ARAGORN::GetNumFromFile($Sys->Get('DATPATH')) + 1);
	return $err if ($err != $ZP::E_SUCCESS);
	
	# ���X�v�f�̎擾
	my @elem = ();
	$Form->GetListData(\@elem, 'subject', 'FROM', 'mail', 'MESSAGE');
	
	$err = $ZP::E_SUCCESS;
	my $id	 = $Conv->MakeID($Sys->Get('SERVER'), $Sys->Get('CLIENT'), $Sys->Get('KOYUU'), $Sys->Get('BBS'), 8);
	my $date = $Conv->GetDate($Set, $Sys->Get('MSEC'));
	$date .= $Conv->GetIDPart($Set, $Form, $this->{'SECURITY'}, $id, $Sys->Get('CAPID'), $Sys->Get('KOYUU'), $Sys->Get('AGENT'));
	
	# �v���O�C���u BE(HS)���ۂ����� �vver.0.x.x
	my $beid = $Form->Get('BEID', '');
	$date .= " $beid" if ($beid ne '');
	
	my $data = join('<>', $elem[1], $elem[2], $date, $elem[3], $elem[0]);
	my $data2 = "$data\n";
	my $datPath = $Sys->Get('DATPATH');
	
	# ���O��������
	require './module/peregrin.pl';
	my $Log = PEREGRIN->new;
	$Log->Load($Sys, 'WRT', $Sys->Get('KEY'));
	$Log->Set($Set, length($Form->Get('MESSAGE')), $Sys->Get('VERSION'), $Sys->Get('KOYUU'), $data, $Sys->Get('AGENT', 0));
	$Log->Save($Sys);
	
	# �����[�g�z�X�g�ۑ�(SETTING.TXT�ύX�ɂ��A��ɕۑ�)
	SaveHost($Sys, $Form);
	
	# dat�t�@�C���֒��ڏ�������
	my $resNum = 0;
	my $err2 = ARAGORN::DirectAppend($Sys, $datPath, $data2);
	if ($err2 == 0) {
		# ���X�����ő吔�𒴂�����over�ݒ������
		$resNum = ARAGORN::GetNumFromFile($datPath);
		if ($resNum >= $Sys->Get('RESMAX')) {
			# dat��OVER�X���b�h���X����������
			Get1001Data($Sys, \$data2);
			ARAGORN::DirectAppend($Sys, $datPath, $data2);
			$resNum++;
		}
	}
	# dat�t�@�C���ǋL���s
	elsif ($err2 == 1) {
		$err = $ZP::E_POST_NOTEXISTDAT;
	}
	elsif ($err2 == 2) {
		$err = $ZP::E_LIMIT_STOPPEDTHREAD;
	}
	
	if ($err == $ZP::E_SUCCESS) {
		# subject.txt�̍X�V
		# �X���b�h�쐬���[�h�Ȃ�V�K�ɒǉ�����
		if ($Sys->Equal('MODE', 1)) {
			require './module/earendil.pl';
			my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
			my $Pools = FRODO->new;
			$Pools->Load($Sys);
			$Thread->Add($Sys->Get('KEY'), $elem[0], 1);
			
			while ($Thread->GetNum() > $Sys->Get('SUBMAX')) {
				my $lid = $Thread->GetLastID();
				$Pools->Add($lid, $Thread->Get('SUBJECT', $lid), $Thread->Get('RES', $lid));
				$Thread->Delete($lid);
				EARENDIL::Copy("$path/dat/$lid.dat", "$path/pool/$lid.cgi");
				unlink "$path/dat/$lid.dat";
			}
			
			$Pools->Save($Sys);
			$Thread->Save($Sys);
		}
		# �������݃��[�h�Ȃ烌�X���̍X�V
		else {
			my $sage = (!$Form->Contain('mail', 'sage') ? 1 : 0);
			$Thread->OnDemand($Sys, $Sys->Get('KEY'), $resNum, $sage);
		}
	}
	
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	�O����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my ($this) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	
	# cookie�p�ɃI���W�i����ۑ�����
	my $from = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	$from =~ s/[\r\n]//g;
	$mail =~ s/[\r\n]//g;
	$Form->Set('NAME', $from);
	$Form->Set('MAIL', $mail);
	
	# �L���b�v�p�X�̒��o�ƍ폜
	$Sys->Set('CAPID', '');
	if ($mail =~ s/(?:#|��)(.+)//) {
		my $capPass = $1;
		
		# �L���b�v���ݒ�
		my $capID = $this->{'SECURITY'}->GetCapID($capPass);
		$Sys->Set('CAPID', $capID);
		$Form->Set('mail', $mail);
	}
	
	# dat�p�X�̐���
	my $datPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/' . $Sys->Get('KEY') . '.dat';
	$Sys->Set('DATPATH', $datPath);
	
	# �{���֑������ϊ�
	my $text = $Form->Get('MESSAGE');
	$this->{'CONV'}->ConvertCharacter1(\$text, 2);
	$Form->Set('MESSAGE', $text);
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ݒ��O����
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@param	$res
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeWrite
{
	my $this = shift;
	my ($res) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $capID = $Sys->Get('CAPID', '');
	my $bbs = $Form->Get('bbs');
	my $from = $Form->Get('FROM');
	my $koyuu = $Sys->Get('KOYUU');
	my $client = $Sys->Get('CLIENT');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	
	# �K�����[�U�ENG���[�h�`�F�b�N
	{
		# �K�����[�U
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NGUSER, $bbs)) {
			require './module/faramir.pl';
			my $vUser = FARAMIR->new;
			$vUser->Load($Sys);
			
			my $koyuu2 = ($client & $ZP::C_MOBILE_IDGET & ~$ZP::C_P2 ? $koyuu : undef);
			my $check = $vUser->Check($host, $addr, $koyuu2);
			if ($check == 4) {
				return $ZP::E_REG_NGUSER;
			}
			elsif ($check == 2) {
				return $ZP::E_REG_NGUSER if ($from !~ /$host/i); # $host�͐��K�\��
				$Form->Set('FROM', "</b>[�L��֥�M] <b>$from");
			}
		}
		
		# NG���[�h
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NGWORD, $bbs)) {
			require './module/wormtongue.pl';
			my $ngWord = WORMTONGUE->new;
			$ngWord->Load($Sys);
			my @checkKey = ('FROM', 'mail', 'MESSAGE');
			
			my $check = $ngWord->Check($this->{'FORM'}, \@checkKey);
			if ($check == 3) {
				return $ZP::E_REG_NGWORD;
			}
			elsif ($check == 1) {
				$ngWord->Method($Form, \@checkKey);
			}
			elsif ($check == 2) {
				$Form->Set('FROM', "</b>[�L+��+�M] $host <b>$from");
			}
		}
	}
	
	# plugin�ɓn���l��ݒ�
	$Sys->Set('_ERR', 0);
	$Sys->Set('_NUM_', $res);
	$Sys->Set('_THREAD_', $this->{'THREADS'});
	$Sys->Set('_SET_', $this->{'SET'});
	
	$this->ExecutePlugin(16);
	
	my $text = $Form->Get('MESSAGE');
	$text =~ s/<br>/ <br> /g;
	$Form->Set('MESSAGE', " $text ");
	
	# �������ݒ�
	$from = $Form->Get('FROM');
	if (!$from) {
		$from = $this->{'SET'}->Get('BBS_NONAME_NAME');
		$Form->Set('FROM', $from);
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C������
#	-------------------------------------------------------------------------------------
#	@param	$type
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ExecutePlugin
{
	my $this = shift;
	my ($type) = @_;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Plugin = $this->{'PLUGIN'};
	
	# �L���Ȋg���@�\�ꗗ���擾
	my @pluginSet = ();
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	foreach my $id (@pluginSet) {
		# �^�C�v����Ăяo���̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & $type) {
			my $file = $Plugin->Get('FILE', $id);
			my $className = $Plugin->Get('CLASS', $id);
			
			require "./plugin/$file";
			my $Config = PLUGINCONF->new($Plugin, $id);
			my $command = $className->new($Config);
			$command->execute($Sys, $Form, $type);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���`�F�b�N
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Set = $this->{'SET'};
	my $Sec = $this->{'SECURITY'};
	
	my $bbs = $this->{'FORM'}->Get('bbs');
	my $from = $this->{'FORM'}->Get('FROM');
	my $capID = $Sys->Get('CAPID', '');
	my $datPath = $Sys->Get('DATPATH');
	my $client = $Sys->Get('CLIENT');
	my $mode = $Sys->Get('AGENT');
	my $koyuu = $Sys->Get('KOYUU');
	my $host = $ENV{'REMOTE_HOST'};
	my $addr = $ENV{'REMOTE_ADDR'};
	my $islocalip = 0;
	
	$islocalip = 1 if ($addr =~ /^(127|172|192|10)\./);
	
	# ���X�������݃��[�h���̂�
	if ($Sys->Equal('MODE', 2)) {
		require './module/gondor.pl';
		
		# �ړ]�X���b�h
		return $ZP::E_LIMIT_MOVEDTHREAD if (ARAGORN::IsMoved($datPath));
		
		# ���X�ő吔
		return $ZP::E_LIMIT_OVERMAXRES if ($Sys->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath));
		
		# dat�t�@�C���T�C�Y����
		if ($Set->Get('BBS_DATMAX')) {
			my $datSize = int((stat $datPath)[7] / 1024);
			if ($Set->Get('BBS_DATMAX') < $datSize) {
				return $ZP::E_LIMIT_OVERDATSIZE;
			}
		}
	}
	# REFERER�`�F�b�N
	if ($Set->Equal('BBS_REFERER_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsReferer($this->{'SYS'}, \%ENV)) {
			return $ZP::E_POST_INVALIDREFERER;
		}
	}
	# PROXY�`�F�b�N
	if (!$islocalip && !$Set->Equal('BBS_PROXY_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsProxy($this->{'SYS'}, $this->{'FORM'}, $from, $mode)) {
			#$this->{'FORM'}->Set('FROM', "</b> [�\\{}\@{}\@{}-] <b>$from");
			if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_DNSBL, $bbs)) {
				return $ZP::E_REG_DNSBL;
			}
		}
	}
	# �ǎ��p
	if (!$Set->Equal('BBS_READONLY', 'none')) {
		if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_READONLY, $bbs)) {
			return $ZP::E_LIMIT_READONLY;
		}
	}
	# JP�z�X�g�ȊO�K��
	if (!$islocalip && $Set->Equal('BBS_JP_CHECK', 'checked')) {
		if ($host !~ /\.jp$/i) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTJPHOST, $bbs)) {
				return $ZP::E_REG_NOTJPHOST;
			}
		}
	}
	
	# �X���b�h�쐬���[�h
	if ($Sys->Equal('MODE', 1)) {
		# �X���b�h�L�[���d�����Ȃ��悤�ɂ���
		my $tPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/dat/';
		my $key = $Sys->Get('KEY');
		$key++ while (-e "$tPath$key.dat");
		$Sys->Set('KEY', $key);
		$datPath = "$tPath$key.dat";
		
		# �X���b�h�쐬(�g�т���)
		if ($client & $ZP::C_MOBILE) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_MOBILETHREAD, $bbs)) {
				return $ZP::E_LIMIT_MOBILETHREAD;
			}
		}
		# �X���b�h�쐬(�L���b�v�̂�)
		if ($Set->Equal('BBS_THREADCAPONLY', 'checked')) {
			if (!$Sec->IsAuthority($capID, $ZP::CAP_LIMIT_THREADCAPONLY, $bbs)) {
				return $ZP::E_LIMIT_THREADCAPONLY;
			}
		}
		# �X���b�h�쐬(�X���b�h���Ă���)
		require './module/peregrin.pl';
		my $Log = PEREGRIN->new;
		$Log->Load($Sys, 'THR');
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_MANYTHREAD, $bbs)) {
			my $tateHour = $Set->Get('BBS_TATESUGI_HOUR', '0') - 0;
			my $tateCount = $Set->Get('BBS_TATESUGI_COUNT', '0') - 0;
			my $checkCount = $Set->Get('BBS_THREAD_TATESUGI', '0') - 0;
			if ($tateHour != 0 && $Log->IsTatesugi($tateHour) >= $tateCount) {
				return $ZP::E_REG_MANYTHREAD;
			}
			if ($checkCount != 0 && $Log->Search($koyuu, 3, $mode, $host, $checkCount)) {
				return $ZP::E_REG_MANYTHREAD;
			}
		}
		$Log->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu, undef, $mode);
		$Log->Save($Sys);
		
		# Samba���O
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs) || !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
			my $Logs = PEREGRIN->new;
			$Logs->Load($Sys, 'SMB');
			$Logs->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
			$Logs->Save($Sys);
		}
	}
	# ���X�������݃��[�h
	else {
		require './module/peregrin.pl';
		
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs) || !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
			my $Logs = PEREGRIN->new;
			$Logs->Load($Sys, 'SMB');
			
			my $Logh = PEREGRIN->new;
			$Logh->Load($Sys, 'SBH');
			
			my $n = 0;
			my $tm = 0;
			my $Samba = int($Set->Get('BBS_SAMBATIME', '') eq '' ? $Sys->Get('DEFSAMBA') : $Set->Get('BBS_SAMBATIME'));
			my $Houshi = int($Set->Get('BBS_HOUSHITIME', '') eq '' ? $Sys->Get('DEFHOUSHI') : $Set->Get('BBS_HOUSHITIME'));
			my $Holdtm = int($Sys->Get('SAMBATM'));
			
			# Samba
			if ($Samba && !$Sec->IsAuthority($capID, $ZP::CAP_REG_SAMBA, $bbs)) {
				if ($Houshi) {
					my ($ishoushi, $htm) = $Logh->IsHoushi($Houshi, $koyuu);
					if ($ishoushi) {
						$Sys->Set('WAIT', $htm);
						return $ZP::E_REG_SAMBA_STILL;
					}
				}
				
				($n, $tm) = $Logs->IsSamba($Samba, $koyuu);
			}
				
			# �Z���ԓ��e (Samba�D��)
			if (!$n && $Holdtm && !$Sec->IsAuthority($capID, $ZP::CAP_REG_NOTIMEPOST, $bbs)) {
				$tm = $Logs->IsTime($Holdtm, $koyuu);
			}
			
			$Logs->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
			$Logs->Save($Sys);
			
			if ($n >= 6 && $Houshi) {
				$Logh->Set($Set, $Sys->Get('KEY'), $Sys->Get('VERSION'), $koyuu);
				$Logh->Save($Sys);
				$Sys->Set('WAIT', $Houshi);
				return $ZP::E_REG_SAMBA_LISTED;
			}
			elsif ($n) {
				$Sys->Set('SAMBATIME', $Samba);
				$Sys->Set('WAIT', $tm);
				$Sys->Set('SAMBA', $n);
				return ($n > 3 && $Houshi ? $ZP::E_REG_SAMBA_WARNING : $ZP::E_REG_SAMBA_CAUTION);
			}
			elsif ($tm > 0) {
				$Sys->Set('WAIT', $tm);
				return $ZP::E_REG_NOTIMEPOST;
			}
		}
		
		# ���X��������(�A�����e)
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_NOBREAKPOST, $bbs)) {
			if ($Set->Get('timeclose') && $Set->Get('timecount') ne '') {
				my $Log = PEREGRIN->new;
				$Log->Load($Sys, 'HST');
				my $cnt = $Log->Search($koyuu, 2, $mode, $host, $Set->Get('timecount'));
				if ($cnt >= $Set->Get('timeclose')) {
					return $ZP::E_REG_NOBREAKPOST;
				}
			}
		}
		# ���X��������(��d���e)
		if (!$Sec->IsAuthority($capID, $ZP::CAP_REG_DOUBLEPOST, $bbs)) {
			if ($this->{'SYS'}->Get('KAKIKO') == 1) {
				my $Log = PEREGRIN->new;
				$Log->Load($Sys, 'WRT', $Sys->Get('KEY'));
				if ($Log->Search($koyuu, 1) - 2 == length($this->{'FORM'}->Get('MESSAGE'))) {
					return $ZP::E_REG_DOUBLEPOST;
				}
			}
		}
		
		#$Log->Set($Set, length($this->{'FORM'}->Get('MESSAGE')), $Sys->Get('VERSION'), $koyuu, $datas, $mode);
		#$Log->Save($Sys);
	}
	
	# �p�X��ۑ�
	$Sys->Set('DATPATH', $datPath);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�E���[�����̐��K��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my $this = shift;
	
	my $Sys = $this->{'SYS'};
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $Set = $this->{'SET'};
	
	my $name = $Form->Get('FROM');
	my $mail = $Form->Get('mail');
	my $subject = $Form->Get('subject');
	my $bbs = $Form->Get('bbs');
	my $host = $ENV{'REMOTE_HOST'};
	
	# �L���b�v���擾
	my $capID = $Sys->Get('CAPID', '');
	my $capName = '';
	my $capColor = '';
	if ($capID && $Sec->IsAuthority($capID, $ZP::CAP_DISP_HANLDLE, $bbs)) {
		$capName = $Sec->Get($capID, 'NAME', 1, '');
		$capColor = $Sec->Get($Sec->{'GROUP'}->GetBelong($capID), 'COLOR', 0, '');
		$capColor = $Set->Get('BBS_CAP_COLOR', '') if ($capColor eq '');
	}
	
	# �� -> #
	$this->{'CONV'}->ConvertCharacter0(\$name);
	
	# �g���b�v�ϊ�
	my $trip = '';
	if ($name =~ /\#(.*)$/x) {
		my $key = $1;
		$trip = $this->{'CONV'}->ConvertTrip(\$key, $Set->Get('BBS_TRIPCOLUMN'), $Sys->Get('TRIP12'));
	}
	
	# ���ꕶ���ϊ� �t�H�[�����Đݒ�
	$this->{'CONV'}->ConvertCharacter1(\$name, 0);
	$this->{'CONV'}->ConvertCharacter1(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter1(\$subject, 3);
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	$Form->Set('TRIPKEY', $trip);
	
	# �v���O�C�����s �t�H�[�����Ď擾
	$this->ExecutePlugin($Sys->Get('MODE'));
	$name = $Form->Get('FROM', '');
	$mail = $Form->Get('mail', '');
	$subject = $Form->Get('subject', '');
	$bbs = $Form->Get('bbs');
	$host = $Form->Get('HOST');
	$trip = $Form->Get('TRIPKEY', '???');
	
	# 2ch�݊�
	$name =~ s/^ //;
	
	# �֑������ϊ�
	$this->{'CONV'}->ConvertCharacter2(\$name, 0);
	$this->{'CONV'}->ConvertCharacter2(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter2(\$subject, 3);
	
	# �g���b�v�Ɩ��O����������
	$name =~ s|\#.*$| </b>��$trip <b>|x if ($trip ne '');
	
	# fusiana�ϊ� 2ch�݊�
	$this->{'CONV'}->ConvertFusianasan(\$name, $host);
	
	# �L���b�v������
	if ($capName ne '') {
		$name = ($name ne '' ? "$name��" : '');
		if ($capColor eq '') {
			$name .= "$capName ��";
		}
		else {
			$name .= "<font color=\"$capColor\">$capName ��</font>";
		}
	}
	
	
	# �X���b�h�쐬��
	if ($Sys->Equal('MODE', 1)) {
		return $ZP::E_FORM_NOSUBJECT if ($subject eq '');
		# �T�u�W�F�N�g���̕������m�F
		if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGSUBJECT, $bbs)) {
			if ($Set->Get('BBS_SUBJECT_COUNT') < length($subject)) {
				return $ZP::E_FORM_LONGSUBJECT;
			}
		}
	}
	
	# ���O���̕������m�F
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGNAME, $bbs)) {
		if ($Set->Get('BBS_NAME_COUNT') < length($name)) {
			return $ZP::E_FORM_LONGNAME;
		}
	}
	# ���[�����̕������m�F
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGMAIL, $bbs)) {
		if ($Set->Get('BBS_MAIL_COUNT') < length($mail)) {
			return $ZP::E_FORM_LONGMAIL;
		}
	}
	# ���O���̓��͊m�F
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_NONAME, $bbs)) {
		if ($Set->Equal('NANASHI_CHECK', 'checked') && $name eq '') {
			return $ZP::E_FORM_NONAME;
		}
	}
	
	# ���K���������e���ēx�ݒ�
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	�e�L�X�g���̐��K��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my $this = shift;
	
	my $Form = $this->{'FORM'};
	my $Sec = $this->{'SECURITY'};
	my $Set = $this->{'SET'};
	my $Sys = $this->{'SYS'};
	my $Conv = $this->{'CONV'};
	
	my $bbs = $Form->Get('bbs');
	my $text = $Form->Get('MESSAGE');
	my $host = $Form->Get('HOST');
	my $capID = $this->{'SYS'}->Get('CAPID', '');
	
	# �֑������ϊ�
	$Conv->ConvertCharacter2(\$text, 2);
	
	my ($ln, $cl) = $Conv->GetTextInfo(\$text);
	
	# �{��������
	return $ZP::E_FORM_NOTEXT if ($text eq '');
	
	# �{����������
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGTEXT, $bbs)) {
		if ($Set->Get('BBS_MESSAGE_COUNT') < length($text)) {
			return $ZP::E_FORM_LONGTEXT;
		}
	}
	# ���s��������
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_MANYLINE, $bbs)) {
		if (($Set->Get('BBS_LINE_NUMBER') * 2) < $ln) {
			return $ZP::E_FORM_MANYLINE;
		}
	}
	# 1�s��������
	if (!$Sec->IsAuthority($capID, $ZP::CAP_FORM_LONGLINE, $bbs)) {
		if ($Set->Get('BBS_COLUMN_NUMBER') < $cl) {
			return $ZP::E_FORM_LONGLINE;
		}
	}
	# �A���J�[��������
	if ($Sys->Get('ANKERS')) {
		if ($Conv->IsAnker(\$text, $Sys->Get('ANKERS'))) {
			return $ZP::E_FORM_MANYANCHOR;
		}
	}
	
	# �{���z�X�g�\��
	if (!$Sec->IsAuthority($capID, $ZP::CAP_DISP_NOHOST, $bbs)) {
		if ($Set->Equal('BBS_RAWIP_CHECK', 'checked') && $Sys->Equal('MODE', 1)) {
			$text .= ' <hr> <font color=tomato face=Arial><b>';
			$text .= "$ENV{'REMOTE_ADDR'} , $host , </b></font><br>";
		}
	}
	
	$Form->Set('MESSAGE', $text);
	
	return $ZP::E_SUCCESS;
}

#------------------------------------------------------------------------------------------------------------
#
#	1001�̃��X�f�[�^��ݒ肷��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001���X�i�[�o�b�t�@
#
#------------------------------------------------------------------------------------------------------------
sub Get1001Data
{
	
	my ($Sys, $data) = @_;
	
	my $endPath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/1000.txt';
	
	# 1000.txt�����݂���΂��̓��e�A������΃f�t�H���g��1001���g�p����
	if (open(my $fh, '<', $endPath)) {
		flock($fh, 2);
		$$data = <$fh>;
		close($fh);
	}
	else {
		my $resmax = $Sys->Get('RESMAX');
		my $resmax1 = $resmax + 1;
		my $resmaxz = $resmax;
		my $resmaxz1 = $resmax1;
		$resmaxz =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # �S�p����
		$resmaxz1 =~ s/([0-9])/"\x82".chr(0x4f+$1)/eg; # �S�p����
		
		$$data = "$resmaxz1<><>Over $resmax Thread<>���̃X���b�h��$resmaxz�𒴂��܂����B<br>";
		$$data .= '���������Ȃ��̂ŁA�V�����X���b�h�𗧂ĂĂ��������ł��B�B�B<>' . "\n";
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�z�X�g���O���o�͂���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$data	1001���X�i�[�o�b�t�@
#
#------------------------------------------------------------------------------------------------------------
sub SaveHost
{
	
	my ($Sys, $Form) = @_;
	
	my $bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	my $host = $ENV{'REMOTE_HOST'};
	my $agent = $Sys->Get('AGENT');
	my $koyuu = $Sys->Get('KOYUU');
	
	if ($agent ne '0') {
		if ($agent eq 'P') {
			$host = "$host($koyuu)$ENV{'REMOTE_ADDR'}";
		}
		else {
			$host = "$host($koyuu)";
		}
	}
	
	require './module/imrahil.pl';
	my $Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/log/HOST", $Sys->Get('HSTMAX'), 2 | 4) == 0) {
		$Logger->Put($host, $Sys->Get('KEY'), $Sys->Get('MODE'));
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

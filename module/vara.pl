#============================================================================================================
#
#	�f���������ݎx�����W���[��
#	vara.pl
#	-------------------------------------------------------------------------------------
#	2004.03.27 start
#
#	���낿���˂�v���X
#	2010.08.12 �K���I�𐫓����̂��ߎd�l�ύX
#	2010.08.13 ���O�ۑ��`���ύX�ɂ��d�l�ύX
#	2010.08.15 0ch�{�ƃv���O�C���Ƃ̌݊�������
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
	my $this = shift;
	my $obj = {};
	
	$obj = {
		'SYS'		=> undef,
		'SET'		=> undef,
		'FORM'		=> undef,
		'THREADS'	=> undef,
		'CONV'		=> undef,
		'SECURITY'	=> undef,
		'PLUGIN'	=> undef
	};
	bless $obj, $this;
	
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
	
	$this->{'SYS'}		= $Sys;
	$this->{'FORM'}		= $Form;
	$this->{'SET'}		= $Set;
	$this->{'THREADS'}	= $Thread;
	$this->{'CONV'}		= $Conv;
	
	# ���W���[�����p�ӂ���ĂȂ��ꍇ�͂����Ő�������
	if (! defined $Set) {
		require './module/isildur.pl';
		$this->{'SET'} = ISILDUR->new;
		$this->{'SET'}->Load($Sys);
	}
	if (! defined $Thread) {
		require './module/baggins.pl';
		$this->{'THREADS'} = BILBO->new;
		$this->{'THREADS'}->Load($Sys);
	}
	if (! defined $Conv) {
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
#	���@���F$I   : ISILDUR�I�u�W�F�N�g
#			$M   : MELKOR�I�u�W�F�N�g
#	�߂�l�F�Ȃ�
#
#	2010.08.13 windyakin ��
#	 -> ���O�ۑ��`���ύX�ɂ��K���`�F�b�N�ʒu�̕ύX
#	2010.08.15 �F�X
#	 -> �v���O�C��1,2�̎��s�����ύX
#
#------------------------------------------------------------------------------------------------------------
sub Write
{
	my $this = shift;
	my ($err);
	
	# �������ݑO����
	ReadyBeforeCheck($this);
	
	# ���͓��e�`�F�b�N(���O�A���[��)
	if (($err = NormalizationNameMail($this))) {
		return $err;
	}
	# ���͓��e�`�F�b�N(�{��)
	if (($err = NormalizationContents($this))) {
		return $err;
	}
	
	# �f�[�^�̏�������
	eval {
		my ($oSys, $oSet, $oForm, $oConv);
		my (@elem, $date, $data, $data2, $resNum, $datPath, $id);
		
		require './module/gondor.pl';
		$oSys	= $this->{'SYS'};
		$oSet	= $this->{'SET'};
		$oForm	= $this->{'FORM'};
		$oConv	= $this->{'CONV'};
		
		# �������ݒ��O����
		if ($err = ReadyBeforeWrite($this, ARAGORN::GetNumFromFile($oSys->Get('DATPATH')) + 1)) {
			return $err;
		}
		
		# ���X�v�f�̎擾
		$oForm->GetListData(\@elem, 'subject', 'FROM', 'mail', 'MESSAGE');
		
		$err		= 0;
		$id			= $oConv->MakeID($oSys->Get('SERVER'), 8);
		$date		= $oConv->GetDate($oSet);
		$date		.= $oConv->GetIDPart($oSet, $oForm, $this->{'SECURITY'}, $id, $oSys->Get('CAPID'), $oSys->Get('AGENT'));
		$data		= join('<>', $elem[1], $elem[2], $date, $elem[3], $elem[0]);
		$data2		= "$data\n";
		$datPath	= $oSys->Get('DATPATH');
		
		# �K���`�F�b�N
		# �Ȃ�����ȂƂ���ɁH -> http://yakin.38-ch.net/test/read.cgi/windyakin/1281101424/597
		if ($err = IsRegulation($this, $data)) {
			return $err;
		}
		
		# �����[�g�z�X�g�ۑ�(SETTING.TXT�ύX�ɂ��A��ɕۑ�)
		SaveHost($oSys, $oForm);
		
		# dat�t�@�C���֒��ڏ�������
		eval {
			if (($err = ARAGORN::DirectAppend($oSys, $datPath, $data2)) == 0) {
				# ���X�����ő吔�𒴂�����over�ݒ������
				if (($resNum = ARAGORN::GetNumFromFile($datPath)) >= $oSys->Get('RESMAX')) {
					# dat��OVER�X���b�h���X����������
					Get1001Data($oSys, \$data2);
					ARAGORN::DirectAppend($oSys, $datPath, $data2);
					$resNum++;
				}
				# ����ۑ�
				SaveHistory($oSys, $oForm, ARAGORN::GetNumFromFile($datPath));
			}
			# dat�t�@�C���ǋL���s
			else {
				$err = 999 if ($err == 1);
				$err = 200 if ($err == 2);
			}
		};
		if ($err == 0 && $@ eq '') {
			# subject.txt�̍X�V
			# �X���b�h�쐬���[�h�Ȃ�V�K�ɒǉ�����
			if ($oSys->Equal('MODE', 1)) {
				$this->{'THREADS'}->Add($oSys->Get('KEY'), $elem[0], 1);
			}
			# �������݃��[�h�Ȃ烌�X���̍X�V
			else {
				$this->{'THREADS'}->Set($oSys->Get('KEY'), 'RES', $resNum);
				# sage�������Ă��Ȃ�������age��
				if (!$oForm->Contain('mail', 'sage')) {
					$this->{'THREADS'}->AGE($oSys->Get('KEY'));
				}
			}
			$this->{'THREADS'}->Save($oSys);
		}
	};
	return $err;
}

#------------------------------------------------------------------------------------------------------------
#
#	�O����
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	�Ȃ�
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeCheck
{
	my ($this) = @_;
	my ($Sys, $Form, @pluginSet, $capPass, $capID);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	
	# cookie�p�ɃI���W�i����ۑ�����
	my ($from, $mail);
	$from = $Form->Get('FROM');
	$mail = $Form->Get('mail');
	$from =~ s/\n//g;
	$mail =~ s/\n//g;
	$Form->Set('NAME', $from);
	$Form->Set('MAIL', $mail);
	
	# �L���b�v�p�X�̒��o�ƍ폜
	if ($mail =~ /(#|��)(.+)/) {
		$mail =~ s/��/#/;
		$mail =~ s/#(.+)//;
		$capPass = $1;
		
		# �L���b�v���ݒ�
		$capID = $this->{'SECURITY'}->GetCapID($capPass);
		$Form->Set('mail', $mail);
	}
	$capID = '' if (! defined $capID);
	$Sys->Set('CAPID', $capID);
	
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
#	@param	$this
#	@param	$res
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub ReadyBeforeWrite
{
	my ($this, $res) = @_;
	my ($Sys, $Form, @pluginSet, $text, $host, $from);
	
	$Sys	= $this->{'SYS'};
	$Form	= $this->{'FORM'};
	$host	= $this->{'FORM'}->Get('HOST');
	$from	= $this->{'FORM'}->Get('FROM');
	
	# �K�����[�U�ENG���[�h�`�F�b�N
	{
		my ($vUser, $ngWord, $check, @checkKey);
		# �K�����[�U
		require './module/faramir.pl';
		$vUser = FARAMIR->new;
		$vUser->Load($Sys);
		$check = $vUser->Check($host);
		if ($check == 4) {
			return 601;
		}
		if ($check == 2) {
			if ($from =~ /$host/i) {
				$this->{'FORM'}->Set('FROM', "</b>[�L��֥�M] <b>$from");
			}
			else {
				return 601;
			}
		}
		
		# NG���[�h
		require './module/wormtongue.pl';
		$ngWord = WORMTONGUE->new;
		$ngWord->Load($Sys);
		@checkKey = ('FROM', 'mail', 'MESSAGE');
		$check = $ngWord->Check($this->{'FORM'}, \@checkKey);
		if ($check == 3) {
			return 600;
		}
		if ($check == 1) {
			$ngWord->Method($this->{'FORM'}, \@checkKey);
		}
		if ($check == 2) {
			$this->{'FORM'}->Set('FROM', "$from<font color=\"tomato\">$host</font>");
		}
	}
	
	# plugin�ɓn���l��ݒ�
	$Sys->Set('_ERR', 0);
	$Sys->Set('_NUM_', $res);
	$Sys->Set('_THREAD_', $this->{'THREADS'});
	$Sys->Set('_SET_', $this->{'SET'});
	
	$this->ExecutePlugin(16);
	
	$text = $Form->Get('MESSAGE');
	$text =~ s/<br>/ <br> /g;
	$Form->Set('MESSAGE', " $text ");
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C������
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@param	$type
#	@return	�Ȃ�
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub ExecutePlugin
{
	my ($this, $type) = @_;
	my ($Sys, $Form, $Plugin, $id, @pluginSet, $Config);
	
	$Sys = $this->{'SYS'};
	$Form = $this->{'FORM'};
	$Plugin = $this->{'PLUGIN'};
	
	# �L���Ȋg���@�\�ꗗ���擾
	$Plugin->GetKeySet('VALID', 1, \@pluginSet);
	foreach $id (@pluginSet) {
		# �^�C�v����Ăяo���̏ꍇ�̓��[�h���Ď��s
		if ($Plugin->Get('TYPE', $id) & $type) {
			my ($file, $className, $command, $config);
			$file = $Plugin->Get('FILE', $id);
			$className = $Plugin->Get('CLASS', $id);
			require "./plugin/$file";
			$Config = PLUGINCONF->new($Plugin, $id);
			$command = $className->new($Config);
			$command->execute($Sys, $Form, $type);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���`�F�b�N
#	-------------------------------------------------------------------------------------
#	@param	$this, $datas
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#	2010.08.12 windyakin ��
#	 -> �Q�d�������̋K����I�𐫂ɂ����̂ŕύX
#	 -> �K�����[�U�[�z�X�g�\�����̂̎d�l�ύX
#
#	2010.08.13 windyakin ��
#	 -> ���O�o�͌`���ύX�ɂ������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub IsRegulation
{
	my ($this, $datas) = @_;
	my ($oSYS, $oSET, $oSEC);
	my ($err, $host, $bbs, $datPath, $capID, $Samba, $from, $mode);
	
	$oSYS		= $this->{'SYS'};
	$oSET		= $this->{'SET'};
	$oSEC		= $this->{'SECURITY'};
	$host		= $this->{'FORM'}->Get('HOST');
	$bbs		= $this->{'FORM'}->Get('bbs');
	$from		= $this->{'FORM'}->Get('FROM');
	$capID		= $oSYS->Get('CAPID');
	$datPath	= $oSYS->Get('DATPATH');
	$Samba		= $oSYS->Get('SAMBA');
	$mode		= $oSYS->Get('AGENT');
	
	# ���X�������݃��[�h���̂�
	if ($oSYS->Equal('MODE', 2)) {
		require './module/gondor.pl';
		
		# �ړ]�X���b�h
		if (ARAGORN::IsMoved($datPath)) {
			return 202;
		}
		# ���X�ő吔
		if ($oSYS->Get('RESMAX') < ARAGORN::GetNumFromFile($datPath)) {
			return 201;
		}
		# dat�t�@�C���T�C�Y����
		if ($oSET->Get('BBS_DATMAX')) {
			my $datSize = int((stat $datPath)[7] / 1024);
			if ($oSET->Get('BBS_DATMAX') < $datSize) {
				return 206;
			}
		}
	}
	# REFERER�`�F�b�N
	if ($oSET->Equal('BBS_REFERER_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsReferer($this->{'SYS'}, \%ENV)) {
			return 998;
		}
	}
	# PROXY�`�F�b�N
	if ($oSET->Equal('BBS_PROXY_CHECK', 'checked')) {
		if ($this->{'CONV'}->IsProxy(\$host)) {
			$this->{'FORM'}->Set('FROM', "</b> [�\{}\@{}\@{}-] <b>$from");
			return 997 if (! $oSEC->IsAuthority($capID, 19, $bbs));
		}
	}
	# �ǎ��p
	if (!$oSET->Equal('BBS_READONLY', 'none')) {
		if (! $oSEC->IsAuthority($capID, 13, $bbs)) {
			return 203;
		}
	}
	# JP�z�X�g�ȊO�K��
	if ($oSET->Equal('BBS_JP_CHECK', 'checked')) {
		unless ($host =~ /\.(jp|JP)$/) {
			return 207;
		}
	}
	
	# �X���b�h�쐬���[�h
	if ($oSYS->Equal('MODE', 1)) {
		# �X���b�h�L�[���d�����Ȃ��悤�ɂ���
		my $tPath = $oSYS->Get('BBSPATH') . '/' . $oSYS->Get('BBS') . '/dat/';
		my $key = $oSYS->Get('KEY');
		while (-e "$tPath$key.dat") {
			$key++;
		}
		$oSYS->Set('KEY', $key);
		$datPath = "$tPath$key.dat";
		
		# �X���b�h�쐬(�g�т���)
		if ($oSYS->Get('AGENT') eq "O") {
			if (! $oSEC->IsAuthority($capID, 16, $bbs)) {
				return 204;
			}
		}
		# �X���b�h�쐬(�L���b�v�̂�)
		if ($oSET->Equal('BBS_THREADCAPONLY', 'checked')) {
			if (! $oSEC->IsAuthority($capID, 9, $bbs)) {
				return 504;
			}
		}
		# �X���b�h�쐬(�X���b�h���Ă���)
		require './module/peregrin.pl';
		my $LOG = PEREGRIN->new;
		$LOG->Load($oSYS, 'THR');
		if (! $oSEC->IsAuthority($capID, 8, $bbs)) {
			if ($LOG->Search($host, 1)) {
				return 500;
			}
		}
		$LOG->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $host);
		$LOG->Save($oSYS);
	}
	# ���X�������݃��[�h
	else {
		require './module/peregrin.pl';
		my $LOGs = PEREGRIN->new;
		$LOGs->Load($oSYS, 'SMB');
		$LOGs->Set($oSET, $oSYS->Get('KEY'), $oSYS->Get('VERSION'), $host);
		$LOGs->Save($oSYS);
		
		# SAMBA
		if (! $oSEC->IsAuthority($capID, 12, $bbs)) {
			my ($n, $tm) = $LOGs->IsSamba($Samba, $host);
			if ($tm > 0) {
				$oSYS->Set('WAIT', $tm);
				$oSYS->Set('SAMBA', $n);
				$oSYS->Set('SAMBATM', $Samba);
				return 505;
			}
		}
		
		my $LOG = PEREGRIN->new;
		$LOG->Load($oSYS, 'WRT', $oSYS->Get('KEY'));
		
		# ���X��������(�A�����e)
		if (! $oSEC->IsAuthority($capID, 10, $bbs)) {
			if ($LOG->Search($host, 2) >= $oSET->Get('timeclose')) {
			#	return 501;
			}
		}
		# ���X��������(��d���e)
		if (! $oSEC->IsAuthority($capID, 11, $bbs)) {
			if ($this->{'SYS'}->Get('KAKIKO') eq 1) {
				if ($LOG->Search($host, 1) == length($this->{'FORM'}->Get('MESSAGE'))) {
					return 502;
				}
			}
		}
		
=for
		# �Z���ԓ��e
		if (!$oSEC->IsAuthority($capID, 12, $bbs)) {
			my $tm = $LOG->IsTime($Samba, $host);
			if ($tm > 0) {
				$oSYS->Set('WAIT', $tm);
				return 503;
			}
		}
=cut
		$LOG->Set($oSET, length($this->{'FORM'}->Get('MESSAGE')), $oSYS->Get('VERSION'), $host, $datas, $mode);
		$LOG->Save($oSYS);
	}
	
	# �p�X��ۑ�
	$oSYS->Set('DATPATH', $datPath);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���O�E���[�����̐��K��
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#	2010.08.12 windyakin ��
#	 -> �g���b�v�ϊ������̏��Ԃ�ύX(�֑�����,fusianasan�ϊ��̑O��)
#	 -> ������ϊ������̏��Ԃ�ύX(�������`�F�b�N�̑O��)
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationNameMail
{
	my ($this) = @_;
	my ($Form, $oSEC, $oSET, $Sys);
	my ($name, $mail, $subject, $bbs, $capName, $capID, $key, $host);
	
	$Sys		= $this->{'SYS'};
	$Form		= $this->{'FORM'};
	$oSEC		= $this->{'SECURITY'};
	$oSET		= $this->{'SET'};
	
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$subject	= $Form->Get('subject');
	$bbs		= $Form->Get('bbs');
	$host		= $Form->Get('HOST');
	
	# �L���b�v���擾
	$capID = $Sys->Get('CAPID');
	if ($capID && $oSEC->IsAuthority($capID, 17, $bbs)) {
		$capName = $oSEC->Get($capID, 'NAME', 1);
	}
	
	# �g���b�v�L�[��؂藣��
	if ($name =~ /#(.+)$/) {
		$key = $1;
		
		# �g���b�v�ϊ�
		$key = $this->{'CONV'}->ConvertTrip(\$key, $oSET->Get('BBS_TRIPCOLUMN'), $Sys->Get('TRIP12'));
	}
	else {
		$key = '';
	}
	
	# ���ꕶ���ϊ� �t�H�[�����Đݒ�
	$this->{'CONV'}->ConvertCharacter1(\$name, 0);
	$this->{'CONV'}->ConvertCharacter1(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter1(\$subject, 3);
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	# �v���O�C�����s �t�H�[�����Ď擾
	$this->ExecutePlugin($Sys->Get('MODE'));
	$name		= $Form->Get('FROM');
	$mail		= $Form->Get('mail');
	$subject	= $Form->Get('subject');
	$bbs		= $Form->Get('bbs');
	$host		= $Form->Get('HOST');
	
	# 2ch�݊�
	$name = substr($name, 1) if (index($name, ' ') == 0);
	
	# �֑������ϊ�
	$this->{'CONV'}->ConvertCharacter2(\$name, 0);
	$this->{'CONV'}->ConvertCharacter2(\$mail, 1);
	$this->{'CONV'}->ConvertCharacter2(\$subject, 3);
	
	# �g���b�v�Ɩ��O����������
	$name =~ s|#.+$| </b>��$key <b>|;
	
	# fusiana�ϊ� 2ch�݊�
	$name =~ s:fusianasan|�R���:</b>$host<b>:;
	$name =~ s:fusianasan|�R���: </b>$host<b>:g;
	
	# �L���b�v������
	if (defined $capName && $capName ne '') {
		$name = ($Form->Get('NAME') ? "$name��" : '') . "$capName ��";
	}
	
	
	# �X���b�h�쐬��
	if ($Sys->Equal('MODE', 1)) {
		if ($subject eq '') {
			return 150;
		}
		# �T�u�W�F�N�g���̕������m�F
		if (! $oSEC->IsAuthority($capID, 1, $bbs)) {
			if ($oSET->Get('BBS_SUBJECT_COUNT') < length($subject)) {
				return 101;
			}
		}
	}
	
	# ���O���̕������m�F
	if (! $oSEC->IsAuthority($capID, 2, $bbs)) {
		if ($oSET->Get('BBS_NAME_COUNT') < length($name)) {
			return 101;
		}
	}
	# ���[�����̕������m�F
	if (! $oSEC->IsAuthority($capID, 3, $bbs)) {
		if ($oSET->Get('BBS_MAIL_COUNT') < length($mail)) {
			return 102;
		}
	}
	# ���O���̓��͊m�F
	if (! $oSEC->IsAuthority($capID, 7, $bbs)) {
		if ($oSET->Equal('NANASHI_CHECK', 'checked') && $name eq '') {
			return 152;
		}
	}
	# �������ݒ�
	unless ($name) { $name = $oSET->Get('BBS_NONAME_NAME'); }
	unless ($mail) { $mail = ''; }
	
	# ���K���������e���ēx�ݒ�
	$Form->Set('FROM', $name);
	$Form->Set('mail', $mail);
	$Form->Set('subject', $subject);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�e�L�X�g���̐��K��
#	-------------------------------------------------------------------------------------
#	@param	$this
#	@return	�K���ʉ߂Ȃ�0��Ԃ�
#			�K���`�F�b�N�ɂ���������G���[�R�[�h��Ԃ�
#
#	2010.08.15 �F�X
#	 -> �v���O�C���݊����ێ��ɂ����������̕ύX
#
#------------------------------------------------------------------------------------------------------------
sub NormalizationContents
{
	my ($Sys) = @_;
	my ($Form, $oSEC, $oSET);
	my ($text, $bbs, $host, $ln, $cl, $capID);
	
	$Form		= $Sys->{'FORM'};
	$oSEC		= $Sys->{'SECURITY'};
	$oSET		= $Sys->{'SET'};
	$bbs		= $Form->Get('bbs');
	$text		= $Form->Get('MESSAGE');
	$host		= $Form->Get('HOST');
	$capID		= $Sys->{'SYS'}->Get('CAPID');
	
	# �֑������ϊ�
	$Sys->{'CONV'}->ConvertCharacter2(\$text, 2);
	
	($ln, $cl)	= $Sys->{'CONV'}->GetTextInfo(\$text);
	
	# �{��������
	if ($text eq '') {
		return 151;
	}
	# �{����������
	if (! $oSEC->IsAuthority($capID, 4, $bbs)) {
		if ($oSET->Get('BBS_MESSAGE_COUNT') < length($text)) {
			return 103;
		}
	}
	# ���s��������
	if (! $oSEC->IsAuthority($capID, 5, $bbs)) {
		if (($oSET->Get('BBS_LINE_NUMBER') * 2) < $ln) {
			return 105;
		}
	}
	# 1�s��������
	if (! $oSEC->IsAuthority($capID, 6, $bbs)) {
		if ($oSET->Get('BBS_COLUMN_NUMBER') < $cl) {
			return 104;
		}
	}
	# �A���J�[��������
	if ($Sys->{'SYS'}->Get('ANKERS')) {
		if ($Sys->{'CONV'}->IsAnker(\$text, $Sys->{'SYS'}->Get('ANKERS'))) {
			return 106;
		}
	}
	
	# �{���z�X�g�\��
	if (! $oSEC->IsAuthority($capID, 15, $bbs)) {
		if ($oSET->Equal('BBS_RAWIP_CHECK', 'checked') && $Sys->{'SYS'}->Equal('MODE', 1)) {
			$text .= ' <hr> <font color=tomato face=Arial><b>';
			$text .= "$ENV{'REMOTE_ADDR'} , $host , </b></font><br>";
		}
	}
	
	$Form->Set('MESSAGE', $text);
	
	return 0;
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
	if (-e $endPath) {
		open LAST, $endPath;
		while (<LAST>) {
			$$data = $_;
			last;
		}
		close LAST;
	}
	else {
		$$data = '�P�O�O�P<><>Over 1000 Thread<>���̃X���b�h�͂P�O�O�O�𒴂��܂����B<br>';
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
	my ($Logger, $bbs);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/log/HOST", 500, 2 | 4) == 0) {
		$Logger->Put($Form->Get('HOST'), $Sys->Get('KEY'), $Sys->Get('MODE'));
		$Logger->Write();
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�������O���o�͂���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$resNum	�������݃��X��
#
#------------------------------------------------------------------------------------------------------------
sub SaveHistory
{
	my ($Sys, $Form, $resNum) = @_;
	my ($Logger, $bbs, $threadInfo, $name, $content);
	
	$bbs = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	$threadInfo = $Sys->Get('BBS') . ',' . $Sys->Get('KEY');
	$name = $Form->Get('FROM');
	$content = $Form->Get('MESSAGE');
	
	require './module/imrahil.pl';
	$Logger = IMRAHIL->new;
	
	if ($Logger->Open("$bbs/info/history", $Sys->Get('HISMAX'), 2 | 4) == 0) {
		$Logger->Put($threadInfo, $resNum, $content, $name);
		$Logger->Write();
	}
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

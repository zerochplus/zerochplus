#============================================================================================================
#
#	�V�X�e���Ǘ� - ���[�U ���W���[��
#
#============================================================================================================
package	MODULE;

use strict;
use warnings;
no warnings 'redefine';

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
		'LOG'	=> [],
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\�����\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoPrint
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	# �Ǘ��}�X�^�I�u�W�F�N�g�̐���
	require './mordor/sauron.pl';
	my $Base = SAURON->new;
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# �ʒm�ꗗ���
	if ($subMode eq 'NOTICE') {
		CheckVersionUpdate($Sys);
		$indata = PreparePageNoticeList($Sys, $Form);
	}
	# �ʒm�ꗗ���
	elsif ($subMode eq 'NOTICE_CREATE') {
		$indata = PreparePageNoticeCreate($Sys, $Form);
	}
	# ���O�{�����
	elsif ($subMode eq 'ADMINLOG') {
		$indata = PreparePageAdminLog($Sys, $Form, $CGI->{'LOGGER'});
	}
	# �ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('���[�U�ʒm����', $this->{'LOG'});
	}
	# �ݒ莸�s���
	elsif ($subMode eq 'FALSE') {
		$indata = $Base->PreparePageError($this->{'LOG'});
	}
	
	$Base->Print($Sys->Get('_TITLE'), 1, $indata);
}

#------------------------------------------------------------------------------------------------------------
#
#	�@�\���\�b�h
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Form	SAMWISE
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub DoFunction
{
	my $this = shift;
	my ($Sys, $Form, $CGI) = @_;
	
	my $subMode = $Form->Get('MODE_SUB');
	my $err = 0;
	
	# �ʒm�쐬
	if ($subMode eq 'CREATE') {
		$err = FunctionNoticeCreate($Sys, $Form, $this->{'LOG'});
	}
	# �ʒm�폜
	elsif ($subMode eq 'DELETE') {
		$err = FunctionNoticeDelete($Sys, $Form, $this->{'LOG'});
	}
	# ���샍�O�폜
	elsif ($subMode eq 'LOG_REMOVE') {
		$err = FunctionLogRemove($Sys, $Form, $CGI->{'LOGGER'}, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'), "SYSTEM_TOP($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('���[�U�ʒm�ꗗ', "'sys.top','DISP','NOTICE'");
	$Base->SetMenu('���[�U�ʒm�쐬', "'sys.top','DISP','NOTICE_CREATE'");
	
	# �V�X�e���Ǘ������̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('', '');
		$Base->SetMenu('���샍�O�{��', "'sys.top','DISP','ADMINLOG'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�ꗗ�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageNoticeList
{
	my ($Sys, $Form) = @_;
	
	require './module/galadriel.pl';
	require './module/gandalf.pl';
	
	# �ʒm���̓ǂݍ���
	my $Notices = GANDALF->new;
	$Notices->Load($Sys);
	
	my @noticeSet = ();
	$Notices->GetKeySet('ALL', '', \@noticeSet);
	@noticeSet = reverse sort @noticeSet;
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# �\�����̐ݒ�
	my $listnum = scalar(@noticeSet);
	my $dispnum = int($Form->Get('DISPNUM_NOTICE', 5) || 5);
	my $dispst = &$max(int($Form->Get('DISPST_NOTICE') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	my $CGI = $Sys->Get('ADMIN');
	my $user = $CGI->{'USER'};
	
	# �ʒm�ꗗ���o��
	my $displist = [];
	while ($nextnum < $listnum) {
		my $id = $noticeSet[$nextnum++];
		
		if ($Notices->IsInclude($id, $user) && ! $Notices->IsLimitOut($id)) {
			my $from;
			if ($Notices->Get('FROM', $id) eq '0000000000') {
				$from = '0ch+�Ǘ��V�X�e��';
			}
			else {
				$from = $CGI->{'SECINFO'}->{'USER'}->Get('NAME', $Notices->Get('FROM', $id));
			}
			
			push @$displist, {
				'id'		=> $id,
				'from'		=> $from,
				'subject'	=> $Notices->Get('SUBJECT', $id),
				'text'		=> $Notices->Get('TEXT', $id),
				'date'		=> GALADRIEL->GetDateFromSerial($Notices->Get('DATE', $id), 0),
			};
			last if (scalar(@$displist) >= $dispnum);
		}
	}
	
	my $indata = {
		'title'		=> 'User Notice List',
		'intmpl'	=> 'sys.top.noticelist',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'notices'	=> $displist,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�쐬��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageNoticeCreate
{
	my ($Sys, $Form) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	my $Sec = $CGI->{'SECINFO'};
	my $User = $Sec->{'USER'};
	
	my $issysad = $Sec->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*');
	
	my @userSet = ();
	$User->GetKeySet('ALL', '', \@userSet);
	
	my $users = [];
	foreach my $id (@userSet) {
		push @$users, {
			'id'		=> $id,
			'name'		=> $User->Get('NAME', $id),
			'fullname'	=> $User->Get('FULL', $id),
		};
	}
	my $indata = {
		'title'		=> 'User Notice Create',
		'intmpl'	=> 'sys.top.noticecreate',
		'issysad'	=> $issysad,
		'users'		=> $users,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�Ǘ����샍�O�{����ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageAdminLog
{
	my ($Sys, $Form, $Logger) = @_;
	
	my $CGI = $Sys->Get('ADMIN');
	
	my $max = sub { $_[0] > $_[1] ? $_[0] : $_[1] };
	
	# �\�����̐ݒ�
	my $listnum = $Logger->Size();
	my $dispnum = int($Form->Get('DISPNUM_LOG', 10) || 10);
	my $dispst = &$max(int($Form->Get('DISPST_LOG') || 0), 0);
	my $prevnum = &$max($dispst - $dispnum, 0);
	my $nextnum = $dispst;
	
	require './module/galadriel.pl';
	
	# ���O�ꗗ���o��
	my $displog = [];
	while ($nextnum < $listnum) {
		my $data = $Logger->Get($listnum - $nextnum++ - 1);
		my @elem = split(/<>/, $data, -1);
		
		push @$displog, {
			'date'		=> $elem[0],
			'user'		=> $elem[1],
			'operation'	=> $elem[2],
			'result'	=> $elem[3],
		};
		last if (scalar(@$displog) >= $dispnum);
	}
	
	my $indata = {
		'title'		=> 'Operation Log',
		'intmpl'	=> 'sys.top.adminlog',
		'dispnum'	=> $dispnum,
		'prevnum'	=> $prevnum,
		'nextnum'	=> $nextnum,
		'logs'		=> $displog,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���[�U�ʒm�쐬
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeCreate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$cuser) {
		return 1000;
	}
	
	# ���̓`�F�b�N
	if ('input check') {
		my $inList = ['NOTICE_TITLE', 'NOTICE_CONTENT'];
		if (!$Form->IsInput($inList)) {
			return 1001;
		}
		$inList = ['NOTICE_LIMIT'];
		if ($Form->Equal('NOTICE_KIND', 'ALL') && !$Form->IsInput($inList)) {
			return 1001;
		}
		$inList = ['NOTICE_USERS'];
		if ($Form->Equal('NOTICE_KIND', 'ONE') && !$Form->IsInput($inList)) {
			return 1001;
		}
	}
	
	require './module/gandalf.pl';
	my $Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	my $date = time;
	my $subject = $Form->Get('NOTICE_TITLE');
	my $content = $Form->Get('NOTICE_CONTENT');
	my $users = '*';
	my $limit = 0;
	
	require './module/galadriel.pl';
	GALADRIEL->ConvertCharacter1(\$subject, 0);
	GALADRIEL->ConvertCharacter1(\$content, 2);
	
	if ($Form->Equal('NOTICE_KIND', 'ALL')) {
		$limit = int($Form->Get('NOTICE_LIMIT', 0) || 0);
		$limit = $date + ($limit * 24 * 60 * 60);
	}
	else {
		$users = join(',', $Form->GetAtArray('NOTICE_USERS'));
	}
	
	# �ʒm����ǉ�
	$Notice->Add($users, $cuser, $subject, $content, $limit);
	$Notice->Save($Sys);
	
	push @$pLog, '���[�U�ւ̒ʒm�I��';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ʒm�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionNoticeDelete
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$cuser) {
		return 1000;
	}
	
	require './module/gandalf.pl';
	my $Notice = GANDALF->new;
	$Notice->Load($Sys);
	
	foreach my $id ($Form->GetAtArray('NOTICES')) {
		my $subj = $Notice->Get('SUBJECT', $id);
		# ���݂��Ȃ��ʒm
		next if (!defined $subj);
		# �S�̒ʒm
		if ($Notice->Get('TO', $id) eq '*') {
			if ($Notice->Get('FROM', $id) ne $cuser) {
				push @$pLog, "�ʒm�u$subj�v�͑S�̒ʒm�Ȃ̂ō폜�ł��܂���ł����B";
			}
			else {
				$Notice->Delete($id);
				push @$pLog, "�S�̒ʒm�u$subj�v���폜���܂����B";
			}
		}
		# �ʒʒm
		else {
			$Notice->RemoveToUser($id, $cuser);
			push @$pLog, "�ʒm�u$subj�v���폜���܂����B";
		}
	}
	
	$Notice->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���샍�O�폜
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$Logger	
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLogRemove
{
	my ($Sys, $Form, $Logger, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*')) {
		return 1000;
	}
	
	$Logger->Clear();
	push @$pLog, '���샍�O���폜���܂����B';
	
	return 0;
}


sub CheckVersionUpdate
{
	my ($Sys) = @_;
	
	my $Release = $Sys->Get('ADMIN')->{'NEWRELEASE'};
	
	if ($Release->Get('Update')) {
		my $newver = $Release->Get('Ver');
		my $reldate = $Release->Get('Date');
		
		# ���[�U�ʒm ����
		require './module/gandalf.pl';
		my $Notice = GANDALF->new;
		$Notice->Load($Sys);
		my $nid = 'verupnotif';
		
		# �ʒm����
		use Time::Local;
		$_ = [split /\./, $reldate];
		my $date = timelocal(0, 0, 0, $_->[2], $_->[1]-1, $_->[0]);
		my $limit = 0;
		
		# �ʒm���e
		my $note = join('<br>', @{$Release->Get('Detail')});
		my $subject = "0ch+ New Version $newver is Released.";
		my $content = "<!-- \*Ver=$newver\* --> $note";
		
		# �ʒm�� 0ch+�Ǘ��V�X�e��
		my $from = '0000000000';
		
		# �ʒm�� �Ǘ��Ҍ����������[�U
		require './module/elves.pl';
		my $User = GLORFINDEL->new;
		$User->Load($Sys);
		my @toSet = ();
		$User->GetKeySet('SYSAD', 1, \@toSet);
		my $users = join(',', @toSet, 'nouser');
		
		# �ʒm��ǉ�
		if ($Notice->Get('TEXT', $nid, '') =~ /\*Ver=(.+?)\*/ && $1 eq $newver) {
			$Notice->{'TO'}->{$nid}			= $users;
			$Notice->{'TEXT'}->{$nid}		= $content;
			$Notice->{'DATE'}->{$nid}		= $date;
		}
		else {
			#$Notice->Add($users, $from, $subject, $content, $limit);
			$Notice->{'TO'}->{$nid}			= $users;
			$Notice->{'FROM'}->{$nid}		= $from;
			$Notice->{'SUBJECT'}->{$nid}	= $subject;
			$Notice->{'TEXT'}->{$nid}		= $content;
			$Notice->{'DATE'}->{$nid}		= $date;
			$Notice->{'LIMIT'}->{$nid}		= $limit;
			$Notice->Save($Sys);
		}
	}
	
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

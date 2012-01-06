#============================================================================================================
#
#	�������W���[��(BALROGS)
#	balrogs.pl
#	-------------------------------------------------------------------------------------
#	2003.11.22 start
#	2004.09.18 �V�X�e�����ςɔ����ύX
#
#============================================================================================================
package	BALROGS;

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
	my ($obj);
	
	$obj = {
		'SYS'		=> undef,
		'TYPE'		=> undef,
		'SEARCHSET'	=> undef,
		'RESULTSET'	=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$SYS    : MELKOR
#	@param	$mode   : 0:�S����,1:BBS������,2:�X���b�h������
#	@param	$type   : 0:�S����,1:���O����,2:�{������
#			          4:ID(���t)����
#	@param	$bbs    : ����BBS��($mode=1�̏ꍇ�Ɏw��)
#	@param	$thread : �����X���b�h��($mode=2�̏ꍇ�Ɏw��)
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Create
{
	my $this = shift;
	my ($SYS, $mode, $type, $bbs, $thread) = @_;
	my ($pSearchSet, $dir, $set);
	
	$this->{'SYS'} = $SYS;
	$this->{'TYPE'} = $type;
	undef @{$this->{'SEARCHSET'}};
	$pSearchSet = $this->{'SEARCHSET'};
	
	# �I���S����
	if ($mode == 0) {
		require './module/baggins.pl';
		require './module/nazguls.pl';
		my $BBSs = NAZGUL->new;
		my $Threads = BILBO->new;
		my (@bbsSet, @threadSet, $bbsID, $threadID, $set, $BBSpath);
		
		$BBSs->Load($SYS);
		$BBSs->GetKeySet('ALL', '', \@bbsSet);
		
		$BBSpath = $SYS->Get('BBSPATH');
		
		foreach $bbsID (@bbsSet) {
			$dir = $BBSs->Get('DIR', $bbsID);
			
			# �f�B���N�g����.0ch_hidden�Ƃ����t�@�C��������Γǂݔ�΂�
			next if ( -e "$BBSpath/$dir/.0ch_hidden" );
			
			$SYS->Set('BBS', $dir);
			$Threads->Load($SYS);
			$Threads->GetKeySet('ALL', '', \@threadSet);
			
			foreach $threadID (@threadSet) {
				$set = "$dir<>$threadID";
				push @$pSearchSet, $set;
			}
			undef @threadSet;
		}
	}
	# �f�����S����
	elsif ($mode == 1) {
		require './module/baggins.pl';
		my $Threads = BILBO->new;
		my (@threadSet, $threadID, $set);
		
		$SYS->Set('BBS', $bbs);
		$Threads->Load($SYS);
		$Threads->GetKeySet('ALL', '', \@threadSet);
		
		foreach $threadID (@threadSet) {
			$set = "$bbs<>$threadID";
			push @$pSearchSet, $set;
		}
	}
	# �X���b�h���S����
	elsif ($mode == 2) {
		$set = "$bbs<>$thread";
		push @$pSearchSet, $set;
	}
	# �w�肪��������
	else {
		return;
	}
	
	# dat���W���[���ǂݍ���
	if (! defined $this->{'ARAGORN'}) {
		require './module/gondor.pl';
		$this->{'ARAGORN'} = ARAGORN->new;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�������s
#	-------------------------------------------------------------------------------------
#	@param	$word : �������[�h
#	@param	$f    : �O���ʃN���A�t���O
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Run
{
	my $this = shift;
	my ($word, $f) = @_;
	my ($pSearchSet, $bbs, $key);
	
	$pSearchSet = $this->{'SEARCHSET'};
	
	foreach (@$pSearchSet) {
		($bbs, $key) = split(/<>/, $_);
		$this->{'SYS'}->Set('BBS', $bbs);
		$this->{'SYS'}->Set('KEY', $key);
		Search($this, $word);
	}
	return($this->{'RESULTSET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	�������ʎ擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	���ʃZ�b�g
#
#------------------------------------------------------------------------------------------------------------
sub GetResultSet
{
	my $this = shift;
	
	return($this->{'RESULTSET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	����������
#	-------------------------------------------------------------------------------------
#	@param	$this : this�I�u�W�F�N�g
#	@param	$word : �������[�h
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Search
{
	my ($this, $word) = @_;
	my ($pDAT, $pResultSet, $SetStr);
	my ($bbs, $key, $i, $bFind, $Path, $pDat, @elem);
	
	$bbs	= $this->{'SYS'}->Get('BBS');
	$key	= $this->{'SYS'}->Get('KEY');
	$Path	= $this->{'SYS'}->Get('BBSPATH') . "/$bbs/dat/$key.dat";
	
	if ($this->{'ARAGORN'}->Load($this->{'SYS'}, $Path, 1)) {
		$pResultSet = $this->{'RESULTSET'};
		$bFind = 0;
		# ���ׂẴ��X���Ń��[�v
		for ($i = 0 ; $i < $this->{'ARAGORN'}->Size() ; $i++) {
			$pDat = $this->{'ARAGORN'}->Get($i);
			@elem = split(/<>/, $$pDat);
			# ���O����
			if ($this->{'TYPE'} == 0 || $this->{'TYPE'} & 1) {
				if (index($elem[0], $word) > -1) {
					$elem[0] =~ s/(\Q$word\E)/<span class="res">$word<\/span>/g;
					$bFind = 1;
				}
			}
			# �{������
			if ($this->{'TYPE'} == 0 || $this->{'TYPE'} & 2) {
				if (index($elem[3], $word) > -1) {
					$elem[3] =~ s/(\Q$word\E)/<span class="res">$word<\/span>/g;
					$bFind = 1;
				}
			}
			# ID or ���t����
			if ($this->{'TYPE'} == 0 || $this->{'TYPE'} & 4) {
				if (index($elem[2], $word) > -1) {
					$elem[2] =~ s/(\Q$word\E)/<span class="res">$word<\/span>/g;
					$bFind = 1;
				}
			}
			if ($bFind) {
				$SetStr = "$bbs<>$key<>" . ($i + 1) . '<>';
				$SetStr .= join('<>', @elem);
				push @$pResultSet, $SetStr;
			}
			$bFind = 0;
		}
		$this->{'RESULTSET'} = $pResultSet;
	}
	$this->{'ARAGORN'}->Close();
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

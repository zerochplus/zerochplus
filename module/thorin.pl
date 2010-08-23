#============================================================================================================
#
#	�o�͊Ǘ����W���[��(THORIN)
#	thorin.pl
#	---------------------------------------------
#	2002.12.05 start
#
#============================================================================================================
package	THORIN;

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
	my (@BUFF, $obj);
	
	$obj = {				# thorin�I�u�W�F�N�g
		'BUFF'	=> \@BUFF,	# �o�̓o�b�t�@
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�b�t�@�o�� - Print
#	-------------------------------------------
#	���@���F$line : �o�̓e�L�X�g
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($line) = @_;
	
	push @{$this->{'BUFF'}}, $line;
}

#------------------------------------------------------------------------------------------------------------
#
#	INPUT�^�O�o�� - HTMLInput
#	-------------------------------------------
#	���@���F$kind  : �^�C�v
#			$name  : ���O
#			$value : �l
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub HTMLInput
{
	my $this = shift;
	my ($kind, $name, $value) = @_;
	my $line;
	
	$line = "<input type=$kind name=\"$name\" value=\"$value\">\n";
	
	push @{$this->{'BUFF'}}, $line;
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�b�t�@�t���b�V�� - Flush
#	-------------------------------------------
#	���@���F$flag       : �o�̓t���O
#			$perm		: �p�[�~�b�V����
#			$szFilePath : �o�̓p�X
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Flush
{
	my $this = shift;
	my ($flag, $perm, $szFilePath) = @_;
	
	# �t�@�C���֏o��
	if ($flag) {
#		eval
		{
			open OUTPUT, "+> $szFilePath";
			flock OUTPUT, 2;
			truncate OUTPUT, 0;
			seek OUTPUT, 0, 0;
			print OUTPUT @{$this->{'BUFF'}};
			close OUTPUT;
			chmod $perm, $szFilePath;
		};
	}
	# �W���o�͂ɏo��
	else {
		print @{$this->{'BUFF'}};
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�o�b�t�@�N���A - Clear
#	-------------------------------------------
#	���@���F�Ȃ�
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	undef @{$this->{'BUFF'}};
}

#------------------------------------------------------------------------------------------------------------
#
#	�}�[�W - Merge
#	-------------------------------------------
#	���@���F$thorin : THORIN���W���[��
#	�߂�l�F�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Merge
{
	my $this = shift;
	my ($thorin) = @_;
	
	foreach (@{$thorin->{'BUFF'}}) {
		push @{$this->{'BUFF'}}, $_;
	}
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;
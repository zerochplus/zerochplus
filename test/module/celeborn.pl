#============================================================================================================
#
#	�ߋ����O�Ǘ����W���[��(CELEBORN)
#	celeborn.pl
#	-------------------------------------------------------------------------------------
#	2003.01.22 start
#	2003.03.07 Make���\�b�h�ǉ�
#	2004.08.24 �č\�z
#
#============================================================================================================
package	CELEBORN;

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
	my (%KAKO, $PATH, $obj);
	
	$obj = {
		'KEY'		=> undef,
		'SUBJECT'	=> undef,
		'DATE'		=> undef,
		'PATH'		=> undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O���t�@�C���ǂݍ���
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($SYS) = @_;
	my (@elem, $path);
	
	undef $this->{'KEY'};
	undef $this->{'SUBJECT'};
	undef $this->{'DATE'};
	undef $this->{'PATH'};
	
	$path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
	if (-e $path) {
		open KAKO, "< $path";
		while (<KAKO>) {
			chomp $_;
			@elem = split(/<>/, $_);
			$this->{'KEY'}->{$elem[0]}		= $elem[1];
			$this->{'SUBJECT'}->{$elem[0]}	= $elem[2];
			$this->{'DATE'}->{$elem[0]}		= $elem[3];
			$this->{'PATH'}->{$elem[0]}		= $elem[4];
		}
		close KAKO;
		return 0;
	}
	return -1;
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O���t�@�C����������
#	-------------------------------------------------------------------------------------
#	@param	$SYS	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($SYS) = @_;
	my ($path, $data);
	
	$path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
#	eval
	{
		open KAKO, "+> $path";
		flock KAKO, 2;
		binmode KAKO;
		truncate KAKO, 0;
		seek KAKO, 0, 0;
		foreach (keys %{$this->{'SUBJECT'}}) {
			$data = join('<>',
				$_,
				$this->{KEY}->{$_},
				$this->{SUBJECT}->{$_},
				$this->{DATE}->{$_},
				$this->{PATH}->{$_}
			);
			
			print KAKO "$data\n";
		}
		close KAKO;
		chmod $SYS->Get('PM-DAT'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	ID�Z�b�g�擾
#	-------------------------------------------------------------------------------------
#	@param	$kind	�������
#	@param	$name	�������[�h
#	@param	$pBuf	ID�Z�b�g�i�[�o�b�t�@
#	@return	�L�[�Z�b�g��
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($kind, $name, $pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	if ($kind eq 'ALL') {
		foreach $key (keys %{$this->{'KEY'}}) {
			if ($this->{'KEY'}->{$key} ne '0') {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	else {
		foreach $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	���擾
#	-------------------------------------------------------------------------------------
#	@param	$kind	�����
#	@param	$key	���[�UID
#			$default : �f�t�H���g
#	@return	���[�U���
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key, $default) = @_;
	my ($val);
	
	$val = $this->{$kind}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	�ǉ�
#	-------------------------------------------------------------------------------------
#	@param	$key		�X���b�h�L�[
#	@param	$subject	�X���b�h�^�C�g��
#	@param	$date		�X�V����
#	@return	ID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($key, $subject, $date, $path) = @_;
	my ($id);
	
	$id = time;
	while (exists $this->{'KEY'}->{$id}) {
		$id++;
	}
	$this->{'KEY'}->{$id}		= $key;
	$this->{'SUBJECT'}->{$id}	= $subject;
	$this->{'DATE'}->{$id}		= $date;
	$this->{'PATH'}->{$id}		= $path;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	���ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$id		ID
#	@param	$kind	�����
#	@param	$val	�ݒ�l
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($id, $kind, $val) = @_;
	
	if (exists $this->{$kind}->{$id}) {
		$this->{$kind}->{$id} = $val;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	���폜
#	-------------------------------------------------------------------------------------
#	@param	$id		�폜ID
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'KEY'}->{$id};
	delete $this->{'SUBJECT'}->{$id};
	delete $this->{'DATE'}->{$id};
	delete $this->{'PATH'}->{$id};
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O���̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub UpdateInfo
{
	my $this = shift;
	my ($Sys) = @_;
	my (%Dirs, @dirList, @fileList, @elem);
	my ($dir, $file, $path, $subj);
	
	require './module/earendil.pl';
	
	undef $this->{'KEY'};
	undef $this->{'SUBJECT'};
	undef $this->{'DATE'};
	undef $this->{'PATH'};
	
	$path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako';
	
	# �f�B���N�g�������擾
	EARENDIL::GetFolderHierarchy($path, \%Dirs);
	EARENDIL::GetFolderList(\%Dirs, \@dirList, '');
	
	foreach $dir (@dirList) {
		EARENDIL::GetFileList("$path/$dir", \@fileList, '(\d+)\.html');
		Add($this, 0, 0, 0, $dir);
		foreach $file (@fileList) {
			@elem = split(/\./, $file);
			$subj = GetThreadSubject("$path/$dir/$file");
			if ($subj ne '') {
				Add($this, $elem[0], $subj, time, $dir);
			}
		}
		undef @fileList;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����Oindex�̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub UpdateIndex
{
	my $this = shift;
	my ($Sys, $Page) = @_;
	my ($Banner, %PATHES, @subDirs, @info, @dirs);
	my ($basePath, $path, $id, $dir, $key, $subj, $date);
	
	# ���m���ǂݍ���
	require './module/denethor.pl';
	$Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	$basePath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	# �p�X���L�[�ɂ��ăn�b�V�����쐬
	foreach $id (keys(%{$this->{'KEY'}})) {
		$path = $this->{'PATH'}->{$id};
		$PATHES{$path} = $id;
	}
	@dirs = keys %PATHES;
	unshift @dirs, '';
	
#	eval
	{
		# �p�X���Ƃ�index�𐶐�����
		foreach $path (@dirs) {
			# 1�K�w���̃T�u�t�H���_���擾����
			GetSubFolders($path, \@dirs, \@subDirs);
			foreach $dir (sort @subDirs) {
				push @info, "0<>0<>0<>$dir";
			}
			
			# ���O�f�[�^������Ώ��z��ɒǉ�����
			foreach $id (keys(%{$this->{'KEY'}})) {
				if ($path eq $this->{'PATH'}->{$id} && $this->{'KEY'}->{$id} ne '0') {
					$key = $this->{'KEY'}->{$id};
					$subj = $this->{'SUBJECT'}->{$id};
					$date = $this->{'DATE'}->{$id};
					push @info, "$key<>$subj<>$date<>$path";
				}
			}
			
			# index�t�@�C�����o�͂���
			$Page->Clear();
			OutputIndex($Sys, $Page, $Banner, \@info, $basePath, $path);
			
			undef @info;
			undef @subDirs;
		}
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	�T�u�t�H���_���擾����
#	-------------------------------------------------------------------------------------
#	@param	$base	�e�t�H���_�p�X
#	@param	$pDirs	�f�B���N�g�����̔z��
#	@param	$pList	�T�u�t�H���_�i�[�z��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub GetSubFolders
{
	my ($base, $pDirs, $pList) = @_;
	my ($dir, $old);
	
	$base .= '/';
	foreach $dir (@$pDirs) {
		$old = $dir;
		$old =~ s/^$base//;
		if ($old ne $dir && $old !~ /\//) {
			push @$pList, $old;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����O�^�C�g���̎擾
#	-------------------------------------------------------------------------------------
#	@param	$path	�擾����t�@�C���̃p�X
#	@return	�^�C�g��
#
#------------------------------------------------------------------------------------------------------------
sub GetThreadSubject
{
	my ($path) = @_;
	my ($text);
	
	if (-e $path) {
		open FILE, "< $path";
		foreach $text (<FILE>) {
			if ($text =~ /<title>(.*)<\/title>/) {
				close FILE;
				return $1;
			}
		}
	}
	close FILE;
	return '';
}

#------------------------------------------------------------------------------------------------------------
#
#	�ߋ����Oindex���o�͂���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@param	$Page	THORIN
#	@param	$Banner	DENETHOR
#	@param	$pInfo	�o�͏��z��
#	@param	$base	�f���g�b�v�p�X
#	@param	$path	index�o�̓p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub OutputIndex
{
	my ($Sys, $Page, $Banner, $pInfo, $base, $path, $Set) = @_;
	my (@elem, $info, $version);
	my ($Caption, $bbsRoot, $board);
	
	require './module/legolas.pl';
	$Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	$version = $Sys->Get('VERSION');
	$bbsRoot = $Sys->Get('SERVER') . '/' . $Sys->Get('BBS');
	$board = $Sys->Get('BBS');
	
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=Shift_JIS">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(<<HTML);
 <title>�ߋ����O�q�� - $board$path</title>

</head>
<!--nobanner-->
<body>
HTML
	
	# ���m���o��
	$Banner->Print($Page, 100, 2, 0);
	
	$Page->Print(<<HTML);

<h1 align="center" style="margin-bottom:0.2em;">�ߋ����O�q��</h1>
<h2 align="center" style="margin-top:0.2em;">$board</h2>

<table border="1">
 <tr>
  <th>KEY</th>
  <th>subject</th>
  <th>date</th>
 </tr>
HTML
	
	foreach $info (@$pInfo) {
		@elem = split(/<>/, $info);
		
		# �T�u�t�H���_���
		if ($elem[0] eq '0') {
			$Page->Print(" <tr>\n  <td>Directory</td>\n  <td><a href=\"$elem[3]/index.html\">");
			$Page->Print("$elem[3]</a></td>\n  <td>-</td>\n </tr>\n");
		}
		# �ߋ����O���
		else {
			$Page->Print(" <tr>\n  <td>$elem[0]</td>\n  <td><a href=\"$elem[0].html\">");
			$Page->Print("$elem[1]</a></td>\n  <td>$elem[2]</td>\n </tr>\n");
		}
	}
	$Page->Print("</table>\n\n<hr>\n");
	$Page->Print(<<HTML);

<a href="$bbsRoot/">���f���ɖ߂遡</a> | <a href="$bbsRoot/kako/">���ߋ����O�g�b�v�ɖ߂遡</a> | <a href="../">��1��ɖ߂遡</a>

<hr>

<div align="right">
<a href="http://validator.w3.org/check?uri=referer"><img src="/test/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
$version
</div>
</body>
</html>
HTML
	
	# index.html���o�͂���
	$Page->Flush(1, 0666, "$base/kako$path/index.html");
}

#============================================================================================================
#	���W���[���I�[
#============================================================================================================
1;

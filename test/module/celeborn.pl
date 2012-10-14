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
	
	my $obj = {
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
	
	$this->{'KEY'} = {};
	$this->{'SUBJECT'} = {};
	$this->{'DATE'} = {};
	$this->{'PATH'} = {};
	
	my $path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		chomp @lines;
		
		foreach (@lines) {
			next if ($_ eq '');
			
			my @elem = split(/<>/, $_);
			if ($#elem + 1 < 5) {
				warn "invalid line in $path";
				next;
			}
			
			my $id = $elem[0];
			$this->{'KEY'}->{$id} = $elem[1];
			$this->{'SUBJECT'}->{$id} = $elem[2];
			$this->{'DATE'}->{$id} = $elem[3];
			$this->{'PATH'}->{$id} = $elem[4];
		}
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
	
	my $path = $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS') . '/kako/kako.idx';
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach (keys %{$this->{'KEY'}}) {
			my $data = join('<>',
				$_,
				$this->{'KEY'}->{$_},
				$this->{'SUBJECT'}->{$_},
				$this->{'DATE'}->{$_},
				$this->{'PATH'}->{$_}
			);
			
			print $fh "$data\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	else {
		warn "can't save subject: $path";
	}
	chmod $SYS->Get('PM-DAT'), $path;
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
	
	my $n = 0;
	
	if ($kind eq 'ALL') {
		foreach my $key (keys %{$this->{'KEY'}}) {
			if ($this->{'KEY'}->{$key} ne '0') {
				$n += push @$pBuf, $key;
			}
		}
	}
	else {
		foreach my $key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $kind eq 'ALL') {
				$n += push @$pBuf, $key;
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
	
	my $val = $this->{$kind}->{$key};
	
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
	
	my $id = time;
	$id++ while (exists $this->{'KEY'}->{$id});
	
	$this->{'KEY'}->{$id} = $key;
	$this->{'SUBJECT'}->{$id} = $subject;
	$this->{'DATE'}->{$id} = $date;
	$this->{'PATH'}->{$id} = $path;
	
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
	
	require './module/earendil.pl';
	
	$this->{'KEY'} = {};
	$this->{'SUBJECT'} = {};
	$this->{'DATE'} = {};
	$this->{'PATH'} = {};
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/kako';
	
	# �f�B���N�g�������擾
	my @dirList = ();
	EARENDIL::GetFolderHierarchy($path, ($_ = {}));
	EARENDIL::GetFolderList($_, \@dirList, '');
	
	foreach my $dir (@dirList) {
		EARENDIL::GetFileList("$path/$dir", ($_ = []), '([0-9]+)\.html');
		Add($this, 0, 0, 0, $dir);
		foreach my $file (@$_) {
			my @elem = split(/\./, $file);
			my $subj = GetThreadSubject("$path/$dir/$file");
			Add($this, $elem[0], $subj, time, $dir) if ($subj ne '');
		}
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
	my (@subDirs, @info);
	
	# ���m���ǂݍ���
	require './module/denethor.pl';
	my $Banner = DENETHOR->new;
	$Banner->Load($Sys);
	
	my $basePath = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS');
	
	# �p�X���L�[�ɂ��ăn�b�V�����쐬
	my %PATHES = ();
	foreach my $id (keys %{$this->{'KEY'}}) {
		my $path = $this->{'PATH'}->{$id};
		$PATHES{$path} = $id;
	}
	my @dirs = keys %PATHES;
	unshift @dirs, '';
	
	# �p�X���Ƃ�index�𐶐�����
	foreach my $path (@dirs) {
		my @info = ();
		
		# 1�K�w���̃T�u�t�H���_���擾����
		GetSubFolders($path, \@dirs, ($_ = []));
		foreach my $dir (sort @$_) {
			push @info, "0<>0<>0<>$dir";
		}
		
		# ���O�f�[�^������Ώ��z��ɒǉ�����
		foreach my $id (keys %{$this->{'KEY'}}) {
			if ($path eq $this->{'PATH'}->{$id} && $this->{'KEY'}->{$id} ne '0') {
				my $data = join('<>',
					$this->{'KEY'}->{$id},
					$this->{'SUBJECT'}->{$id},
					$this->{'DATE'}->{$id},
					$path
				);
				push @info, "$data";
			}
		}
		
		# index�t�@�C�����o�͂���
		$Page->Clear();
		OutputIndex($Sys, $Page, $Banner, \@info, $basePath, $path);
	}
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
	
	foreach my $dir (@$pDirs) {
		if ($dir =~ s|^\Q$base/\E|| && $dir !~ m|/|) {
			push @$pList, $dir;
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
	my $title = '';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		
		foreach (@lines) {
			if ($_ =~ m|<title>(.*)</title>|) {
				$title = $1;
				last;
			}
		}
	}
	else {
		warn "can't open: $path";
	}
	return $title;
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
	
	my $cgipath	= $Sys->Get('CGIPATH');
	
	require './module/legolas.pl';
	my $Caption = LEGOLAS->new;
	$Caption->Load($Sys, 'META');
	
	my $version = $Sys->Get('VERSION');
	my $bbsRoot = $Sys->Get('CGIPATH') . '/' . $Sys->Get('BBSPATH') . '/'. $Sys->Get('BBS');
	my $board = $Sys->Get('BBS');
	
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
	
	foreach (@$pInfo) {
		my @elem = split(/<>/, $_, -1);
		
		# �T�u�t�H���_���
		if ($elem[0] eq '0') {
			$Page->Print(" <tr>\n  <td>Directory</td>\n  <td><a href=\"$elem[3]/\">");
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
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
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

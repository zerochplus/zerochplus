#============================================================================================================
#
#	�v���O�C���Ǘ����W���[��
#
#============================================================================================================
package	ATHELAS;

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
		'Sys'		=> undef,
		'FILE'		=> undef,
		'CLASS'		=> undef,
		'NAME'		=> undef,
		'EXPL'		=> undef,
		'TYPE'		=> undef,
		'VALID'		=> undef,
		'CONFIG'	=> undef,
		'CONFTYPE'	=> undef,
		'ORDER'		=> undef,
	};
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����ǂݍ���
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	# �n�b�V��������
	$this->{'SYS'} = $Sys;
	$this->{'FILE'} = {};
	$this->{'CLASS'} = {};
	$this->{'NAME'} = {};
	$this->{'EXPL'} = {};
	$this->{'TYPE'} = {};
	$this->{'VALID'} = {};
	$this->{'CONFIG'} = {};
	$this->{'CONFTYPE'} = {};
	$this->{'ORDER'} = [];
	
	my $path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		
		foreach (@lines) {
			next if ($_ eq '');
			
			my @elem = split(/<>/, $_, -1);
			if (scalar(@elem) < 7) {
				warn "invalid line in $path";
				#next;
			}
			
			eval { require "./plugin/$elem[1]"; };
			next if ($@);
			
			my $id = $elem[0];
			$this->{'FILE'}->{$id} = $elem[1];
			$this->{'CLASS'}->{$id} = $elem[2];
			$this->{'NAME'}->{$id} = $elem[3];
			$this->{'EXPL'}->{$id} = $elem[4];
			$this->{'TYPE'}->{$id} = $elem[5];
			$this->{'VALID'}->{$id} = $elem[6];
			$this->{'CONFIG'}->{$id} = {};
			$this->{'CONFTYPE'}->{$id} = {};
			push @{$this->{'ORDER'}}, $id;
			$this->SetDefaultConfig($id);
			$this->LoadConfig($id);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C���ʐݒ�ǂݍ���
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub LoadConfig
{
	my $this = shift;
	my ($id) = @_;
	
	my $config = $this->{'CONFIG'}->{$id};
	my $conftype = $this->{'CONFTYPE'}->{$id};
	my $file = $this->{'FILE'}->{$id};
	my $path = undef;
	
	if ($file =~ /^(0ch_.*)\.pl$/) {
		$path = "./plugin_conf/$1.cgi";
	}
	else {
		warn "invalid plugin file name: $file";
		return;
	}
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @lines = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @lines;
		foreach (@lines) {
			my @elem = split(/<>/, $_, -1);
			if (scalar(@elem) < 3) {
				warn "invalid line in $path";
				next;
			}
			$config->{$elem[1]} = $elem[2];
			$conftype->{$elem[1]} = $elem[0];
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C���ʐݒ�ۑ�
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SaveConfig
{
	my $this = shift;
	my ($id) = @_;
	
	my $config = $this->{'CONFIG'}->{$id};
	my $conftype = $this->{'CONFTYPE'}->{$id};
	my $file = $this->{'FILE'}->{$id};
	my $path = undef;
	
	if ($file =~ /^(0ch_.*)\.pl$/) {
		$path = "./plugin_conf/$1.cgi";
	}
	else {
		warn "invalid plugin file name: $file";
		return;
	}
	
	if (scalar(keys %$config) > 0) {
		if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
			flock($fh, 2);
			seek($fh, 0, 0);
			
			foreach my $key (sort keys %$config) {
				next unless (defined $config->{$key});
				
				my $val = $config->{$key};
				my $type = $conftype->{$key};
				if ($type == 1) {
					$val -= 0;
				}
				elsif ($type == 2) {
					$val =~ s/\r\n|[\r\n]/<br>/g;
					$val =~ s/<>/&lt;&gt;/g;
				}
				elsif ($type == 3) {
					$val = ($val ? 1 : 0);
				}
				print $fh "$type<>$key<>$val\n";
			}
			
			truncate($fh, tell($fh));
			close($fh);
			chmod($this->{'SYS'}->Get('PM-ADM'), $path);
		}
		else {
			warn "can't save subject: $path";
		}
	}
	else {
		unlink $path;
	}
}

sub HasConfig
{
	my $this = shift;
	my ($id) = @_;
	
	return scalar(keys %{$this->{'CONFIG'}->{$id}});
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C���ʐݒ菉���l�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetDefaultConfig
{
	my $this = shift;
	my ($id) = @_;
	
	my $config = $this->{'CONFIG'}->{$id} = {};
	my $conftype = $this->{'CONFTYPE'}->{$id} = {};
	my $file = $this->{'FILE'}->{$id};
	my $className = undef;
	
	if ($file =~ /^0ch_(.*)\.pl$/) {
		$className = "ZPL_$1";
	}
	else {
		warn "invalid plugin file name: $file";
		return;
	}
	
	require "./plugin/$file";
	if ($className->can('getConfig')) {
		my $plugin = $className->new;
		my $conf = $plugin->getConfig;
		foreach my $key (keys %$conf) {
			$config->{$key} = $conf->{$key}->{'default'};
			$conftype->{$key} = $conf->{$key}->{'valuetype'};
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����ۑ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		foreach my $id (@{$this->{'ORDER'}}) {
			my $data = join('<>',
				$id,
				$this->{'FILE'}->{$id},
				$this->{'CLASS'}->{$id},
				$this->{'NAME'}->{$id},
				$this->{'EXPL'}->{$id},
				$this->{'TYPE'}->{$id},
				$this->{'VALID'}->{$id}
			);
			
			print $fh "$data\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod($Sys->Get('PM-ADM'), $path);
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C��ID�Z�b�g�擾
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
		$n += push @$pBuf, @{$this->{'ORDER'}};
	}
	else {
		foreach my $key (@{$this->{'ORDER'}}) {
			if ($this->{$kind}->{$key} eq $name || $name eq 'ALL') {
				$n += push @$pBuf, $key;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����擾
#	-------------------------------------------------------------------------------------
#	@param	$kind		�����
#	@param	$key		���[�UID
#	@param	$default	�f�t�H���g
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
#	�v���O�C�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$id		���[�UID
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
#	�v���O�C���ǉ�
#	-------------------------------------------------------------------------------------
#	@param	$file	�v���O�C���t�@�C����
#	@param	$valid	�L���t���O
#	@return	�v���O�C��ID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($file, $valid) = @_;
	
	my $id = time;
	$id++ while (exists $this->{'FILE'}->{$id});
	
	if (! -e "./plugin/$file") {
		warn "not found plugin: ./plugin/$file";
		return undef;
	}
	
	my $className = undef;
	if ($file =~ /0ch_(.*)\.pl/) {
		$className = "ZPL_$1";
	}
	else {
		warn "invalid plugin file name: $file";
		return undef;
	}
	
	require "./plugin/$file";
	if (!$className->can('new')) {
		warn "invalid plugin file name: $file";
		return undef;
	}
	
	my $plugin = $className->new;
	$this->{'FILE'}->{$id} = $file;
	$this->{'CLASS'}->{$id} = $className;
	$this->{'NAME'}->{$id} = $plugin->getName;
	$this->{'EXPL'}->{$id} = $plugin->getExplanation;
	$this->{'TYPE'}->{$id} = $plugin->getType;
	$this->{'VALID'}->{$id} = $valid;
	$this->{'CONFIG'}->{$id} = {};
	$this->{'CONFTYPE'}->{$id} = {};
	$this->SetDefaultConfig($id);
	$this->LoadConfig($id);
	$this->SaveConfig($id);
	push @{$this->{'ORDER'}}, $id;
	
	return $id;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����폜
#	-------------------------------------------------------------------------------------
#	@param	$id		�폜�v���O�C��ID
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Delete
{
	my $this = shift;
	my ($id) = @_;
	
	delete $this->{'FILE'}->{$id};
	delete $this->{'CLASS'}->{$id};
	delete $this->{'NAME'}->{$id};
	delete $this->{'EXPL'}->{$id};
	delete $this->{'TYPE'}->{$id};
	delete $this->{'VALID'}->{$id};
	delete $this->{'CONFIG'}->{$id};
	delete $this->{'CONFTYPE'}->{$id};
	
	my $order = $this->{'ORDER'};
	for my $i (reverse(0 .. $#$order)) {
		if ($order->[$i] eq $id) {
			splice(@$order, $i, 1);
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����X�V
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my $this = shift;
	my ($plugin, $exist);
	
	my @files = ();
	if (opendir(my $dh, './plugin')) {
		@files = readdir($dh);
		closedir($dh);
	}
	else {
		$this->{'FILE'} = {};
		$this->{'CLASS'} = {};
		$this->{'NAME'} = {};
		$this->{'EXPL'} = {};
		$this->{'TYPE'} = {};
		$this->{'VALID'} = {};
		$this->{'CONFIG'} = {};
		$this->{'CONFTYPE'} = {};
		$this->{'ORDER'} = [];
		return;
	}
	
	# �v���O�C���ǉ��E�X�V�t�F�C�Y
	foreach my $file (@files) {
		if ($file =~ /^0ch_(.*)\.pl/) {
			my $className = "ZPL_$1";
			my @keySet = ();
			if (scalar $this->GetKeySet('FILE', $file, \@keySet) > 0) {
				my $id = $keySet[0];
				require "./plugin/$file";
				my $plugin = $className->new;
				$this->{'NAME'}->{$id} = $plugin->getName;
				$this->{'EXPL'}->{$id} = $plugin->getExplanation;
				$this->{'TYPE'}->{$id} = $plugin->getType;
				$this->SetDefaultConfig($id);
				$this->LoadConfig($id);
				$this->SaveConfig($id);
			}
			else {
				$this->Add($file, 0);
			}
		}
	}
	# �v���O�C���폜�t�F�C�Y
	my @keySet = ();
	if ($this->GetKeySet('ALL', '', \@keySet) > 0) {
		foreach my $id (@keySet) {
			my $exist = 0;
			foreach my $file (@files) {
				if ($this->Get('FILE', $id) eq $file) {
					$exist = 1;
					last;
				}
			}
			if ($exist == 0) {
				$this->Delete($id);
			}
		}
	}
}


#============================================================================================================
#
#	�v���O�C���ʐݒ�Ǘ����W���[��
#
#============================================================================================================

package	PLUGINCONF;

#------------------------------------------------------------------------------------------------------------
#
#	�R���X�g���N�^
#	-------------------------------------------------------------------------------------
#	@param	$Plugin	ATHELAS
#	@param	$id		
#	@return	���W���[���I�u�W�F�N�g
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	my ($Plugin, $id) = @_;
	
	my $obj = {
		'PLUGIN'	=> $Plugin,
		'id'		=> $id
	};
	
	bless $obj, $class;
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C���ʐݒ�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$key	
#	@param	$val	
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetConfig
{
	my $this = shift;
	my ($key, $val) = @_;
	
	my $id = $this->{'id'};
	my $Plugin = $this->{'PLUGIN'};
	my $config = $Plugin->{'CONFIG'}->{$id};
	my $conftype = $Plugin->{'CONFTYPE'}->{$id};
	my $type = 0;
	
	if (defined $conftype->{$key}) {
		$type = $conftype->{$key};
	}
	else {
		if (ref(\$val) eq 'SCALAR') {
			$type = 2;
		}
		else {
			$type = 0;
			return;
		}
		$conftype->{$key} = $type;
	}
	
	if ($type == 1) {
		$val -= 0;
	}
	elsif ($type == 2) {
		$val =~ s/\r\n|[\r\n]/<br>/g;
		$val =~ s/<>/&lt;&gt;/g;
	}
	elsif ($type == 3) {
		$val = ($val ? 1 : 0);
	}
	
	$config->{$key} = $val;
	
	$Plugin->SaveConfig($id);
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C���ʐݒ�擾
#	-------------------------------------------------------------------------------------
#	@param	$key	
#	@return	�v���O�C���ʐݒ�
#
#------------------------------------------------------------------------------------------------------------
sub GetConfig
{
	my $this = shift;
	my ($key) = @_;
	
	my $id = $this->{'id'};
	my $config = $this->{'PLUGIN'}->{'CONFIG'}->{$id};
	
	return $config->{$key};
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

#============================================================================================================
#
#	�V�X�e���Ǘ� - �ݒ� ���W���[��
#
#============================================================================================================
package	MODULE;

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
my $Page = 
	$Base->Create($Sys, $Form);
	
	my $subMode = $Form->Get('MODE_SUB');
	
	# ���j���[�̐ݒ�
	SetMenuList($Base, $CGI);
	
	my $indata = undef;
	
	# �V�X�e�������
	if ($subMode eq 'INFO') {
		$indata = PreparePageSystemInfo($Sys, $Form);
	}
	# ��{�ݒ���
	elsif ($subMode eq 'BASIC') {
		$indata = PreparePageBasicSetting($Sys, $Form);
	}
	# �p�[�~�b�V�����ݒ���
	elsif ($subMode eq 'PERMISSION') {
		$indata = PreparePagePermissionSetting($Sys, $Form);
	}
	# ���~�b�^�ݒ���
	elsif ($subMode eq 'LIMITTER') {
		$indata = PreparePageLimitterSetting($Sys, $Form);
	}
	# ���̑��ݒ���
	elsif ($subMode eq 'OTHER') {
		$indata = PreparePageOtherSetting($Sys, $Form);
	}
	# �\���ݒ�
	elsif ($subMode eq 'VIEW') {
		$indata = PreparePageViewSetting($Sys, $Form);
	}
	# �K���ݒ�
	elsif ($subMode eq 'SEC') {
		$indata = PreparePageSecSetting($Sys, $Form);
	}
	# �g���@�\�ݒ���
	elsif ($subMode eq 'PLUGIN') {
		$indata = PreparePagePluginSetting($Sys, $Form);
	}
	# �g���@�\�ʐݒ�ݒ���
	elsif ($subMode eq 'PLUGINCONF') {
		$indata = PreparePagePluginOptionSetting($Sys, $Form);
	}
	# �V�X�e���ݒ芮�����
	elsif ($subMode eq 'COMPLETE') {
		$indata = $Base->PreparePageComplete('�V�X�e���ݒ菈��', $this->{'LOG'});
	}
	# �V�X�e���ݒ莸�s���
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
	
	# ��{�ݒ�
	if ($subMode eq 'BASIC') {
		$err = FunctionBasicSetting($Sys, $Form, $this->{'LOG'});
	}
	# �p�[�~�b�V�����ݒ�
	elsif ($subMode eq 'PERMISSION') {
		$err = FunctionPermissionSetting($Sys, $Form, $this->{'LOG'});
	}
	# �����ݒ�
	elsif ($subMode eq 'LIMITTER') {
		$err = FunctionLimitterSetting($Sys, $Form, $this->{'LOG'});
	}
	# ���̑��ݒ�
	elsif ($subMode eq 'OTHER') {
		$err = FunctionOtherSetting($Sys, $Form, $this->{'LOG'});
	}
	# �\���ݒ�
	elsif ($subMode eq 'VIEW') {
		$err = FunctionPlusViewSetting($Sys, $Form, $this->{'LOG'});
	}
	# �K���ݒ�
	elsif ($subMode eq 'SEC') {
		$err = FunctionPlusSecSetting($Sys, $Form, $this->{'LOG'});
	}
	# �g���@�\���ݒ�
	elsif ($subMode eq 'SET_PLUGIN') {
		$err = FunctionPluginSetting($Sys, $Form, $this->{'LOG'});
	}
	# �g���@�\���X�V
	elsif ($subMode eq 'UPDATE_PLUGIN') {
		$err = FunctionPluginUpdate($Sys, $Form, $this->{'LOG'});
	}
	# �g���@�\�ʐݒ�ݒ�
	elsif ($subMode eq 'SET_PLUGINCONF') {
		$err = FunctionPluginOptionSetting($Sys, $Form, $this->{'LOG'});
	}
	
	# �������ʕ\��
	if ($err) {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", "ERROR:$err");
		push @{$this->{'LOG'}}, $err;
		$Form->Set('MODE_SUB', 'FALSE');
	}
	else {
		$CGI->{'LOGGER'}->Put($Form->Get('UserName'),"SYSTEM_SETTING($subMode)", 'COMPLETE');
		$Form->Set('MODE_SUB', 'COMPLETE');
	}
	
	$this->DoPrint($Sys, $Form, $CGI);
}

#------------------------------------------------------------------------------------------------------------
#
#	���j���[���X�g�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Base	SAURON
#	@param	$CGI	�Ǘ��V�X�e��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub SetMenuList
{
	my ($Base, $CGI) = @_;
	
	# ���ʕ\�����j���[
	$Base->SetMenu('���', "'sys.setting','DISP','INFO'");
	
	# �V�X�e���Ǘ������̂�
	if ($CGI->{'SECINFO'}->IsAuthority($CGI->{'USER'}, $ZP::AUTH_SYSADMIN, '*')) {
		$Base->SetMenu('', '');
		$Base->SetMenu('��{�ݒ�', "'sys.setting','DISP','BASIC'");
		$Base->SetMenu('�p�[�~�b�V�����ݒ�', "'sys.setting','DISP','PERMISSION'");
		$Base->SetMenu('���~�b�^�ݒ�', "'sys.setting','DISP','LIMITTER'");
		$Base->SetMenu('���̑��ݒ�', "'sys.setting','DISP','OTHER'");
		$Base->SetMenu('', '');
		$Base->SetMenu('�\���ݒ�', "'sys.setting','DISP','VIEW'");
		$Base->SetMenu('�K���ݒ�', "'sys.setting','DISP','SEC'");
		$Base->SetMenu('', '');
		$Base->SetMenu('�g���@�\\�ݒ�', "'sys.setting','DISP','PLUGIN'");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e������ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageSystemInfo
{
	my ($Sys, $Form) = @_;
	
	my @checklist = qw(
		Encode
		Time::HiRes
		Time::Local
		Socket
		
		Template
		CGI::Session
		Storable
		Digest::SHA::PurePerl
		Net::DNS::Lite
		List::MoreUtils
		LWP::UserAgent
		XML::Simple
		
		Net::DNS
	);
	
	my $core = {};
	eval {
		require Module::CoreList;
		$core = $Module::CoreList::version{$]};
	};
	
	my $vers = [];
	foreach my $pkg (@checklist) {
		my $var = eval("require $pkg;return \${${pkg}::VERSION};");
		push @$vers, {
			'name'		=> $pkg,
			'version'	=> $var,
			'core'		=> $core->{$pkg},
		};
	}
	
	my $indata = {
		'title'			=> '0ch+ Administrator Information',
		'intmpl'		=> 'sys.setting.sysinfo',
		'zerover'		=> $Sys->Get('VERSION'),
		'perlver'		=> $],
		'perlpath'		=> $^X,
		'filename'		=> $ENV{'SCRIPT_FILENAME'} || $0,
		'serverhost'	=> $ENV{'HTTP_HOST'},
		'servername'	=> $ENV{'SERVER_NAME'},
		'serversoft'	=> $ENV{'SERVER_SOFTWARE'},
		'versions'		=> $vers,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�V�X�e����{�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageBasicSetting
{
	my ($Sys, $Form) = @_;
	
	my $server = $Sys->Get('SERVER');
	my $cgipath = $Sys->Get('CGIPATH');
	
	if ($server eq '') {
		my $sname = $ENV{'SERVER_NAME'};
		$server = "http://$sname";
	}
	if ($cgipath eq '') {
		my $path = $ENV{'SCRIPT_NAME'};
		$path =~ s|/[^/]+/[^/]+$||;
		$cgipath = "$path$cgipath";
	}
	
	my $indata = {
		'title'		=> 'System Base Setting',
		'intmpl'	=> 'sys.setting.basic',
		'server'	=> $server,
		'cgipath'	=> $cgipath,
		'bbspath'	=> $Sys->Get('BBSPATH'),
		'infopath'	=> $Sys->Get('INFO'),
		'datapath'	=> $Sys->Get('DATA'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�[�~�b�V�����ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePermissionSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Permission Setting',
		'intmpl'	=> 'sys.setting.perm',
		'datP'		=> sprintf('%o', $Sys->Get('PM-DAT')),
		'txtP'		=> sprintf('%o', $Sys->Get('PM-TXT')),
		'logP'		=> sprintf('%o', $Sys->Get('PM-LOG')),
		'admP'		=> sprintf('%o', $Sys->Get('PM-ADM')),
		'stopP'		=> sprintf('%o', $Sys->Get('PM-STOP')),
		'admDP'		=> sprintf('%o', $Sys->Get('PM-ADIR')),
		'bbsDP'		=> sprintf('%o', $Sys->Get('PM-BDIR')),
		'logDP'		=> sprintf('%o', $Sys->Get('PM-LDIR')),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageLimitterSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Limitter Setting',
		'intmpl'	=> 'sys.setting.limit',
		'resmax'	=> $Sys->Get('RESMAX'),
		'submax'	=> $Sys->Get('SUBMAX'),
		'anchors'	=> $Sys->Get('ANKERS'),
		'errmax'	=> $Sys->Get('ERRMAX'),
		'hstmax'	=> $Sys->Get('HSTMAX'),
		'admmax'	=> $Sys->Get('ADMMAX'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	���̑��ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageOtherSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Other Setting',
		'intmpl'	=> 'sys.setting.other',
		'urllink'	=> $Sys->Get('URLLINK'),
		'linkst'	=> $Sys->Get('LINKST'),
		'linked'	=> $Sys->Get('LINKED'),
		'pathkind'	=> $Sys->Get('PATHKIND'),
		'headtext'	=> $Sys->Get('HEADTEXT'),
		'headurl'	=> $Sys->Get('HEADURL'),
		'fastmode'	=> $Sys->Get('FASTMODE'),
		'bbsget'	=> $Sys->Get('BBSGET'),
		'upcheck'	=> $Sys->Get('UPCHECK'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\���ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageViewSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System View Setting',
		'intmpl'	=> 'sys.setting.view',
		'banner'	=> $Sys->Get('BANNER'),
		'counter'	=> $Sys->Get('COUNTER'),
		'prtext'	=> $Sys->Get('PRTEXT'),
		'prlink'	=> $Sys->Get('PRLINK'),
		'msec'		=> $Sys->Get('MSEC'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePageSecSetting
{
	my ($Sys, $Form) = @_;
	
	my $indata = {
		'title'		=> 'System Regulation Setting',
		'intmpl'	=> 'sys.setting.reg',
		'kakiko'	=> $Sys->Get('KAKIKO'),
		'samba'		=> $Sys->Get('SAMBATM'),
		'defsamba'	=> $Sys->Get('DEFSAMBA'),
		'defhoushi'	=> $Sys->Get('DEFHOUSHI'),
		'trip12'	=> $Sys->Get('TRIP12'),
		'bbq'		=> $Sys->Get('BBQ'),
		'bbx'		=> $Sys->Get('BBX'),
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePluginSetting
{
	my ($Sys, $Form) = @_;
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my @pluginSet = ();
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	
	my $plugins = [];
	foreach my $id (@pluginSet) {
		push @$plugins, {
			'id'		=> $id,
			'file'		=> $Plugin->Get('FILE', $id),
			'class'		=> $Plugin->Get('CLASS', $id),
			'name'		=> $Plugin->Get('NAME', $id),
			'expl'		=> $Plugin->Get('EXPL', $id),
			'valid'		=> $Plugin->Get('VALID', $id),
			'hascfg'	=> $Plugin->HasConfig($id),
		};
	}
	
	my $indata = {
		'title'		=> 'System Plugin Setting',
		'intmpl'	=> 'sys.setting.plugin',
		'plugins'	=> $plugins,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�ʐݒ�ݒ��ʂ̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PreparePagePluginOptionSetting
{
	my ($Sys, $Form) = @_;
	
	my $id = $Form->Get('PLGID');
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	my $Config = PLUGINCONF->new($Plugin, $id);
	
	my $name = $Plugin->Get('NAME', $id);
	my $class = $Plugin->Get('CLASS', $id);
	my $conf = {};
	if ($class->can('getConfig')) {
		$conf = $class->getConfig();
	}
	
	my $type2str = [undef, '���l','������','�^�U�l'];
	
	my $configs = [];
	foreach my $key (sort keys %$conf) {
		push @$configs, {
			'key'		=> $key,
			'keyenc'	=> unpack('H*', $key),
			'val'		=> $Config->GetConfig($key),
			'type'		=> $_ = $conf->{$key}->{'valuetype'},
			'typestr'	=> $type2str->[$_],
			'desc'		=> $conf->{$key}->{'description'},
		};
	}
	
	my $indata = {
		'title'		=> 'System Plugin Option Setting - '.$name,
		'intmpl'	=> 'sys.setting.pluginconf',
		'configs'	=> $configs,
		'plgid'		=> $id,
	};
	
	return $indata;
}

#------------------------------------------------------------------------------------------------------------
#
#	��{�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionBasicSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	# ���̓`�F�b�N
	return 1001 if (!$Form->IsInput([qw(SERVER CGIPATH BBSPATH INFO DATA)]));
	
	$Sys->Set('SERVER', $Form->Get('SERVER'));
	$Sys->Set('CGIPATH', $Form->Get('CGIPATH'));
	$Sys->Set('BBSPATH', $Form->Get('BBSPATH'));
	$Sys->Set('INFO', $Form->Get('INFO'));
	$Sys->Set('DATA', $Form->Get('DATA'));
	$Sys->Save;
	
	# ���O�̐ݒ�
	push @$pLog, '�� ��{�ݒ�';
	push @$pLog, '�@�@�@ �T�[�o�F' . $Form->Get('SERVER');
	push @$pLog, '�@�@�@ CGI�p�X�F' . $Form->Get('CGIPATH');
	push @$pLog, '�@�@�@ �f���p�X�F' . $Form->Get('BBSPATH');
	push @$pLog, '�@�@�@ �Ǘ��f�[�^�t�H���_�F' . $Form->Get('INFO');
	push @$pLog, '�@�@�@ ��{�f�[�^�t�H���_�F' . $Form->Get('DATA');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�[�~�b�V�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPermissionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('PM-DAT', oct($Form->Get('PERM_DAT')));
	$Sys->Set('PM-TXT', oct($Form->Get('PERM_TXT')));
	$Sys->Set('PM-LOG', oct($Form->Get('PERM_LOG')));
	$Sys->Set('PM-ADM', oct($Form->Get('PERM_ADMIN')));
	$Sys->Set('PM-STOP', oct($Form->Get('PERM_STOP')));
	$Sys->Set('PM-ADIR', oct($Form->Get('PERM_ADMIN_DIR')));
	$Sys->Set('PM-BDIR', oct($Form->Get('PERM_BBS_DIR')));
	$Sys->Set('PM-LDIR', oct($Form->Get('PERM_LOG_DIR')));
	$Sys->Save;
	
	# ���O�̐ݒ�
	push @$pLog, '�� ��{�ݒ�';
	push @$pLog, '�@�@�@ dat�p�[�~�b�V�����F' . $Form->Get('PERM_DAT');
	push @$pLog, '�@�@�@ txt�p�[�~�b�V�����F' . $Form->Get('PERM_TXT');
	push @$pLog, '�@�@�@ log�p�[�~�b�V�����F' . $Form->Get('PERM_LOG');
	push @$pLog, '�@�@�@ �Ǘ��t�@�C���p�[�~�b�V�����F' . $Form->Get('PERM_ADMIN');
	push @$pLog, '�@�@�@ ��~�X���b�h�p�[�~�b�V�����F' . $Form->Get('PERM_STOP');
	push @$pLog, '�@�@�@ �Ǘ�DIR�p�[�~�b�V�����F' . $Form->Get('PERM_ADMIN_DIR');
	push @$pLog, '�@�@�@ �f����DIR�p�[�~�b�V�����F' . $Form->Get('PERM_BBS_DIR');
	push @$pLog, '�@�@�@ ���ODIR�p�[�~�b�V�����F' . $Form->Get('PERM_LOG_DIR');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�����l�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionLimitterSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('RESMAX', $Form->Get('RESMAX'));
	$Sys->Set('SUBMAX', $Form->Get('SUBMAX'));
	$Sys->Set('ANKERS', $Form->Get('ANKERS'));
	$Sys->Set('ERRMAX', $Form->Get('ERRMAX'));
	$Sys->Set('HSTMAX', $Form->Get('HSTMAX'));
	$Sys->Set('ADMMAX', $Form->Get('ADMMAX'));
	$Sys->Save;
	
	# ���O�̐ݒ�
	push @$pLog, '�� ��{�ݒ�';
	push @$pLog, '�@�@�@ subject�ő吔�F' . $Form->Get('SUBMAX');
	push @$pLog, '�@�@�@ ���X�ő吔�F' . $Form->Get('RESMAX');
	push @$pLog, '�@�@�@ �A���J�[�ő吔�F' . $Form->Get('ANKERS');
	push @$pLog, '�@�@�@ �G���[���O�ő吔�F' . $Form->Get('ERRMAX');
	push @$pLog, '�@�@�@ �z�X�g���O�ő吔�F' . $Form->Get('HSTMAX');
	push @$pLog, '�@�@�@ �Ǘ����샍�O�ő吔�F' . $Form->Get('ADMMAX');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	���̑��ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionOtherSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('HEADTEXT', $Form->Get('HEADTEXT'));
	$Sys->Set('HEADURL', $Form->Get('HEADURL'));
	$Sys->Set('URLLINK', ($Form->Equal('URLLINK', 'on') ? 'TRUE' : 'FALSE'));
	$Sys->Set('LINKST', $Form->Get('LINKST'));
	$Sys->Set('LINKED', $Form->Get('LINKED'));
	$Sys->Set('PATHKIND', $Form->Get('PATHKIND'));
	$Sys->Set('FASTMODE', ($Form->Equal('FASTMODE', 'on') ? 1 : 0));
	$Sys->Set('BBSGET', ($Form->Equal('BBSGET', 'on') ? 1 : 0));
	$Sys->Set('UPCHECK', $Form->Get('UPCHECK'));
	$Sys->Save();
	
	# ���O�̐ݒ�
	push @$pLog, '�� ���̑��ݒ�';
	push @$pLog, '�@�@�@ �w�b�_�e�L�X�g�F' . $Sys->Get('HEADTEXT');
	push @$pLog, '�@�@�@ �w�b�_URL�F' . $Sys->Get('HEADURL');
	push @$pLog, '�@�@�@ URL���������N�F' . $Sys->Get('URLLINK');
	push @$pLog, '�@�@�@ �@�J�n���ԁF' . $Sys->Get('LINKST');
	push @$pLog, '�@�@�@ �@�I�����ԁF' . $Sys->Get('LINKED');
	push @$pLog, '�@�@�@ PATH��ʁF' . $Sys->Get('PATHKIND');
	push @$pLog, '�@�@�@ index.html���X�V���Ȃ��F' . $Sys->Get('FASTMODE');
	push @$pLog, '�@�@�@ bbs.cgi��GET���\\�b�h�F' . $Sys->Get('BBSGET');
	push @$pLog, '�@�@�@ �X�V�`�F�b�N�Ԋu�F' . $Sys->Get('UPCHECK');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�\���ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusViewSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('COUNTER', $Form->Get('COUNTER'));
	$Sys->Set('PRTEXT', $Form->Get('PRTEXT'));
	$Sys->Set('PRLINK', $Form->Get('PRLINK'));
	$Sys->Set('BANNER', ($Form->Equal('BANNER', 'on') ? 1 : 0));
	$Sys->Set('MSEC', ($Form->Equal('MSEC', 'on') ? 1 : 0));
	$Sys->Save;
	
	# ���O�̐ݒ�
	push @$pLog, '�� �\���ݒ�';
	push @$pLog, '�@�@�@ �J�E���^�[�A�J�E���g�F' . $Sys->Get('COUNTER');
	push @$pLog, '�@�@�@ PR���\\��������F' . $Sys->Get('PRTEXT');
	push @$pLog, '�@�@�@ PR�������NURL�F' . $Sys->Get('PRLINK');
	push @$pLog, '�@�@�@ �o�i�[�\\���F' . $Sys->Get('BANNER');
	push @$pLog, '�@�@�@ �~���b�\���F' . $Sys->Get('MSEC');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�K���ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPlusSecSetting
{
	my ($Sys, $Form, $pLog) = @_;
	my ($SYSTEM);
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	$Sys->Set('KAKIKO', ($Form->Equal('KAKIKO', 'on') ? 1 : 0));
	$Sys->Set('SAMBATM', $Form->Get('SAMBATM'));
	$Sys->Set('DEFSAMBA', $Form->Get('DEFSAMBA'));
	$Sys->Set('DEFHOUSHI', $Form->Get('DEFHOUSHI'));
	$Sys->Set('TRIP12', ($Form->Equal('TRIP12', 'on') ? 1 : 0));
	$Sys->Set('BBQ', ($Form->Equal('BBQ', 'on') ? 1 : 0));
	$Sys->Set('BBX', ($Form->Equal('BBX', 'on') ? 1 : 0));
	$Sys->Save;
	
	# ���O�̐ݒ�
	push @$pLog, '�� �K���ݒ�';
	push @$pLog, '�@�@�@ 2�d�J�L�R�K���F' . $Sys->Get('KAKIKO');
	push @$pLog, '�@�@�@ �A�����e�K���b���F' . $Sys->Get('SAMBATM');
	push @$pLog, '�@�@�@ Samba�ҋ@�b���F' . $Sys->Get('DEFSAMBA');
	push @$pLog, '�@�@�@ Samba��d���ԁF' . $Sys->Get('DEFHOUSHI');
	push @$pLog, '�@�@�@ 12���g���b�v�F' . $Sys->Get('TRIP12');
	push @$pLog, '�@�@�@ BBQ�F' . $Sys->Get('BBQ');
	push @$pLog, '�@�@�@ BBX�F' . $Sys->Get('BBX');
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	
	my @pluginSet = ();
	$Plugin->GetKeySet('ALL', '', \@pluginSet);
	my @validSet = $Form->GetAtArray('PLUGIN_VALID');
	
	my %order = ();
	for (my $i = 0; $i < scalar(@pluginSet); $i++) {
		my $id = $pluginSet[$i];
		
		my $valid = 0;
		foreach (@validSet) {
			if ($_ eq $id) {
				$valid = 1;
				last;
			}
		}
		$Plugin->Set($id, 'VALID', $valid);
		push @$pLog, $Plugin->Get('NAME', $id) . ' ��' . ($valid ? '�L��' : '����') . '�ɐݒ肵�܂����B';
		
		$_ = $Form->Get("PLUGIN_${id}_ORDER", $i + 1);
		$_ = $i + 1 if ($_ ne ($_ - 0));
		$_ -= 0;
		$order{$_} = [] if (!exists $order{$_});
		push @{$order{$_}}, $id;
	}
	
	$Plugin->{'ORDER'} = [map { @{$order{$_}} } sort {$a <=> $b} keys %order];
	$Plugin->Save($Sys);
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�v���O�C�����X�V
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginUpdate
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	
	# ���̍X�V�ƕۑ�
	$Plugin->Load($Sys);
	$Plugin->Update;
	$Plugin->Save($Sys);
	
	# ���O�̐ݒ�
	push @$pLog, '�� �v���O�C�����̍X�V';
	push @$pLog, '�@�v���O�C�����̍X�V���������܂����B';
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���@�\�ʐݒ�ݒ�
#	-------------------------------------------------------------------------------------
#	@param	$Sys	�V�X�e���ϐ�
#	@param	$Form	�t�H�[���ϐ�
#	@param	$pLog	���O�p
#	@return	�G���[�R�[�h
#
#------------------------------------------------------------------------------------------------------------
sub FunctionPluginOptionSetting
{
	my ($Sys, $Form, $pLog) = @_;
	
	# �����`�F�b�N
	my $Sec = $Sys->Get('ADMIN')->{'SECINFO'};
	my $cuser = $Sys->Get('ADMIN')->{'USER'};
	return 1000 if (!$Sec->IsAuthority($cuser, $ZP::AUTH_SYSADMIN, '*'));
	
	my $id = $Form->Get('PLGID');
	
	require './module/athelas.pl';
	my $Plugin = ATHELAS->new;
	$Plugin->Load($Sys);
	my $Config = PLUGINCONF->new($Plugin, $id);
	
	my $class = $Plugin->Get('CLASS', $id);
	
	if ($class->can('getConfig')) {
		my $conf = $class->getConfig();
		push @$pLog, "$class";
		
		foreach my $key (keys %$conf) {
			my $val = $Form->Get('PLUGIN_OPT_'.unpack('H*', $key));
			$Config->SetConfig($key, $val);
			push @$pLog, "$key ��ݒ肵�܂����B";
		}
	}
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

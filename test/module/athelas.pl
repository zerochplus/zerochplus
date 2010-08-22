#============================================================================================================
#
#	プラグイン管理モジュール
#	athelas.pl
#	-------------------------------------------------------------------------------------
#	2005.02.19 start
#
#============================================================================================================
package	ATHELAS;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($obj, %FILES, %CLASSES, %NAMES, %EXPS, %TYPES, %VALIDS, %CONFIGS, %CONFTYPES);
	
	$obj = {
		'FILE'		=> \%FILES,
		'CLASS'		=> \%CLASSES,
		'NAME'		=> \%NAMES,
		'EXPL'		=> \%EXPS,
		'TYPE'		=> \%TYPES,
		'VALID'		=> \%VALIDS,
		'CONFIG'	=> \%CONFIGS,
		'CONFTYPE'	=> \%CONFTYPES
	};
	bless $obj, $this;
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報読み込み
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, @elem);
	
	# ハッシュ初期化
	undef $this->{'FILE'};
	undef $this->{'CLASS'};
	undef $this->{'NAME'};
	undef $this->{'EXPL'};
	undef $this->{'TYPE'};
	undef $this->{'VALID'};
	undef $this->{'CONFIG'};
	undef $this->{'CONFTYPE'};
	
	$path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	if	(-e $path) {
		open PLUGINS, "< $path";
		while (<PLUGINS>) {
			chomp $_;
			@elem = split(/<>/, $_);
			if (@elem >= 6) {
				$this->{'FILE'}->{$elem[0]}		= $elem[1];
				$this->{'CLASS'}->{$elem[0]}	= $elem[2];
				$this->{'NAME'}->{$elem[0]}		= $elem[3];
				$this->{'EXPL'}->{$elem[0]}		= $elem[4];
				$this->{'TYPE'}->{$elem[0]}		= $elem[5];
				$this->{'VALID'}->{$elem[0]}	= $elem[6];
				$this->{'CONFIG'}->{$elem[0]}	= {};
				$this->{'CONFTYPE'}->{$elem[0]}	= {};
				$this->LoadConfig($elem[0]);
			}
		}
		close PLUGINS;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン個別設定読み込み (0ch+ Only)
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	なし
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub LoadConfig
{
	my $this = shift;
	my ($id) = @_;
	my ($file, $path, $CONFIG, $CONFTYPE);
	
	$file = $this->{'FILE'}->{$id};
	$CONFIG = $this->{'CONFIG'}->{$id};
	$CONFTYPE = $this->{'CONFTYPE'}->{$id};
	
	$file =~ /^(0ch_.*)\.pl$/;
	$path = "./plugin_conf/$1.cgi";
	if (-f $path) {
		open CONF, $path;
		while (<CONF>) {
			chomp $_;
			my ($type, $key, $val) = split(/<>/, $_, 3);
			$CONFIG->{$key} = $val;
			$CONFTYPE->{$key} = $type;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン個別設定保存 (0ch+ Only)
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	なし
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub SaveConfig
{
	my $this = shift;
	my ($id) = @_;
	my ($file, $path, $CONFIG, $CONFTYPE);
	
	$file = $this->{'FILE'}->{$id};
	$CONFIG = $this->{'CONFIG'}->{$id};
	$CONFTYPE = $this->{'CONFTYPE'}->{$id};
	
	mkdir './plugin_conf' if (! -e './plugin_conf');
	
	$file =~ /^(0ch_.*)\.pl$/;
	$path = "./plugin_conf/$1.cgi";
	if (open CONF, "> $path") {
		my ($key, $val, $type);
		foreach $key (sort keys %$CONFIG) {
			next unless (defined $CONFIG->{$key});
			$val = $CONFIG->{$key};
			$type = $CONFTYPE->{$key};
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
			print CONF "$type<>$key<>$val\n";
		}
		close CONF;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン個別設定初期値設定 (0ch+ Only)
#	-------------------------------------------------------------------------------------
#	@param	$id	
#	@return	なし
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub SetDefaultConfig
{
	my $this = shift;
	my ($id) = @_;
	my ($file, $path, $CONFIG, $CONFTYPE, $className);
	
	$file = $this->{'FILE'}->{$id};
	$CONFIG = $this->{'CONFIG'}->{$id};
	$CONFTYPE = $this->{'CONFTYPE'}->{$id};
	
	%$CONFIG = ();
	%$CONFTYPE = ();
	
	$file =~ /^0ch_(.*)\.pl$/;
	$className = "ZPL_$1";
	
	require "./plugin/$file";
	my $plugin = new $className;
	if ($className->can('getConfig')) {
		my $conf = $plugin->getConfig();
		foreach my $key (keys %$conf) {
			$CONFIG->{$key} = $conf->{$key}->{'default'};
			$CONFTYPE->{$key} = $conf->{$key}->{'valuetype'};
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報保存
#	-------------------------------------------------------------------------------------
#	@param	$Sys	MELKOR
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	my ($path, $data, $id);
	
	$path = '.' . $Sys->Get('INFO') . '/plugins.cgi';
	
	eval {
		open PLUGINS, "+> $path";
		flock PLUGINS, 2;
		binmode PLUGINS;
		truncate PLUGINS, 0;
		seek PLUGINS, 0, 0;
		foreach my $id (keys %{$this->{'FILE'}}) {
			$data = join('<>',
				$id,
				$this->{'FILE'}->{$id},
				$this->{'CLASS'}->{$id},
				$this->{'NAME'}->{$id},
				$this->{'EXPL'}->{$id},
				$this->{'TYPE'}->{$id},
				$this->{'VALID'}->{$id}
			);
			
			print PLUGINS "$data\n";
		}
		close PLUGINS;
		chmod $Sys->Get('PM-ADM'), $path;
	};
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグインIDセット取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	検索種別
#	@param	$name	検索ワード
#	@param	$pBuf	IDセット格納バッファ
#	@return	キーセット数
#
#------------------------------------------------------------------------------------------------------------
sub GetKeySet
{
	my $this = shift;
	my ($kind, $name, $pBuf) = @_;
	my ($key, $n);
	
	$n = 0;
	
	if ($kind eq 'ALL') {
		foreach	$key (keys %{$this->{NAME}}) {
			push @$pBuf, $key;
			$n++;
		}
	}
	else {
		foreach	$key (keys %{$this->{$kind}}) {
			if ($this->{$kind}->{$key} eq $name || $name eq 'ALL') {
				push @$pBuf, $key;
				$n++;
			}
		}
	}
	
	return $n;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報取得
#	-------------------------------------------------------------------------------------
#	@param	$kind	情報種別
#	@param	$key	ユーザID
#	@return	ユーザ情報
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($kind, $key) = @_;
	
	return $this->{$kind}->{$key};
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報設定
#	-------------------------------------------------------------------------------------
#	@param	$id		ユーザID
#	@param	$kind	情報種別
#	@param	$val	設定値
#	@return	なし
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
#	プラグイン追加
#	-------------------------------------------------------------------------------------
#	@param	$file	プラグインファイル名
#	@param	$valid	有効フラグ
#	@return	プラグインID
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($file, $valid) = @_;
	my ($id, $ret);
	
	$ret = undef;
	$id = time;
	while (exists $this->{'FILE'}->{$id}) {
		$id++;
	}
	if (-e "./plugin/$file") {
		if ($file =~ /0ch_(.*)\.pl/) {
			my $className = "ZPL_$1";
			eval {
				require("./plugin/$file");
				my $plugin = new $className;
				$this->{'FILE'}->{$id}		= $file;
				$this->{'CLASS'}->{$id}		= $className;
				$this->{'NAME'}->{$id}		= $plugin->getName();
				$this->{'EXPL'}->{$id}		= $plugin->getExplanation();
				$this->{'TYPE'}->{$id}		= $plugin->getType();
				$this->{'VALID'}->{$id}		= $valid;
				$this->{'CONFIG'}->{$id}	= {};
				$this->{'CONFTYPE'}->{$id}	= {};
				$this->LoadConfig($id);
				$ret = $id;
			};
		}
	}
	return '';
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報削除
#	-------------------------------------------------------------------------------------
#	@param	$id		削除プラグインID
#	@return	なし
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
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン情報更新
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Update
{
	my $this = shift;
	my (@files, $file, $plugin, @buff, $exist);
	
	if (-e './plugin') {
		opendir PLUGINS, './plugin';
		@files = readdir PLUGINS;
		closedir PLUGINS;
		# プラグイン追加・更新フェイズ
		foreach $file (@files) {
			if ($file =~ /^0ch_(.*)\.pl/) {
				my $className = "ZPL_$1";
				if ($this->GetKeySet('FILE', $file, \@buff) > 0) {
					require "./plugin/$file";
					$plugin = new $className;
					$this->{'NAME'}->{$buff[0]} = $plugin->getName();
					$this->{'EXPL'}->{$buff[0]} = $plugin->getExplanation();
					$this->{'TYPE'}->{$buff[0]} = $plugin->getType();
					$this->SetDefaultConfig($buff[0]);
					$this->LoadConfig($buff[0]);
					$this->SaveConfig($buff[0]);
					$plugin = undef;
				}
				else {
					$this->Add($file, 0);
				}
				undef @buff;
			}
		}
		# プラグイン削除フェイズ
		if ($this->GetKeySet('ALL', '', \@buff) > 0) {
			$exist = 0;
			foreach $plugin (@buff) {
				foreach $file (@files) {
					if ($this->Get('FILE', $plugin) eq $file) {
						$exist = 1;
						last;
					}
				}
				if ($exist == 0) {
					$this->Delete($plugin);
				}
				$exist = 0;
			}
		}
	}
	else {
		undef $this->{'FILE'};
		undef $this->{'CLASS'};
		undef $this->{'NAME'};
		undef $this->{'EXPL'};
		undef $this->{'TYPE'};
		undef $this->{'VALID'};
		undef $this->{'CONFIG'};
		undef $this->{'CONFTYPE'};
	}
}


#============================================================================================================
#
#	プラグイン個別設定管理モジュール (0ch+ Only)
#
#	-------------------------------------------------------------------------------------
#	2010.08.20 start 色々
#
#============================================================================================================

package	PLUGINCONF;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	$Plugin	ATHELAS
#	@param	$id		
#	@return	モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my ($Plugin, $id) = @_;
	my ($obj);
	
	$obj = {
		'PLUGIN'	=> $Plugin,
		'id'		=> $id
	};
	
	bless $obj, $this;
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン個別設定設定 (0ch+ Only)
#	-------------------------------------------------------------------------------------
#	@param	$key	
#	@param	$val	
#	@return	なし
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub SetConfig
{
	my $this = shift;
	my ($key, $val) = @_;
	my ($CONFIG, $CONFTYPE, $id, $type);
	
	$id = $this->{'id'};
	$CONFIG = $this->{'PLUGIN'}->{'CONFIG'}->{$id};
	$CONFTYPE = $this->{'PLUGIN'}->{'CONFTYPE'}->{$id};
	
	if (! defined $CONFTYPE->{$key}) {
		if (ref(\$val) eq 'SCALAR') {
	#		if (($val ^ $val) eq '0') {
	#			$type = 1;
	#		}
	#		else {
	#			$type = 2;
	#		}
			$type = 2;
		}
		else {
			$type = 0;
			return;
		}
		$CONFTYPE->{$key} = $type;
	}
	else {
		$type = $CONFTYPE->{$key};
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
	
	$CONFIG->{$key} = $val;
	
	$this->{'PLUGIN'}->SaveConfig($id);
}

#------------------------------------------------------------------------------------------------------------
#
#	プラグイン個別設定取得 (0ch+ Only)
#	-------------------------------------------------------------------------------------
#	@param	$key	
#	@return	プラグイン個別設定
#
#	2010.08.16 色々
#	-> プラグインの個別設定
#
#------------------------------------------------------------------------------------------------------------
sub GetConfig
{
	my $this = shift;
	my ($key) = @_;
	my ($CONFIG, $id);
	
	$id = $this->{'id'};
	$CONFIG = $this->{'PLUGIN'}->{'CONFIG'}->{$id};
	
	return $CONFIG->{$key};
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

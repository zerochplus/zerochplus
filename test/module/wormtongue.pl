#============================================================================================================
#
#	NGワード管理モジュール
#
#============================================================================================================
package	WORMTONGUE;

use strict;
use warnings;

#------------------------------------------------------------------------------------------------------------
#
#	モジュールコンストラクタ - new
#	-------------------------------------------
#	引　数：なし
#	戻り値：モジュールオブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $class = shift;
	
	my $obj = {
		'METHOD'	=> undef,
		'SUBSTITUTE'=> undef,
		'NGWORD'	=> undef,
	};
	
	bless $obj, $class;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード読み込み - Load
#	-------------------------------------------
#	引　数：$Sys : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($Sys) = @_;
	
	$this->{'NGWORD'} = [];
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . '/info/ngwords.cgi';
	
	if (open(my $fh, '<', $path)) {
		flock($fh, 2);
		my @datas = <$fh>;
		close($fh);
		map { s/[\r\n]+\z// } @datas;
		
		my @head = split(/<>/, shift @datas);
		$this->{'METHOD'} = $head[0];
		$this->{'SUBSTITUTE'} = $head[1];
		
		push @{$this->{'NGWORD'}}, @datas;
		return 0;
	}
	return 1;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード書き込み - Save
#	-------------------------------------------
#	引　数：$Sys : MELKOR
#	戻り値：0
#
#------------------------------------------------------------------------------------------------------------
sub Save
{
	my $this = shift;
	my ($Sys) = @_;
	
	my $path = $Sys->Get('BBSPATH') . '/' . $Sys->Get('BBS') . "/info/ngwords.cgi";
	
	if (open(my $fh, (-f $path ? '+<' : '>'), $path)) {
		flock($fh, 2);
		seek($fh, 0, 0);
		binmode($fh);
		
		print $fh "$this->{'METHOD'}<>$this->{'SUBSTITUTE'}\n";
		foreach (@{$this->{'NGWORD'}}) {
			print $fh "$_\n";
		}
		
		truncate($fh, tell($fh));
		close($fh);
	}
	chmod $Sys->Get('PM-ADM'), $path;
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード追加 - Set
#	-------------------------------------------
#	引　数：$key : NGワード
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Add
{
	my $this = shift;
	my ($key) = @_;
	
	push @{$this->{'NGWORD'}}, $key;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワードデータ取得 - Get
#	-------------------------------------------
#	引　数：$key : 取得キー
#			$default : デフォルト
#	戻り値：データ
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	
	my $val = $this->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワードデータ設定 - SetData
#	-------------------------------------------
#	引　数：$key  : 設定キー
#			$data : 設定データ
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{$key} = $data;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワードクリア - Clear
#	-------------------------------------------
#	引　数：なし
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Clear
{
	my $this = shift;
	
	$this->{'NGWORD'} = [];
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード調査 - Check
#	-------------------------------------------
#	引　数：$Form  : SAMWISE
#			$pList : チェックリスト(リファレンス)
#	戻り値：検知番号
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my $this = shift;
	my ($Form, $pList) = @_;
	
	foreach my $word (@{$this->{'NGWORD'}}) {
		next if ($word eq '');
		foreach my $key (@$pList) {
			my $work = $Form->Get($key);
			if ($work =~ /\Q$word\E/) {
				if ($this->{'METHOD'} eq 'host') {
					return 2;
				}
				elsif ($this->{'METHOD'} eq 'disable') {
					return 3;
				}
				else {
					return 1;
				}
			}
		}
	}
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	NGワード処理 - Method
#	-------------------------------------------
#	引　数：$Form  : SAMWISE
#			$pList : チェックリスト(リファレンス)
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Method
{
	my $this = shift;
	my ($Form, $pList) = @_;
	
	# 処理種別が代替か削除の場合のみ処理
	return unless ($this->{'METHOD'} eq 'delete' || $this->{'METHOD'} eq 'substitute');
	
	# 代替用文字列を設定
	my $substitute = '';
	if ($this->{'METHOD'} eq 'delete') {
		#$substitute = '<b><font color=red>削除</font></b>';
		$substitute = '';
	}
	else {
		$substitute = $this->{'SUBSTITUTE'};
		$substitute = '' if (! defined $substitute);
	}
	
	foreach my $word (@{$this->{'NGWORD'}}) {
		next if ($word eq '');
		foreach my $key (@$pList) {
			my $work = $Form->Get($key);
			if ($work =~ s/\Q$word\E/$substitute/g) {
				$Form->Set($key, $work);
			}
		}
	}
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

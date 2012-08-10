#============================================================================================================
#
#	アップデート通知
#	newrelease.pl
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#	---------------------------------------------------------------------------
#
#	2012.08.09 start
#
#============================================================================================================

package ZP_NEWRELEASE;

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
	my $this = shift;
	my ( $obj, %NEWRELEASE );
	
	$obj = {
		'NEWRELEASE'	=> \%NEWRELEASE
	};
	
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	初期化 - Init
#	-------------------------------------------------------------------------------------
#	引　数：$sys : MELKOR
#	戻り値：0
#
#------------------------------------------------------------------------------------------------------------
sub Init
{
	my $this = shift;
	my ( $sys ) = @_;
	undef $this->{'NEWRELEASE'};
	
	$this->{'NEWRELEASE'} = {
		'CheckURL'	=> 'http://zerochplus.sourceforge.jp/Release.txt',
		'Interval'	=> 60 * 60 * 24, # 24時間
		'RawVer'	=> $sys->Get('VERSION'),
		'CachePATH'	=>  '.' . $sys->Get('INFO') . '/Release.cgi',
		'CachePM'	=> $sys->Get('PM-ADM'),
		'Update'	=> 0,
	};
	
}


#------------------------------------------------------------------------------------------------------------
#
#	更新チェック - Check
#	-------------------------------------------------------------------------------------
#	引　数：なし
#	戻り値：0
#
#------------------------------------------------------------------------------------------------------------
sub Check
{
	my $this = shift;
	my $hash = $this->{'NEWRELEASE'};
	my ( $url, $interval, $rawver, @ver, $date, $path );
	
	
	$url = $hash->{'CheckURL'};
	$interval = $hash->{'Interval'};
	
	$rawver = $hash->{'RawVer'};
	# 0ch+ BBS n.m.r YYYYMMDD 形式であることをちょっと期待している
	# または 0ch+ BBS dev-rREV YYYYMMDD
	if ( $rawver =~ /(\d+(?:\.\d+)+)/ ) {
		@ver = split /\./, $1;
	} elsif ( $rawver =~ /dev-r(\d+)/ ) {
		@ver = ( 'dev', $1 );
	} else {
		@ver = ( 'dev', 0 );
	}
	$date = '00000000';
	if ( $rawver =~ /(\d{8})/ ) {
		$date = $1;
	}
	
	$path = $hash->{'CachePATH'};
	
	
	# キャッシュの有効期限が過ぎてたらデータをとってくる
	if ( ( stat $path )[9] < time - $interval ) {
		# 同時接続防止みたいな
		utime ( undef, undef, $path );
		
		require('./module/httpservice.pl');
		
		my $proxy = HTTPSERVICE->new;
		# URLを指定
		$proxy->setURI($url);
		# UserAgentを設定
		$proxy->setAgent($rawver);
		# タイムアウトを設定
		$proxy->setTimeout(3);
		
		# とってくるよ
		$proxy->request();
		
		# とれた
		if ( $proxy->getStatus() eq 200 ) {
			open ( FILE, "> $path" );
			print FILE $proxy->getContent();
			close FILE;
			chmod $hash->{'CachePM'}, $path;
		}
	}
	
	
	# 比較部
	my ( @release, $l, @newver, $newdate, $i, $newrelease, $vv, $nv );
	
	open ( FILE, "< $path" );
	while ( $l = <FILE> ) {
		# $l =~ s/\x0d?\x0a?$//;
		# samwiseと同等のサニタイジングを行います
		$l =~ s/[\x0d\x0a\0]//g;
		$l =~ s/"/&quot;/g;
		$l =~ s/</&lt;/g;
		$l =~ s/>/&gt;/g;

		push @release, $l;
	}
	close FILE;
	# 爆弾(BOM)処理
	$l = shift @release;
	$l =~ s/^\xef\xbb\xbf//;
	unshift @release, $l;
	
	# n.m.r形式であることを期待している
	@newver = split /\./, $release[0];
	# YYYY.MM.DD形式であることを期待している
	$newdate = join '', (split /\./, $release[2], 3);
	
	$i = 0;
	$newrelease = 0;
	# バージョン比較
	# とりあえず自verがdevなら無視(下の日付で確認)
	if ( $ver[0] ne 'dev' ) {
		foreach $nv ( @newver ) {
			$vv = shift @ver;
			if ( $vv < $nv ) {
				$newrelease = 1;
			} elsif ( $vv > $nv ) {
				# なぜかインストール済みの方があたらしい
				last;
			}
		}
	}
	# よくわかんなかったらあらためて日付で確認する
	unless ( $newrelease ) {
		if ( $date < $newdate ) {
			$newrelease = 1;
		}
	}
	
	
	$this->{'NEWRELEASE'}->{'Update'}	= $newrelease;
	$this->{'NEWRELEASE'}->{'Ver'}		= shift @release;
	$this->{'NEWRELEASE'}->{'URL'}		= 'http://sourceforge.jp/projects/zerochplus/releases/' . shift @release;
	$this->{'NEWRELEASE'}->{'Date'}		= shift @release;
	
	shift @release; # 4行目(空行)を消す
	# 残りはリリースノートとかそういうのが残る
	$this->{'NEWRELEASE'}->{'Detail'}	= \@release;
	
	return 0;

}

#------------------------------------------------------------------------------------------------------------
#
#	設定値取得 - Get
#	-------------------------------------------------------------------------------------
#	MELKORとかとおなじような感じで
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($key, $default) = @_;
	my ($val);
	
	$val = $this->{'NEWRELEASE'}->{$key};
	
	return (defined $val ? $val : (defined $default ? $default : undef));
}

#------------------------------------------------------------------------------------------------------------
#
#	設定値設定 - Set
#	-------------------------------------------------------------------------------------
#	MELKOR(ry
#
#------------------------------------------------------------------------------------------------------------
sub Set
{
	my $this = shift;
	my ($key, $data) = @_;
	
	$this->{'NEWRELEASE'}->{$key} = $data;
}

1;

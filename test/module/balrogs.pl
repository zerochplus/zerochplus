#============================================================================================================
#
#	検索モジュール(BALROGS)
#	balrogs.pl
#	-------------------------------------------------------------------------------------
#	2003.11.22 start
#	2004.09.18 システム改変に伴う変更
#
#============================================================================================================
package	BALROGS;

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
#	検索設定
#	-------------------------------------------------------------------------------------
#	@param	$SYS    : MELKOR
#	@param	$mode   : 0:全検索,1:BBS内検索,2:スレッド内検索
#	@param	$type   : 0:全検索,1:名前検索,2:本文検索
#			          4:ID(日付)検索
#	@param	$bbs    : 検索BBS名($mode=1の場合に指定)
#	@param	$thread : 検索スレッド名($mode=2の場合に指定)
#	@return	なし
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
	
	# 鯖内全検索
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
			
			# 板ディレクトリに.0ch_hiddenというファイルがあれば読み飛ばす
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
	# 掲示板内全検索
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
	# スレッド内全検索
	elsif ($mode == 2) {
		$set = "$bbs<>$thread";
		push @$pSearchSet, $set;
	}
	# 指定がおかすぃ
	else {
		return;
	}
	
	# datモジュール読み込み
	if (! defined $this->{'ARAGORN'}) {
		require './module/gondor.pl';
		$this->{'ARAGORN'} = ARAGORN->new;
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	検索実行
#	-------------------------------------------------------------------------------------
#	@param	$word : 検索ワード
#	@param	$f    : 前結果クリアフラグ
#	@return	なし
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
#	検索結果取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	結果セット
#
#------------------------------------------------------------------------------------------------------------
sub GetResultSet
{
	my $this = shift;
	
	return($this->{'RESULTSET'});
}

#------------------------------------------------------------------------------------------------------------
#
#	検索実装部
#	-------------------------------------------------------------------------------------
#	@param	$this : thisオブジェクト
#	@param	$word : 検索ワード
#	@return	なし
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
		# すべてのレス数でループ
		for ($i = 0 ; $i < $this->{'ARAGORN'}->Size() ; $i++) {
			$pDat = $this->{'ARAGORN'}->Get($i);
			@elem = split(/<>/, $$pDat);
			# 名前検索
			if ($this->{'TYPE'} == 0 || $this->{'TYPE'} & 1) {
				if (index($elem[0], $word) > -1) {
					$elem[0] =~ s/(\Q$word\E)/<span class="res">$word<\/span>/g;
					$bFind = 1;
				}
			}
			# 本文検索
			if ($this->{'TYPE'} == 0 || $this->{'TYPE'} & 2) {
				if (index($elem[3], $word) > -1) {
					$elem[3] =~ s/(\Q$word\E)/<span class="res">$word<\/span>/g;
					$bFind = 1;
				}
			}
			# ID or 日付検索
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

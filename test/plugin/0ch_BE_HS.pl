#============================================================================================================
#
#	拡張機能 - BE(HS)っぽいもの
#	0ch_BE_HS.pl
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#	導 入 前 に 必 ず r e a d m e . t x t を 読 ん で く だ さ い 。
#	読まないとあなたは明日の朝おきたら 首 を 寝 違 え て い ま す 。
#
#	---------------------------------------------------------------------------
#
#	2010.08.26 start
#
#============================================================================================================
package ZPL_BE_HS;

#------------------------------------------------------------------------------------------------------------
#
#	コンストラクタ
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	オブジェクト
#
#------------------------------------------------------------------------------------------------------------
sub new
{
	my $this = shift;
	my $obj={};
	bless($obj,$this);
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能名称取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	名称文字列
#
#------------------------------------------------------------------------------------------------------------
sub getName
{
	my	$this = shift;
	return 'BE(HS)っぽいもの';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能説明取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	説明文字列
#
#------------------------------------------------------------------------------------------------------------
sub getExplanation
{
	my	$this = shift;
	return '２ちゃんねるのBEにログインできるようにします';
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能タイプ取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	拡張機能タイプ(スレ立て:1,レス:2,read:4,index:8)
#
#------------------------------------------------------------------------------------------------------------
sub getType
{
	my	$this = shift;
	return (1 | 2);
}

#------------------------------------------------------------------------------------------------------------
#
#	拡張機能実行インタフェイス
#	-------------------------------------------------------------------------------------
#	@param	$sys	MELKOR
#	@param	$form	SAMWISE
#	@return	正常終了の場合は0
#
#------------------------------------------------------------------------------------------------------------
sub execute
{
	my $this = shift;
	my ($sys, $form, $type) = @_;
	
	# 名前欄を取得
	my $name = $form->Get('FROM');
	
	# 悪さ対策でとりあえず空にする
	$form->Set('BEID', '');
	
	if ( $name =~ /!BE.+!HS/ ) {
		
		my ( $beid, $key );
		
		if ( $name =~ /!BE(\d+)!HS.*?#(.+)$/ ) {
			$beid = $1;
			$key = $2;
		}
		elsif ( $name =~ /!BE(\d+)-#(.+)!HS/ ) {
			$beid = $1;
			$key = $2;
		}
		
		# トリップ変換してやるー
		my $trip = ConvertTrip($key);
		
		# とりあえず消す
		$name =~ s/!BE.+!HS//;
		$form->Set('FROM', $name);
		
		# BEプロフのURLですね！
		my $beprof = "http://be.2ch.net/test/p.php?i=$beid";
		
		# LWPの設定
		my ( $code, $content ) = BeGet($beprof);
		
		# HTML解析
		if ( $code ne 200 ) {
			$form->Set('BEID', "BE:取得エラー($code)");
			return 0;
		}
		
		# Shift_JISｪ…
		require Encode;
		Encode::from_to( $content, 'EUC-JP', 'Shift_JIS' );
		
		if ( $content =~ /<div id="sitename">\n<h1>(.+)<\/h1>/ ) {
		
			my $name = $1;
			$name =~ s|^.*◆([A-Za-z0-9\./]{10}).*$|$1|;
			
			# 入力トリップとプロフのトリップの一致を調べる
			if ( $trip eq $name ) {
				
				my $point = 0;
				
				# ポイント取得
				if ( $content =~ m/<p><b>be.{8}<\/b>:([0-9]+)<\/p>/ ) {
					$point = BeRank($1);
				}
				else {
					# おかしかったらみんな０ポイント
					$point = '2BP(0)';
				}
				
				$form->Set('BEID', "BE:$beid-$point");
				
			}
			else {
				#$form->Set('BEID', "BE:認証エラー($trip:$name)");
				return 0;
			}
			
		}
		else {
			$form->Set('BEID', 'BE:取得エラー(-1)');
			return 0;
		}
		
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	旧トリップ作成関数
#	-------------------------------------------------------------------------------------
#	@param	$key	トリップキー
#	@return	$trip	トリップ
#
#------------------------------------------------------------------------------------------------------------
sub ConvertTrip
{
	
	my ( $key ) = @_;
	
	# 従来のトリップ生成方式
	my $salt = substr($key . 'H.', 1, 2);
	$salt =~ s/[^\.-z]/\./go;
	$salt =~ tr/:;<=>?@[\\]^_`/ABCDEFGabcdef/;
	
	# 0x80問題再現
	$key =~ s/\x80[\x00-\xff]*$//;
	
	my $trip = substr(crypt($key, $salt), -10);
	
	return $trip;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	BEプロフィールページ取得
#	-------------------------------------------------------------------------------------
#	@param	$url	BEプロフ
#	@return	$code	HTTPステータス
#	@return $cont	BeプロフHTML
#
#------------------------------------------------------------------------------------------------------------
sub BeGet {
	
	my ( $url ) = @_;
	
	require LWP::UserAgent;
	my $ua   = new LWP::UserAgent;
	$ua->agent('Mozilla/5.0 (Windows; U; Windows NT 5.1; ja; rv:1.9.2.8) Gecko/20100722 Firefox/3.6.8');
	$ua->timeout(5);
	
	# とってくるよ
	my $req  = HTTP::Request->new(GET => $url);
	my $res  = $ua->request($req);
	my $cont = $res->content;
	my $code = $res->code;
	
	return ( $code, $cont );
	

}
#------------------------------------------------------------------------------------------------------------
#
#	BE会員ランク取得
#	-------------------------------------------------------------------------------------
#	@param	$point	ポイント
#	@return	ランク表示形式 2BP(0)
#
#------------------------------------------------------------------------------------------------------------
sub BeRank {
	
	my ( $point ) = @_;
	
	if ( $point < 10000 )		{ $point = "2BP($point)"; }
	elsif ( $point < 12000 )	{ $point = "BRZ($point)"; }
	elsif ( $point < 100000 )	{ $point = "PLT($point)"; }
	elsif ( $point < 500000 )	{ $point = "DIA($point)"; }
	elsif ( $point >= 500000 )	{ $point = "S★($point)"; }
	else						{ $point = "2BP(0)"; }
	
	return $point;
	
}


#============================================================================================================
#	Module END
#============================================================================================================
1;
__END__

#============================================================================================================
#
#	拡張機能 - 助けるよ
#	0ch_tasukeruyo.pl
#	---------------------------------------------------------------------------
#	2010.08.14 start
#
#============================================================================================================
package ZPL_tasukeruyo;

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
	my		$this = shift;
	my		$obj={};
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
	return '助けるよ';
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
	return '名前欄に tasukeruyo を記入するとUAを表\示します';
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
	return (16);
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
	my	$this = shift;
	my	($sys, $form, $type) = @_;
	
	if ( $type & 16 ) {
		my	($from, $koyuu, $agent, $tasuke, $mes, $ua);
		$from	= $form->Get('FROM');
		$koyuu	= $sys->Get('KOYUU');
		$koyuu	= $sys->Get('HOST') if (! defined $koyuu);
		$agent	= $sys->Get('AGENT');
		$mes	= $form->Get('MESSAGE');
		$ua		= $ENV{'HTTP_USER_AGENT'};
		
		if ( $from =~ /tasukeruyo/ ) {
			if ( $agent eq 'O' || $agent eq 'P' || $agent eq 'i' ) {
				$tasuke = "$ENV{'REMOTE_HOST'}($koyuu)";
			}
			else {
				$tasuke = "$ENV{'REMOTE_HOST'}($ENV{'REMOTE_ADDR'})";
			}
			
			$from =~ s#([\x81-\x9f\xe0-\xfc][\x40-\x7e\x80-\xfc]|[^\xa1-\xdf]|^)tasukeruyo#$1</b>$tasuke<b>#g;
			$form->Set('FROM', $from);
			
			$ua =~ s/</&lt;/g;
			$ua =~ s/>/&gt;/g;
			$form->Set('MESSAGE',"$mes<br> <hr> <font color=\"blue\">$ua</font>");
		}
	}
	
	return 0;
}

#============================================================================================================
#	Module END
#============================================================================================================
1;

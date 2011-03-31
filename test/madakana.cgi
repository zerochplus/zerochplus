#!/usr/bin/perl
#============================================================================================================
#
#	規制一覧表示用CGI
#	madakana.cgi
#	---------------------------------------------------------------------------
#	2011.03.18 start
#	2011.03.31 remake
#
#============================================================================================================

use strict;
use warnings;

#use CGI::Carp qw(fatalsToBrowser);
no warnings 'once';

# CGIの実行結果を終了コードとする
exit(MADAKANA());

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub MADAKANA
{
	
	my ( %SYS, $Page, $err );
	
	require './module/thorin.pl';
	$Page = new THORIN;
	
	# 初期化に成功したら内容を表示
	if (($err = Initialize(\%SYS, $Page)) == 0) {
		
		# ヘッダ表示
		PrintMadaHead(\%SYS, $Page);
		
		# 内容表示
		PrintMadaCont(\%SYS, $Page);
		
		# フッタ表示
		PrintMadaFoot(\%SYS, $Page);
		
	}
	else {
		PrintMadaError(\%SYS, $Page, $err);
	}
	
	$Page->Flush(0, 0, '');
	
	return $err;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgi初期化・前準備
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub Initialize
{
	my ($pSYS, $Page) = @_;
	my (@elem, @regs, $path);
	my ($oSYS, $oCONV);
	
	require './module/melkor.pl';
	require './module/galadriel.pl';
	require './module/samwise.pl';
	
	$oSYS	= new MELKOR;
	$oCONV	= new GALADRIEL;
	
	%$pSYS = (
		'SYS'	=> $oSYS,
		'CONV'	=> $oCONV,
		'PAGE'	=> $Page,
		'CODE'	=> 'Shift_JIS',
	);
	
	$pSYS->{'FORM'} = SAMWISE->new($oSYS->Get('BBSGET')),
	
	# システム初期化
	$oSYS->Init();
	
	
	# 夢が広がりんぐ
	$oSYS->{'MainCGI'} = $pSYS;
	
	# ホスト情報設定(DNS逆引き)
	$ENV{'REMOTE_HOST'} = $oCONV->GetRemoteHost() unless ($ENV{'REMOTE_HOST'});
	$pSYS->{'FORM'}->Set('HOST', $ENV{'REMOTE_HOST'});
	
	return 0;
	
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgiヘッダ出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaHead
{
	my ($Sys, $Page) = @_;
	my ($Caption, $Banner, $code, $HOST, $ADDR);
	
	require './module/legolas.pl';
	require './module/denethor.pl';
	$Caption = new LEGOLAS;
	$Banner = new DENETHOR;
	
	$Caption->Load($Sys->{'SYS'}, 'META');
	$Banner->Load($Sys->{'SYS'});
	
	$code	= $Sys->{'CODE'};
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>

 <meta http-equiv="Content-Type" content="text/html;charset=$code">
 <meta http-equiv="Content-Style-Type" content="text/css">
 <meta http-equiv="imagetoolbar" content="no">

HTML
	
	$Caption->Print($Page, undef);
	
	$Page->Print(" <title>まだかな、まだかな</title>\n\n");
	$Page->Print("</head>\n<!--nobanner-->\n<body>\n");
	
	# バナー出力
	$Banner->Print($Page, 100, 2, 0) if ($Sys->{'SYS'}->Get('BANNER'));
	
	$Page->Print(<<HTML);
<div style="color:navy;">
<h1 style="font-size:1em;font-weight:normal;margin:0;">まだかな、まだかな、まなかな(規制一覧表\)</h1>
<p style="margin:0;">
あなたのリモホ[<span style="color:red;font-weight:bold;">$HOST</span>]
</p>
<p>
by <font color="green">ぜろちゃんねるプラス ★</font>
</p>
<p>
##############################################################################<br>
# ここから<br>
</p>
HTML
	
}

#------------------------------------------------------------------------------------------------------------
#
#	read.cgi内容出力
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaCont
{
	my ($Sys, $Page) = @_;
	my ($BBS, $HOST, $ADDR, $BBSpath, @BBSkey, %BBSs, $path);
	
	require './module/nazguls.pl';
	$BBS	= new NAZGUL;
	$BBS->Load($Sys->{'SYS'});
	
	$HOST	= $Sys->{'FORM'}->Get('HOST');
	$ADDR	= $ENV{'REMOTE_ADDR'};
	$BBSpath	= $Sys->{'SYS'}->Get('BBSPATH');
	
	# BBSセットの取得
	$BBS->GetKeySet('ALL', '', \@BBSkey);
	
	# ハッシュに詰め込む
	foreach my $id (@BBSkey) {
		$BBSs{$BBS->Get('DIR', $id)} = $BBS->Get('NAME', $id);
	}
	
	foreach my $dir ( keys %BBSs ) {
		$Page->Print('<p>'."\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		$Page->Print("# <a href=\"$BBSpath/$dir/\">$BBSs{$dir}</a> [ $dir ]<br>\n");
		$Page->Print('#-----------------------------------------------------------------------------<br>'."\n");
		
		$path = "$BBSpath/$dir/info/access.cgi";
		
		if ( -e $path && open( SEC, "< $path") ) {
			while ( <SEC> ) {
				next if( $_ =~ /(?:disable|enable)<>(?:disable|host)\n/ );
				chomp;
				if ( $HOST =~ /$_/ || $ADDR =~ /$_/ ) {
					$_ = '<font color="red"><b>'.$_.'</b></font>';
				}
				$_ .= "\n";
				s/\n/<br>/g;
				s/(http:\/\/.*)<br>/<a href="$1" target="_blank">$1<\/a><br>/g;
				$Page->Print($_."\n");
			}
			close SEC;
		}
		else {
			$Page->Print('<span style="color:#AAA">Cannot open access.cgi.</span><br>'."\n");
		}
		
		$Page->Print('</p>'."\n");
		
	}
	

	
}

sub PrintMadaFoot
{
	my ($Sys, $Page) = @_;
	my ($ver, $cgipath);
	
	$ver		= $Sys->{'SYS'}->Get('VERSION');
	$cgipath	= $Sys->{'SYS'}->Get('CGIPATH');
	
	$Page->Print(<<HTML);
<p>
# ここまで<br>
##############################################################################<br>
</p>
</div>

<hr>

<div>
<a href="http://validator.w3.org/check?uri=referer"><img src="$cgipath/datas/html.gif" alt="Valid HTML 4.01 Transitional" height="15" width="80" border="0"></a>
<a href="http://0ch.mine.nu/">ぜろちゃんねる</a> <a href="http://zerochplus.sourceforge.jp/">プラス</a>
MADAKANA.CGI - $ver
</div>

</body>
</html>
HTML

}

#------------------------------------------------------------------------------------------------------------
#
#	madakana.cgiエラー表示
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub PrintMadaError
{
	my ($Sys, $Page, $err) = @_;
	my ($code);
	
	$code = 'Shift_JIS';
	
	# HTMLヘッダの出力
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><head><title>ＥＲＲＯＲ！！</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head><!--nobanner-->');
	$Page->Print('<html><body>');
	$Page->Print("<b>$err</b>");
	$Page->Print('</body></html>');
}


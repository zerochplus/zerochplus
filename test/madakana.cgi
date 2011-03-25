#!/usr/bin/perl

#============================================================================================================
#
#	madakana.cgi
#	規制一覧表(これはひどい)
#
#	by ぜろちゃんねるプラス
#	http://zerochplus.sourceforge.jp/
#
#	---------------------------------------------------------------------------
#
#	2011.03.18 start
#
#============================================================================================================

# 基本
use strict;
use warnings;

# デバッグ用
#use CGI::Carp qw(fatalsToBrowser);

# IP / リモートホスト 取得
my $ADDR = $ENV{'REMOTE_ADDR'};
my $HOST = GetRemoteHost($ADDR);

#------------------------------------------------------------------------------------------------------------
#
#	ヘッダー
#
#------------------------------------------------------------------------------------------------------------

print "Content-type: text/html\n\n"; 
print <<"HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
 <meta http-equiv="Content-Style-Type" content="text/css">
 <meta http-equiv="Content-Script-Type" content="text/javascript">
 <meta http-equiv="imagetoolbar" content="no">
 
 <title>まだかな、まだかな</title>
 
 <link rel="stylesheet" type="text/css" href="./datas/madakana.css">
 
</head>
<body text="navy">
<p>
まだかな、まだかな、まなかな
</p>
<p>
あなたのリモホ[<span style="color:red;font-weight:bold;">$HOST($ADDR)</span>]
</p>
<p>
by <font color="green">windyakin ★</font>
</p>

<p>
##############################################################################<br>
# ここから<br>
</p>

HEAD

#------------------------------------------------------------------------------------------------------------
#
#	メイン処理
#
#------------------------------------------------------------------------------------------------------------

my %bbss = ();

# 開いて掲示板一覧を取得する
# 掲示板一覧をハッシュで云々
if ( open( FILE, "< ./info/bbss.cgi" ) ) {
	foreach (<FILE>) {
		my @temp = split( /<>/, $_ );
		$bbss{$temp[2]} = $temp[3];
	}
	close FILE;
}

foreach my $key ( keys %bbss ) {
	
	print '<p>'."\n";
	print '#-----------------------------------------------------------------------------<br>'."\n";
	print "# $bbss{$key} [ $key ]<br>\n";
	print '#-----------------------------------------------------------------------------<br>'."\n";
	
	my $path = "../$key/info/access.cgi";
	
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
			print $_."\n";
		}
		close SEC;
	}
	else {
		print '<span style="color:#AAA">Cannot open access.cgi.<br>'."\n";
	}
	
	print '</p>'."\n";
	
}

print <<FOOT;

<p>
# ここまで<br>
##############################################################################<br>
</p>

</body>
</html>
FOOT


exit;

#------------------------------------------------------------------------------------------------------------
#
#	リモートホスト取得(わざわざIPから逆引き)
#	-------------------------------------------------------------------------------------
#	@param	IPアドレス
#	@return	リモートホスト 逆引きできない場合はIPアドレス
#
#------------------------------------------------------------------------------------------------------------
sub GetRemoteHost
{
	
	my $ADDR = shift;
	
	my $HOST = gethostbyaddr(pack("C4", split(/\./,$ADDR)), 2);
	
	return ( defined($HOST) ? $HOST : $ADDR );
	
}

__END__


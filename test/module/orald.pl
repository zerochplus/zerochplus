#============================================================================================================
#
#	エラー情報管理モジュール(ORALD)
#	orald.pl
#	---------------------------------------
#	2003.02.05 start
#------------------------------------------------------------------------------------------------------------
#
#	Load																			; エラー情報読み込み
#	Get																				; エラー情報取得
#	Print																			; エラーページ出力(read)
#
#============================================================================================================
package	ORALD;

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
	my ($obj);
	
	$obj = {
		'SUBJECT' => undef,
		'MESSAGE' => undef
	};
	bless $obj, $this;
	
	return $obj;
}

#------------------------------------------------------------------------------------------------------------
#
#	エラー情報読み込み - Load
#	-------------------------------------------
#	引　数：$M : MELKOR
#	戻り値：なし
#
#------------------------------------------------------------------------------------------------------------
sub Load
{
	my $this = shift;
	my ($M) = @_;
	my (@readBuff, $path, $err, $subj, $msg, @elem);
	
	undef %{$this->{'ERR'}};
	$path = '.' . $M->Get('INFO') . '/errmsg.cgi';
	
	if (-e $path) {				# ファイルが存在すれば
		open ERR, "< $path";	# ファイルオープン
		@readBuff = <ERR>;
		close ERR;
		
		foreach (@readBuff) {
			# '#' はコメント行なので読まない
			unless	(/^#.*/) {
				chomp $_;
				@elem = split(/<>/, $_);
				$this->{'SUBJECT'}->{$elem[0]} = $elem[1];
				$this->{'MESSAGE'}->{$elem[0]} = $elem[2];
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	エラー情報取得 - Get
#	-------------------------------------------
#	引　数：$err : エラー番号
#	戻り値：($subj,$msg)
#
#------------------------------------------------------------------------------------------------------------
sub Get
{
	my $this = shift;
	my ($err, $kind) = @_;
	my ($val);
	
	$val = $this->{$kind}->{$err};
	
	return $val;
}

#------------------------------------------------------------------------------------------------------------
#
#	エラーページ出力 - PrintBBS
#	-------------------------------------------
#	引　数：$T,$M,$S : THORIN,MELKOR
#			$err     : エラー番号
#			$f       : モード(1:携帯用,0:PC用)
#	戻り値：なし
#
#	2010.08.13 windyakin ★
#	 -> ID末尾改造による変更
#
#------------------------------------------------------------------------------------------------------------
sub Print
{
	my $this = shift;
	my ($Sys, $Page, $err, $mode) = @_;
	my ($Form, $SYS, $version, $bbsPath, $message, $host);
	
	$Form		= $Sys->{'FORM'};
	$SYS		= $Sys->{'SYS'};
	$version	= $SYS->Get('VERSION');
	$bbsPath	= $SYS->Get('BBSPATH') . '/' . $SYS->Get('BBS');
	$message	= $this->{'MESSAGE'}->{$err};
	
	$mode = '0' if (! defined $mode);
	
	# エラーメッセージの置換
	while ($message =~ /{!(.*?)!}/) {
		my $rep = $SYS->Get($1);
		$message =~ s/{!$1!}/$rep/;
	}
	
	# リモートホストの取得
	$host = $Form->Get('HOST');
	if ($host eq '') {
		$host = $Sys->{'CONV'}->GetRemoteHost();
	}
	
	# エラーログを保存
	{
		require './module/peregrin.pl';
		my $P = PEREGRIN->new;
		$P->Load($SYS, 'ERR', '');
		$P->Set('', $err, $version, $host, $mode);
		$P->Save($SYS);
	}
	
	if ($mode eq 'O') {
		my $subject = $this->{'SUBJECT'}->{$err};
		$Page->Print("Content-type: text/html\n\n<html><head><title>");
		$Page->Print("ＥＲＲＯＲ！</title></head><!--nobanner-->\n");
		$Page->Print("<body><font color=red>ERROR:$subject</font><hr>");
		$Page->Print("$message<hr><a href=\"$bbsPath/i/index.html\">こちら</a>");
		$Page->Print("から戻ってください</body></html>");
	}
	else {
		my $COOKIE = $Sys->{'COOKIE'};
		my $oSET = $Sys->{'SET'};
		my ($name, $mail, $msg);
		
		$name = $Form->Get('NAME');
		$mail = $Form->Get('MAIL');
		$msg = $Form->Get('MESSAGE');
		
		# cookie情報の出力
		$COOKIE->Set('NAME', $name) if ($oSET->Equal('BBS_NAMECOOKIE_CHECK', 'checked'));
		$COOKIE->Set('MAIL', $mail) if ($oSET->Equal('BBS_MAILCOOKIE_CHECK', 'checked'));
		$COOKIE->Out($Page, $oSET->Get('BBS_COOKIEPATH'), 60 * 24 * 30);
		
		$Page->Print("Content-type: text/html\n\n");
		$Page->Print(<<HTML);
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html lang="ja">
<head>
 
 <meta http-equiv="Content-Type" content="text/html; charset=Shift_JIS">
 
 <title>ＥＲＲＯＲ！</title>
 
</head>
<!--nobanner-->
<body>
<!-- 2ch_X:error -->
<div style="margin-bottom:2em;">
<font size="+1" color="#FF0000"><b>ＥＲＲＯＲ：$message</b></font>
</div>

<blockquote>
ホスト<b>$host</b><br>
<br>
名前： <b>$name</b><br>
E-mail： $mail<br>
内容：<br>
$msg
<br>
<br>
</blockquote>
<hr>
<div class="reload">こちらでリロードしてください。<a href="$bbsPath/">&nbsp;GO!</a></div>
<div align="right">$version</div>
</body>
</html>
HTML
		
	}
}

#============================================================================================================
#	モジュール終端
#============================================================================================================
1;

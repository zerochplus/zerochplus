#!/usr/bin/perl

#============================================================================================================
#
#	madakana.cgi
#	�K���ꗗ�\(����͂Ђǂ�)
#
#	by ���낿���˂�v���X
#	http://zerochplus.sourceforge.jp/
#
#	---------------------------------------------------------------------------
#
#	2011.03.18 start
#
#============================================================================================================

# ��{
use strict;
use warnings;

# �f�o�b�O�p
#use CGI::Carp qw(fatalsToBrowser);

#------------------------------------------------------------------------------------------------------------
#
#	�w�b�_�[
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
 
 <title>�܂����ȁA�܂�����</title>
 
 <link rel="stylesheet" type="text/css" href="./datas/madakana.css">
 
</head>
<body text="navy">
<p>
�܂����ȁA�܂����ȁA�܂Ȃ���
</p>
<p>
���Ȃ��̃����z[<span style="color:red;font-weight:bold;">$ENV{'REMOTE_HOST'}</span>]
</p>
<p>
by <font color="green">windyakin ��</font>
</p>

<p>
##############################################################################<br>
# ��������<br>
</p>

HEAD

#------------------------------------------------------------------------------------------------------------
#
#	���C������
#
#------------------------------------------------------------------------------------------------------------

my %bbss = ();

# �J���Čf���ꗗ���擾����
# �f���ꗗ���n�b�V���ŉ]�X
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
			if ( $ENV{"REMOTE_HOST"} =~ /$_/ ) {
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
		print '<span style="color:#aaaaaa">Cannot open access.cgi.<br>'."\n";
	}
	
	print '</p>'."\n";
	
}

print <<FOOT;

<p>
# �����܂�<br>
##############################################################################<br>
</p>

</body>
</html>
FOOT


exit;

__END__


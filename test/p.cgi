#!/usr/bin/perl
#============================================================================================================
#
#	�g�їp�y�[�W�\����pCGI
#	p.cgi
#	---------------------------------------------
#	2004.09.15 �V�X�e�����ςɔ����V�K�쐬
#
#============================================================================================================

use strict;
use warnings;

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(PCGI());

#------------------------------------------------------------------------------------------------------------
#
#	p.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PCGI
{
	my ($Sys, $Threads, $Set, $Page, $Form, $Conv);
	my (%pPath, @tList);
	my ($base, $max, $err);
	
	require './module/baggins.pl';
	require './module/isildur.pl';
	require './module/galadriel.pl';
	require './module/melkor.pl';
	require './module/samwise.pl';
	require './module/thorin.pl';
	
	$Threads	= new BILBO;
	$Conv		= new GALADRIEL;
	$Set		= new ISILDUR;
	$Sys		= new MELKOR;
	$Form		= SAMWISE->new(0);
	$Page		= new THORIN;
	
	$max = 0;
	$err = 1;
	
	# url����p�X�����
	GetPathData(\%pPath);
	
	# ���W���[���̏�����
	$Form->DecodeForm(1);
	$Sys->Init();
	$Sys->Set('BBS', $pPath{'bbs'});
	$err = $Set->Load($Sys);
	
	if ($err == 1) {
		$Threads->Load($Sys);
		
		# �X���b�h���X�g�̍쐬
		if ($Form->Equal('method', '')) {
			# ��������
			$max = CreateThreadList($Threads, $Set, \@tList, \%pPath, '');
		}
		else {
			# ��������
			$max = CreateThreadList($Threads, $Set, \@tList, \%pPath, $Form->Get('word', ''));
		}
	}
	
	# �y�[�W�̏o��
	PrintHead($Page, $Sys, $Set, $pPath{'st'}, $max);
	PrintThreadList($Page, $Sys, $Conv, \@tList) if ($err == 1);
	PrintFoot($Page, $Sys, $Set, $pPath{'st'}, $max);
	
	# ��ʂ֏o��
	$Page->Flush(0, 0, '');
}

#------------------------------------------------------------------------------------------------------------
#
#	�w�b�_�����o��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$num	�\����
#	@param	$last	�ŏI��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintHead
{
	my ($Page, $Sys, $Set, $start, $last) = @_;
	my ($path, $st, $bbs, $code);
	
	$path	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . '/p.cgi';
	$bbs	= $Sys->Get('BBS');
	$start	= $start - $Set->Get('BBS_MAX_MENU_THREAD');
	$st		= $start < 1 ? 1 : $start;
	$code	= 'Shift_JIS';
	
	# HTML�w�b�_�̏o��
	$Page->Print("Content-type: text/html\n\n");
	$Page->Print('<html><!--nobanner--><head><title>i-mode 0ch</title>');
	$Page->Print("<meta http-equiv=Content-Type content=\"text/html;charset=$code\">");
	$Page->Print('</head>');
	$Page->Print("<body><form action=\"$path/$bbs\" method=\"POST\" utn>");
	
	if ($Sys->Get('PATHKIND')) {
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$st\">�O</a> ");
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$last\">��</a><br>\n");
	}
	else {
		$Page->Print("<a href=\"$path/$bbs/$st\">�O</a> ");
		$Page->Print("<a href=\"$path/$bbs/$last\">��</a><br>\n");
	}
	$Page->Print("<input type=hidden name=method value=search>");
	$Page->Print("<input type=text name=word><input type=submit value=\"����\"><hr>");
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h���X�g�̕\��
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$Conv	GALADRIEL
#	@param	$pList	���X�g�i�[�o�b�t�@
#	@param	$base	�x�[�X�p�X
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintThreadList
{
	my ($Page, $Sys, $Conv, $pList) = @_;
	my (@elem, $path);
	
	foreach (@{$pList}) {
		@elem = split(/<>/, $_);
		$path = $Conv->CreatePath($Sys, 1, $Sys->Get('BBS'), $elem[1], 'l10');
		$Page->Print("$elem[0]: <a href=\"$path\">$elem[2]($elem[3])</a><br>\n");
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�t�b�^�����o�� - PrintHead
#	-------------------------------------------------------------------------------------
#	@param	$Page	THORIN
#	@param	$Sys	MELKOR
#	@param	$num	�\����
#	@param	$last	�ŏI��
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub PrintFoot
{
	my ($Page, $Sys, $Set, $start, $last) = @_;
	my ($ver, $path, $st, $bbs);
	
	$path	= $Sys->Get('SERVER') . $Sys->Get('CGIPATH') . '/p.cgi';
	$bbs	= $Sys->Get('BBS');
	$ver	= $Sys->Get('VERSION');
	$start	= $start - $Set->Get('BBS_MAX_MENU_THREAD');
	$st		= $start < 1 ? 1 : $start;
	
	if ($Sys->Get('PATHKIND')) {
		$Page->Print("<hr><a href=\"$path?bbs=$bbs&st=$st\">�O</a> ");
		$Page->Print("<a href=\"$path?bbs=$bbs&st=$last\">��</a><br>\n");
	}
	else {
		$Page->Print("<hr><a href=\"$path/$bbs/$st\">�O</a> ");
		$Page->Print("<a href=\"$path/$bbs/$last\">��</a><br>\n");
	}
	$Page->Print("<hr>$ver</form></body></html>\n");
}

#------------------------------------------------------------------------------------------------------------
#
#	�p�X�f�[�^���
#	-------------------------------------------------------------------------------------
#	@param	$pHash	�n�b�V���̎Q��
#	@return	�Ȃ�
#
#	2010.08.12 windyakin ��
#	 -> http://0ch.mine.nu/test/read.cgi/jikken/1273239400/5 �Ή�
#
#------------------------------------------------------------------------------------------------------------
sub GetPathData
{
	my ($pHash) = @_;
	my (@plist, $var, $val);
	
	$pHash->{'bbs'} = '';
	$pHash->{'st'} = 0;
	
	if ($ENV{'PATH_INFO'}) {
		use CGI;
		@plist = split(/\//, CGI::escapeHTML($ENV{'PATH_INFO'}));
		$pHash->{'bbs'} = $plist[1] if (defined $plist[1]);
		$pHash->{'st'} = int($plist[2] || 0);
	}
	else {
		@plist = split(/&/, $ENV{'QUERY_STRING'});
		foreach (@plist) {
			($var, $val) = split(/=/, $_);
			$pHash->{$var} = $val;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#
#	�X���b�h���X�g�̐���
#	-------------------------------------------------------------------------------------
#	@param	$Threads	BILBO
#	@param	$Set		ISILDUR
#	@param	$pList		���ʊi�[�p�z��
#	@param	$pHash		���n�b�V��
#	@param	$keyWord	�������[�h
#	@return	���X�g�Ō�̃C���f�N�X
#
#------------------------------------------------------------------------------------------------------------
sub CreateThreadList
{
	my ($Threads, $Set, $pList, $pHash, $keyWord) = @_;
	my (@threadSet, $threadNum, $max, $start);
	my ($key, $subject, $res, $i, $data);
	
	# �X���b�h�ꗗ�̎擾
	$Threads->GetKeySet('ALL', '', \@threadSet);
	$threadNum = @threadSet;
	
	# �������[�h�����̏ꍇ�͊J�n����X���b�h�\���ő吔�܂ł̃��X�g���쐬
	if ($keyWord eq '') {
		$start	= $pHash->{'st'} > $threadNum ? $threadNum : $pHash->{'st'};
		$start	= $start < 1 ? 1 : $start;
		$max	= $start + $Set->Get('BBS_MAX_MENU_THREAD');
		$max	= $max < $threadNum ? $max : $threadNum + 1;
		$max	= $max == $start ? $max + 1 : $max;
		for ($i = $start ; $i < $max ; $i++) {
			$key		= $threadSet[$i - 1];
			$subject	= $Threads->Get('SUBJECT', $key);
			$res		= $Threads->Get('RES', $key);
			$data		= "$i<>$key<>$subject<>$res";
			push @{$pList}, $data;
		}
	}
	# �������[�h������ꍇ�͌������[�h���܂ޑS�ẴX���b�h�̃��X�g���쐬
	else {
		my $nextNum = 1;
		$max	= $threadNum;
		$start	= 1;
		for ($i = $start;$i < $max + 1;$i++) {
			$key		= $threadSet[$i - 1];
			$subject	= $Threads->Get('SUBJECT', $key);
			if ($subject =~ /$keyWord/) {
				$res	= $Threads->Get('RES', $key);
				$data	= "$i<>$key<>$subject<>$res";
				push @{$pList}, $data;
				$nextNum = $i;
			}
		}
		$max = $nextNum + 1;
	}
	return $max;
}


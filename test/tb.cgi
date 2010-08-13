#!/usr/bin/perl
#============================================================================================================
#
#	�g���b�N�o�b�N��MCGI
#	trackback.cgi
#	---------------------------------------------------------------------------
#	2005.11.11 start
#	2005.12.30 2ch�݊��d�l�ɏC��
#	---------------------------------------------------------------------------
#
#	���g���b�N�o�b�N���M��	�F�`/tb.cgi/[bbs]/[thread key]
#							�F�`/tb.cgi/[bbs]/[thread key]/[res num]
#	��RSS�擾��(������)		�F�`/tb.cgi/[bbs]?__mode=rss
#
#============================================================================================================

# CGI�̎��s���ʂ��I���R�[�h�Ƃ���
exit(TrackBackCGI());

#------------------------------------------------------------------------------------------------------------
#
#	trackback.cgi���C��
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	����I��:1,�ُ�I��:-1,-2
#
#------------------------------------------------------------------------------------------------------------
sub TrackBackCGI
{
	my ($sys, $form, $bbs, $thread, $res);
	
	# PATHINFO�̉��
	($bbs, $thread, $res) = getPathInfo();
	
	# post���̉��
	require './module/samwise.pl';
	$form = new SAMWISE;
	$form->DecodeForm(1);
	
	require './module/melkor.pl';
	$sys = new MELKOR;
	$sys->Init();
	
	#---------------------------------------------------------------------------
	# RSS���[�h
	if ($form->Equal('__mode', 'rss')) {
		# PATH_INFO�̃`�F�b�N
		if ($bbs eq '') {
			sendTBResponse(1);
			return -2;
		}
		# ������
	}
	#---------------------------------------------------------------------------
	# �g���b�N�o�b�N���[�h
	else {
		# PATH_INFO�̃`�F�b�N
		if ($bbs eq '' || $thread eq '') {
			sendTBResponse(1);
			return -1;
		}
		
		# ��M�����`�F�b�N
		if ($form->Equal('url', '')) {
			sendTBResponse(1);
			return -10;
		}
		
		# dat�̍X�V
		if (updateResponse($sys, $form, $bbs, $thread, $res) == 0) {
			sendTBResponse(0);
		}
		else {
			sendTBResponse(1);
		}
	}
	
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	PATHINFO���̎擾
#	-------------------------------------------------------------------------------------
#	@param	�Ȃ�
#	@return	BBS,�X���b�h�L�[,���X�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub getPathInfo
{
	@infos = split(/\//, $ENV{'PATH_INFO'});
	return ($infos[1], $infos[2], $infos[3]);
}

#------------------------------------------------------------------------------------------------------------
#
#	�g���b�N�o�b�N�����̏o��
#	-------------------------------------------------------------------------------------
#	@param	$err	�G���[�R�[�h
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub sendTBResponse
{
	my ($err) = @_;
	my ($errmsg, $body);
	
	if ($err != 0) {
		$errmsg = '<message>ERROR!</message>';
	}
	
	$body = "Content-type: text/html\n\n";
	$body .= '<?xml version="1.0" encoding="iso-8859-1"?>';
	$body .= "<response><error>$err</error>";
	$body .= $errmsg;
	$body .= '</response>';
	
	print $body;
}

#------------------------------------------------------------------------------------------------------------
#
#	BBS�̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$sys	�V�X�e�����
#	@param	$form	�t�H�[�����
#	@param	$bbs	BBS
#	@param	$thread	�X���b�h�L�[
#	@param	$res	���X�ԍ�
#	@return	�Ȃ�
#
#------------------------------------------------------------------------------------------------------------
sub updateResponse
{
	my ($sys, $form, $bbs, $thread, $res) = @_;
	my ($Logger, $oBBSupport, $bbspath, $id, $ret);
	
	if (! $form->IsExist('title')) {
		$form->Set('title', '�i����j');
	}
	
	#---------------------------------------------------------------------------
	# ���O�̏�������
	require './module/galadriel.pl';
	require './module/imrahil.pl';
	$Logger = new IMRAHIL;
	$bbspath = $sys->Get('BBSPATH') . "/$bbs";
	$id = GALADRIEL::MakeID(undef, $sys->Get('SERVER'), 8);
	$sys->Set('BBS', $bbs);
	
	if ($Logger->Open("$bbspath/info/tb_$thread", $sys->Get('HISMAX'), 2 | 4) == 0) {
		my @result;
		if ($Logger->search(1, $id, \@result) > 0) {
			$Logger->Close();
			return -1;
		}
		$Logger->Put($id, $thread, $res, $form->Get('url'), $form->Get('title'));
		$Logger->Write();
		$Logger->Close();
	}
	
	#---------------------------------------------------------------------------
	# dat���X�V����
	if (($ret = updateDatFile($sys, $form, $bbs, $thread, $res, $id)) != 0) {
		return $ret;
	}
	
	#---------------------------------------------------------------------------
	# �f���̍X�V
	require './module/varda.pl';
	$oBBSupport = new VARDA;
	
	eval {
		$sys->Set('MODE', 'CREATE');
		$oBBSupport->Init($sys, undef);
		$oBBSupport->CreateIndex();
		$oBBSupport->CreateIIndex();
		$oBBSupport->CreateSubback();
	};
	return 0;
}

#------------------------------------------------------------------------------------------------------------
#
#	dat�t�@�C���̍X�V
#	-------------------------------------------------------------------------------------
#	@param	$sys	�V�X�e�����
#	@param	$form	�t�H�[�����
#	@param	$bbs	BBS
#	@param	$thread	�X���b�h�L�[
#	@param	$res	���X�ԍ�
#	@param	$id		ID
#	@return	�G���[�ԍ�
#
#------------------------------------------------------------------------------------------------------------
sub updateDatFile
{
	my ($sys, $form, $bbs, $thread, $res, $id) = @_;
	my ($ret, $bbspath, $datpath);
	
	require './module/gondor.pl';
	$bbspath = $sys->Get('BBSPATH') . "/$bbs";
	$datpath = "$bbspath/dat/$thread.dat";
	$ret = -1000;
	
	#---------------------------------------------------------------------------
	# ���X�w�肪����ꍇ�̓��X�ւ̃g���b�N�o�b�N
	if ($res > 0) {
		my $Dat = new ARAGORN;
		if ($Dat->Load($sys, $datpath, 0)) {
			eval {
				my $pRes = $Dat->Get($res - 1);
				my @elem = split(/<>/, $$pRes);
				
				# ��؂肪�Ȃ��ꍇ�͋�؂��t������
				if (! ($elem[3] =~ /<hr><small>��/)) {
					$elem[3] .= '<hr><small>�����̃��X�ւ̃g���b�N�o�b�N</small>';
				}
				$elem[3] .= '<br><small>[' . $form->Get('title') . '] ' . $form->Get('url') . '</small>';
				
				# dat�̕ۑ�
				my $data = join('<>', @elem);
				$Dat->Set($res - 1, $data);
				$Dat->Save($sys);
			};
			$Dat->Close();
			$ret = 0;
		}
	}
	#---------------------------------------------------------------------------
	# ���X�w�肪�Ȃ��ꍇ�̓X���b�h�ւ̃g���b�N�o�b�N
	else {
		require './module/galadriel.pl';
		if (($res = ARAGORN::GetNumFromFile($datpath)) < ($sys->Get('RESMAX') - 1)) {
			my ($data, $msg);
			my $date = GALADRIEL::GetDate(undef, undef) . " ID:$id0";
			$msg .= '�y�g���b�N�o�b�N������z�iver.0.10�j<br>';
			$msg .= '[�^�C�g��] ' . $form->Get('title') . '<br>';
			$msg .= '[���u���O] ' . $form->Get('blog_name') . '<br>' . $form->Get('url') . '<br>';
			$msg .= '[���v��]<br>' . $form->Get('excerpt');
			$data = "�g���b�N�o�b�N ��<>sage<>$date<>$msg<>\n";
			
			# dat�֒ǋL
			if (ARAGORN::DirectAppend($sys, $datpath, $data) == 0) {
				# subject�̍X�V
				require './module/baggins.pl';
				my $threadList = new BILBO;
				$threadList->Load($sys);
				$threadList->Set($thread, 'RES', $res + 1);
				$threadList->Save($sys);
				$ret = 0;
			}
		}
	}
	return $ret;
}

#============================================================================================================
#	Module END
#============================================================================================================

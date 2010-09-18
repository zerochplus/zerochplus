#!/usr/bin/perl
#============================================================================================================
#
#	トラックバック受信CGI
#	trackback.cgi
#	---------------------------------------------------------------------------
#	2005.11.11 start
#	2005.12.30 2ch互換仕様に修正
#	---------------------------------------------------------------------------
#
#	■トラックバック送信時	：～/tb.cgi/[bbs]/[thread key]
#							：～/tb.cgi/[bbs]/[thread key]/[res num]
#	■RSS取得時(未実装)		：～/tb.cgi/[bbs]?__mode=rss
#
#============================================================================================================

# CGIの実行結果を終了コードとする
exit(TrackBackCGI());

#------------------------------------------------------------------------------------------------------------
#
#	trackback.cgiメイン
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	正常終了:1,異常終了:-1,-2
#
#------------------------------------------------------------------------------------------------------------
sub TrackBackCGI
{
	my ($sys, $form, $bbs, $thread, $res);
	
	# PATHINFOの解析
	($bbs, $thread, $res) = getPathInfo();
	
	# post情報の解析
	require './module/samwise.pl';
	$form = new SAMWISE;
	$form->DecodeForm(1);
	
	require './module/melkor.pl';
	$sys = new MELKOR;
	$sys->Init();
	
	#---------------------------------------------------------------------------
	# RSSモード
	if ($form->Equal('__mode', 'rss')) {
		# PATH_INFOのチェック
		if ($bbs eq '') {
			sendTBResponse(1);
			return -2;
		}
		# 未実装
	}
	#---------------------------------------------------------------------------
	# トラックバックモード
	else {
		# PATH_INFOのチェック
		if ($bbs eq '' || $thread eq '') {
			sendTBResponse(1);
			return -1;
		}
		
		# 受信情報をチェック
		if ($form->Equal('url', '')) {
			sendTBResponse(1);
			return -10;
		}
		
		# datの更新
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
#	PATHINFO情報の取得
#	-------------------------------------------------------------------------------------
#	@param	なし
#	@return	BBS,スレッドキー,レス番号
#
#------------------------------------------------------------------------------------------------------------
sub getPathInfo
{
	@infos = split(/\//, $ENV{'PATH_INFO'});
	return ($infos[1], $infos[2], $infos[3]);
}

#------------------------------------------------------------------------------------------------------------
#
#	トラックバック応答の出力
#	-------------------------------------------------------------------------------------
#	@param	$err	エラーコード
#	@return	なし
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
#	BBSの更新
#	-------------------------------------------------------------------------------------
#	@param	$sys	システム情報
#	@param	$form	フォーム情報
#	@param	$bbs	BBS
#	@param	$thread	スレッドキー
#	@param	$res	レス番号
#	@return	なし
#
#------------------------------------------------------------------------------------------------------------
sub updateResponse
{
	my ($sys, $form, $bbs, $thread, $res) = @_;
	my ($Logger, $oBBSupport, $bbspath, $id, $ret);
	
	if (! $form->IsExist('title')) {
		$form->Set('title', '（無題）');
	}
	
	#---------------------------------------------------------------------------
	# ログの書き込み
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
	# datを更新する
	if (($ret = updateDatFile($sys, $form, $bbs, $thread, $res, $id)) != 0) {
		return $ret;
	}
	
	#---------------------------------------------------------------------------
	# 掲示板の更新
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
#	datファイルの更新
#	-------------------------------------------------------------------------------------
#	@param	$sys	システム情報
#	@param	$form	フォーム情報
#	@param	$bbs	BBS
#	@param	$thread	スレッドキー
#	@param	$res	レス番号
#	@param	$id		ID
#	@return	エラー番号
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
	# レス指定がある場合はレスへのトラックバック
	if ($res > 0) {
		my $Dat = new ARAGORN;
		if ($Dat->Load($sys, $datpath, 0)) {
			eval {
				my $pRes = $Dat->Get($res - 1);
				my @elem = split(/<>/, $$pRes);
				
				# 区切りがない場合は区切りを付加する
				if (! ($elem[3] =~ /<hr><small>■/)) {
					$elem[3] .= '<hr><small>■このレスへのトラックバック</small>';
				}
				$elem[3] .= '<br><small>[' . $form->Get('title') . '] ' . $form->Get('url') . '</small>';
				
				# datの保存
				my $data = join('<>', @elem);
				$Dat->Set($res - 1, $data);
				$Dat->Save($sys);
			};
			$Dat->Close();
			$ret = 0;
		}
	}
	#---------------------------------------------------------------------------
	# レス指定がない場合はスレッドへのトラックバック
	else {
		require './module/galadriel.pl';
		if (($res = ARAGORN::GetNumFromFile($datpath)) < ($sys->Get('RESMAX') - 1)) {
			my ($data, $msg);
			my $date = GALADRIEL::GetDate(undef, undef) . " ID:$id0";
			$msg .= '【トラックバック来たよ】（ver.0.10）<br>';
			$msg .= '[タイトル] ' . $form->Get('title') . '<br>';
			$msg .= '[発ブログ] ' . $form->Get('blog_name') . '<br>' . $form->Get('url') . '<br>';
			$msg .= '[＝要約＝]<br>' . $form->Get('excerpt');
			$data = "トラックバック ★<>sage<>$date<>$msg<>\n";
			
			# datへ追記
			if (ARAGORN::DirectAppend($sys, $datpath, $data) == 0) {
				# subjectの更新
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
